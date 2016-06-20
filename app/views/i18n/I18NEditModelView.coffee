RootView = require 'views/core/RootView'
locale = require 'locale/locale'
Patch = require 'models/Patch'
template = require 'templates/i18n/i18n-edit-model-view'
deltasLib = require 'core/deltas'

# in the template, but need to require to load them
require 'views/modal/RevertModal'

module.exports = class I18NEditModelView extends RootView
  className: 'editor i18n-edit-model-view'
  template: template

  events:
    'change .translation-input': 'onInputChanged'
    'change #language-select': 'onLanguageSelectChanged'
    'click #patch-submit': 'onSubmitPatch'

  constructor: (options, @modelHandle) ->
    super(options)
    @model = new @modelClass(_id: @modelHandle)
    @model = @supermodel.loadModel(@model).model
    @model.saveBackups = true
    @selectedLanguage = me.get('preferredLanguage', true)

  showLoading: ($el) ->
    $el ?= @$el.find('.outer-content')
    super($el)

  onLoaded: ->
    super()
    @model.markToRevert() unless @model.hasLocalChanges()

  getRenderData: ->
    c = super()

    c.model = @model
    c.selectedLanguage = @selectedLanguage

    @translationList = []
    if @supermodel.finished() then @buildTranslationList() else []
    result.index = index for result, index in @translationList
    c.translationList = @translationList

    c

  afterRender: ->
    super()

    @hush = true
    $select = @$el.find('#language-select').empty()
    @addLanguagesToSelect($select, @selectedLanguage)
    @$el.find('option[value="en-US"]').remove()
    @hush = false
    editors = []

    @$el.find('tr[data-format="markdown"]').each((index, el) =>
      foundEnEl = enEl=$(el).find('.english-value-row div')[0]
      if foundEnEl?
        englishEditor = ace.edit(foundEnEl)
        englishEditor.el = enEl
        englishEditor.setReadOnly(true)
        editors.push englishEditor
      foundToEl = toEl=$(el).find('.to-value-row div')[0]
      if foundToEl?
        toEditor = ace.edit(foundToEl)
        toEditor.el = toEl
        toEditor.on 'change', @onEditorChange
        editors.push toEditor
    )

    for editor in editors
      session = editor.getSession()
      session.setTabSize 2
      session.setMode 'ace/mode/markdown'
      session.setNewLineMode = 'unix'
      session.setUseSoftTabs true
      editor.setOptions({ maxLines: Infinity })

  onEditorChange: (event, editor) =>
    return if @destroyed
    index = $(editor.el).data('index')
    rowInfo = @translationList[index]
    value = editor.getValue()
    @onTranslationChanged(rowInfo, value)

  wrapRow: (title, key, enValue, toValue, path, format) ->
    @translationList.push {
      title: title,
      key: key,
      enValue: enValue,
      toValue: toValue or '',
      path: path
      format: format
    }

  buildTranslationList: -> [] # overwrite

  onInputChanged: (e) ->
    index = $(e.target).data('index')
    rowInfo = @translationList[index]
    value = $(e.target).val()
    @onTranslationChanged(rowInfo, value)

  onTranslationChanged: (rowInfo, value) ->

    #- Navigate down to where the translation will live
    base = @model.attributes

    for seg in rowInfo.path
      base = base[seg]

    base = base.i18n

    base[@selectedLanguage] ?= {}
    base = base[@selectedLanguage]

    if rowInfo.key.length > 1
      for seg in rowInfo.key[..-2]
        base[seg] ?= {}
        base = base[seg]

    #- Set the data in a non-kosher way

    base[rowInfo.key[rowInfo.key.length-1]] = value
    @model.saveBackup()

    #- Enable patch submit button

    @$el.find('#patch-submit').attr('disabled', null)

  onLanguageSelectChanged: (e) ->
    return if @hush
    @selectedLanguage = $(e.target).val()
    if @selectedLanguage
      me.set('preferredLanguage', @selectedLanguage)
      me.patch()
    @render()

  onSubmitPatch: (e) ->

    delta = @model.getDelta()
    flattened = deltasLib.flattenDelta(delta)
    save = _.all(flattened, (delta) ->
      return _.isArray(delta.o) and delta.o.length is 1 and 'i18n' in delta.dataPath
    )

    commitMessage = "Diplomat submission for lang #{@selectedLanguage}: #{flattened.length} change(s)."
    save = false if @savedBefore

    if save
      modelToSave = @model.cloneNewMinorVersion()
      modelToSave.updateI18NCoverage() if modelToSave.get('i18nCoverage')
      if @modelClass.schema.properties.commitMessage
        modelToSave.set 'commitMessage', commitMessage

    else
      modelToSave = new Patch()
      modelToSave.set 'delta', @model.getDelta()
      modelToSave.set 'target', {
        'collection': _.string.underscored @model.constructor.className
        'id': @model.id
      }
      modelToSave.set 'commitMessage', commitMessage

    errors = modelToSave.validate()
    button = $(e.target)
    button.attr('disabled', 'disabled')
    return button.text('Failed to Submit Changes') if errors
    type = 'PUT'
    if @modelClass.schema.properties.version or (not save)
      # Override PUT so we can trigger postNewVersion logic
      # or you're POSTing a Patch
      type = 'POST'
    res = modelToSave.save(null, {type: type})
    return button.text('Failed to Submit Changes') unless res
    button.text('Submitting...')
    res.error => button.text('Error Submitting Changes')
    res.success =>
      @savedBefore = true
      button.text('Submit Changes')
