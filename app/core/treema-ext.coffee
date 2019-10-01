CocoModel = require 'models/CocoModel'
CocoCollection = require 'collections/CocoCollection'
{me} = require('core/auth')
locale = require 'locale/locale'
aceUtils = require 'core/aceUtils'
createjs = require 'lib/createjs-parts'
require('vendor/scripts/jquery-ui-1.11.1.custom')
require('vendor/styles/jquery-ui-1.11.1.custom.css')

initializeFilePicker = ->
  require('core/services/filepicker')() unless window.application.isIPadApp

class DateTimeTreema extends TreemaNode.nodeMap.string
  valueClass: 'treema-date-time'
  buildValueForDisplay: (el, data) -> el.text(moment(data).format('llll'))
  buildValueForEditing: (valEl) ->
    @buildValueForEditingSimply valEl, null, 'date'

class VersionTreema extends TreemaNode
  valueClass: 'treema-version'
  buildValueForDisplay: (valEl, data) ->
    @buildValueForDisplaySimply(valEl, "#{data.major}.#{data.minor}")

class LiveEditingMarkup extends TreemaNode.nodeMap.ace
  valueClass: 'treema-markdown treema-multiline treema-ace'

  constructor: ->
    super(arguments...)
    @workingSchema.aceMode = 'ace/mode/markdown'
    initializeFilePicker()

  initEditor: (valEl) ->
    buttonRow = $('<div class="buttons"></div>')
    valEl.append(buttonRow)
    @addPreviewToggle(buttonRow)
    @addImageUpload(buttonRow)
    super(valEl)
    valEl.append($('<div class="preview"></div>').hide())

  addImageUpload: (valEl) ->
    return unless me.isAdmin() or me.isArtisan()
    valEl.append(
      $('<div class="pick-image-button"></div>').append(
        $('<button>Pick Image</button>')
          .addClass('btn btn-sm btn-primary')
          .click(=> filepicker.pick @onFileChosen)
      )
    )

  addPreviewToggle: (valEl) ->
    valEl.append($('<div class="toggle-preview-button"></div>').append(
      $('<button>Toggle Preview</button>')
      .addClass('btn btn-sm btn-primary')
      .click(@togglePreview)
    ))

  onFileChosen: (InkBlob) =>
    body =
      url: InkBlob.url
      filename: InkBlob.filename
      mimetype: InkBlob.mimetype
      path: @settings.filePath
      force: true

    @uploadingPath = [@settings.filePath, InkBlob.filename].join('/')
    $.ajax('/file', { type: 'POST', data: body, success: @onFileUploaded })

  onFileUploaded: (e) =>
    @editor.insert "![#{e.metadata.name}](/file/#{@uploadingPath})"

  showingPreview: false

  togglePreview: =>
    valEl = @getValEl()
    if @showingPreview
      valEl.find('.preview').hide()
      valEl.find('.pick-image-button').show()
      valEl.find('.ace_editor').show()
    else
      valEl.find('.preview').html(marked(@data)).show()
      valEl.find('.pick-image-button').hide()
      valEl.find('.ace_editor').hide()
    @showingPreview = not @showingPreview

class SoundFileTreema extends TreemaNode.nodeMap.string
  valueClass: 'treema-sound-file'
  editable: false
  soundCollection: 'files'

  constructor: ->
    super arguments...
    initializeFilePicker()

  onClick: (e) ->
    return if $(e.target).closest('.btn').length
    super(arguments...)

  getFiles: ->
    @settings[@soundCollection]?.models or []

  buildValueForDisplay: (valEl, data) ->
    mimetype = "audio/#{@keyForParent}"
    mimetypes = [mimetype]
    if mimetype is 'audio/mp3'
      # https://github.com/codecombat/codecombat/issues/445
      # http://stackoverflow.com/questions/10688588/which-mime-type-should-i-use-for-mp3
      mimetypes.push 'audio/mpeg'
    else if mimetype is 'audio/ogg'
      mimetypes.push 'application/ogg'
      mimetypes.push 'video/ogg'  # huh, that's what it took to be able to upload ogg sounds in Firefox
    pickButton = $('<a class="btn btn-primary btn-xs"><span class="glyphicon glyphicon-upload"></span></a>')
      .click(=> filepicker.pick {mimetypes: mimetypes}, @onFileChosen)
    playButton = $('<a class="btn btn-primary btn-xs"><span class="glyphicon glyphicon-play"></span></a>')
      .click(@playFile)
    stopButton = $('<a class="btn btn-primary btn-xs"><span class="glyphicon glyphicon-stop"></span></a>')
      .click(@stopFile)

    dropdown = $('<div class="btn-group dropdown"></div>')

    dropdownButton = $('<a></a>')
      .addClass('btn btn-primary btn-xs dropdown-toggle')
      .attr('href', '#')
      .append($('<span class="glyphicon glyphicon-chevron-down"></span>'))
      .dropdown()

    dropdown.append dropdownButton

    menu = $('<div class="dropdown-menu"></div>')
    files = @getFiles()
    for file in files
      continue unless file.get('contentType') in mimetypes
      path = file.get('metadata').path
      filename = file.get 'filename'
      fullPath = [path, filename].join('/')
      li = $('<li></li>')
        .data('fullPath', fullPath)
        .text(filename)
      menu.append(li)
    menu.click (e) =>
      @data = $(e.target).data('fullPath') or data
      @reset()
    dropdown.append(menu)

    valEl.append(pickButton)
    if data
      valEl.append(playButton)
      valEl.append(stopButton)
    valEl.append(dropdown) # if files.length and @canEdit()
    if data
      path = data.split('/')
      name = path[path.length-1]
      valEl.append($('<span></span>').text(name))

  reset: ->
    @instance = null
    @flushChanges()
    @refreshDisplay()

  playFile: =>
    @src = "/file/#{@getData()}"

    if @instance
      @instance.play()

    else
      createjs.Sound.alternateExtensions = ['mp3','ogg']
      registered = createjs.Sound.registerSound(@src)
      if registered is true
        @instance = createjs.Sound.play(@src)

      else
        f = (event) =>
          @instance = createjs.Sound.play(event.src) if event.src is @src
          createjs.Sound.removeEventListener('fileload', f)
        createjs.Sound.addEventListener('fileload', f)

  stopFile: => @instance?.stop()

  onFileChosen: (InkBlob) =>
    if not @settings.filePath
      console.error('Need to specify a filePath for this treema', @getRoot())
      throw Error('cannot upload file')

    body =
      url: InkBlob.url
      filename: InkBlob.filename
      mimetype: InkBlob.mimetype
      path: @settings.filePath
      force: true

    @uploadingPath = [@settings.filePath, InkBlob.filename].join('/')
    $.ajax('/file', { type: 'POST', data: body, success: @onFileUploaded })

  onFileUploaded: (e) =>
    @data = @uploadingPath
    @reset()


class ImageFileTreema extends TreemaNode.nodeMap.string
  valueClass: 'treema-image-file'
  editable: false

  constructor: ->
    super arguments...
    initializeFilePicker()

  onClick: (e) ->
    return if $(e.target).closest('.btn').length
    super(arguments...)

  buildValueForDisplay: (valEl, data) ->
    mimetype = 'image/*'
    pickButton = $('<a class="btn btn-sm btn-primary"><span class="glyphicon glyphicon-upload"></span> Upload Picture</a>')
      .click(=> filepicker.pick {mimetypes:[mimetype]}, @onFileChosen)

    valEl.append(pickButton)
    if data
      valEl.append $('<img />').attr('src', "/file/#{data}")

  onFileChosen: (InkBlob) =>
    if not @settings.filePath
      console.error('Need to specify a filePath for this treema', @getRoot())
      throw Error('cannot upload file')

    body =
      url: InkBlob.url
      filename: InkBlob.filename
      mimetype: InkBlob.mimetype
      path: @settings.filePath
      force: true

    @uploadingPath = [@settings.filePath, InkBlob.filename].join('/')
    $.ajax('/file', { type: 'POST', data: body, success: @onFileUploaded })

  onFileUploaded: (e) =>
    @data = @uploadingPath
    @flushChanges()
    @refreshDisplay()


class CodeLanguagesObjectTreema extends TreemaNode.nodeMap.object
  childPropertiesAvailable: ->
    (key for key in _.keys(aceUtils.aceEditModes) when not @data[key]? and not (key is 'javascript' and @workingSchema.skipJavaScript))

class CodeLanguageTreema extends TreemaNode.nodeMap.string
  buildValueForEditing: (valEl, data) ->
    super(valEl, data)
    valEl.find('input').autocomplete(source: _.keys(aceUtils.aceEditModes), minLength: 0, delay: 0, autoFocus: true)
    valEl

class CodeTreema extends TreemaNode.nodeMap.ace
  constructor: ->
    super(arguments...)
    @workingSchema.aceTabSize = 4
    # TODO: Find a less hacky solution for this
    @workingSchema.aceMode = mode if mode = aceUtils.aceEditModes[@keyForParent]
    @workingSchema.aceMode = mode if mode = aceUtils.aceEditModes[@parent?.data?.language]

  initEditor: (args...) ->
    super args...
    @editor.setPrintMarginColumn 60

class CoffeeTreema extends CodeTreema
  constructor: ->
    super(arguments...)
    @workingSchema.aceMode = 'ace/mode/coffee'
    @workingSchema.aceTabSize = 2

class JavaScriptTreema extends CodeTreema
  constructor: ->
    super(arguments...)
    @workingSchema.aceMode = 'ace/mode/javascript'
    @workingSchema.aceTabSize = 4


class InternationalizationNode extends TreemaNode.nodeMap.object
  findLanguageName: (languageCode) ->
    # to get around mongoose empty object bug, there's a prop in the object which needs to be ignored
    return '' if languageCode is '-'
    locale[languageCode]?.nativeDescription or "#{languageCode} Not Found"

  getChildren: ->
    res = super(arguments...)
    res = (r for r in res when r[0] isnt '-')
    res

  populateData: ->
    super()
    if Object.keys(@data).length is 0
      @data['-'] = {'-':'-'} # also to get around mongoose bug

  getChildSchema: (key) ->
    #construct the child schema here

    i18nChildSchema = {
      title: @findLanguageName(key)
      type: 'object'
      properties: {}
    }
    return i18nChildSchema unless @parent
    unless @workingSchema.props?
      console.warn 'i18n props array is empty! Filling with all parent properties by default'
      @workingSchema.props = (prop for prop,_ of @parent.schema.properties when prop isnt 'i18n')

    for i18nProperty in @workingSchema.props
      parentSchemaProperties = @parent.schema.properties ? {}
      for extraSchemas in [@parent.schema.oneOf, @parent.schema.anyOf]
        for extraSchema in extraSchemas ? []
          for prop, schema of extraSchema?.properties ? {}
            parentSchemaProperties[prop] ?= schema
      i18nChildSchema.properties[i18nProperty] = parentSchemaProperties[i18nProperty]
    return i18nChildSchema
    #this must be filled out in order for the i18n node to work

  childPropertiesAvailable: ->
    (key for key in _.keys(locale) when not @data[key]?)


class LatestVersionCollection extends CocoCollection

module.exports.LatestVersionReferenceNode = class LatestVersionReferenceNode extends TreemaNode
  searchValueTemplate: '<input placeholder="Search" /><div class="treema-search-results"></div>'
  valueClass: 'treema-latest-version'
  url: '/db/article'
  lastTerm: null

  constructor: ->
    super(arguments...)

    # to dynamically build the search url, inspect the links url that should be included
    links = @workingSchema.links or []
    link = (l for l in links when l.rel is 'db')[0]
    return unless link
    parts = (p for p in link.href.split('/') when p.length)
    @url = "/db/#{parts[1]}"
    @model = require('models/' + _.string.classify(parts[1]))

  buildValueForDisplay: (valEl, data) ->
    val = if data then @formatDocument(data) else 'None'
    @buildValueForDisplaySimply(valEl, val)

  buildValueForEditing: (valEl, data) ->
    valEl.html(@searchValueTemplate)
    input = valEl.find('input')
    input.focus().keyup @search
    input.attr('placeholder', @formatDocument(data)) if data

  buildSearchURL: (term) -> "#{@url}?term=#{term}&project=true"

  search: =>
    term = @getValEl().find('input').val()
    return if term is @lastTerm

    @getSearchResultsEl().empty() if @lastTerm and not term
    return unless term
    @lastTerm = term
    @getSearchResultsEl().empty().append('Searching')
    @collection = new LatestVersionCollection([], model: @model)

    @collection.url = @buildSearchURL(term)
    @collection.fetch()
    @collection.once 'sync', @searchCallback, @

  searchCallback: ->
    container = @getSearchResultsEl().detach().empty()
    first = true
    for model in @collection.models
      row = $('<div></div>').addClass('treema-search-result-row')
      text = @formatDocument(model)
      continue unless text?
      row.addClass('treema-search-selected') if first
      first = false
      row.text(text)
      row.data('value', model)
      container.append(row)
    if not @collection.models.length
      container.append($('<div>No results</div>'))
    @getValEl().append(container)

  getSearchResultsEl: -> @getValEl().find('.treema-search-results')
  getSelectedResultEl: -> @getValEl().find('.treema-search-selected')

  modelToString: (model) -> model.get('name')

  formatDocument: (docOrModel) ->
    return @modelToString(docOrModel) if docOrModel instanceof CocoModel
    return 'Unknown' unless @settings.supermodel?
    m = @getReferencedModel(@getData(), @workingSchema)
    data = @getData()
    if _.isString data  # LatestVersionOriginalReferenceNode just uses original
      if m.schema().properties.version
        m = @settings.supermodel.getModelByOriginal(m.constructor, data)
      else
        # get by id
        m = @settings.supermodel.getModel(m.constructor, data)
    else
      m = @settings.supermodel.getModelByOriginalAndMajorVersion(m.constructor, data.original, data.majorVersion)
    if @instance and not m
      m = @instance
      @settings.supermodel.registerModel(m)
    return 'Unknown - ' + (data.original ? data) unless m
    return @modelToString(m)

  getReferencedModel: (data, schema) ->
    return null unless schema.links?
    linkObject = _.find schema.links, rel: 'db'
    return null unless linkObject
    return null if linkObject.href.match('thang.type') and not CocoModel.isObjectID(data)  # Skip loading hardcoded Thang Types for now (TODO)

    # not fully extensible, but we can worry about that later
    link = linkObject.href
    link = link.replace('{(original)}', data.original)
    link = link.replace('{(majorVersion)}', '' + (data.majorVersion ? 0))
    link = link.replace('{($)}', data)
    @getOrMakeModelFromLink(link)

  getOrMakeModelFromLink: (link) ->
    makeUrlFunc = (url) -> -> url
    modelUrl = link.split('/')[2]
    modelModule = _.string.classify(modelUrl)
    modulePath = "models/#{modelModule}"

    modulePath = modulePath.replace(/^models\//,'')
    try
      Model = require('app/models/' + modulePath) # TODO webpack: Get this working async for chunking
    catch e
      console.error 'could not load model from link path', link, 'using path', modulePath
      return

    model = new Model()
    model.url = makeUrlFunc(link)
    return model

  saveChanges: ->
    selected = @getSelectedResultEl()
    return unless selected.length
    fullValue = selected.data('value')
    @data = {
      original: fullValue.attributes.original
      majorVersion: fullValue.attributes.version.major
    }
    @instance = fullValue

  onDownArrowPressed: (e) ->
    return super(arguments...) unless @isEditing()
    @navigateSearch(1)
    e.preventDefault()

  onUpArrowPressed: (e) ->
    return super(arguments...) unless @isEditing()
    e.preventDefault()
    @navigateSearch(-1)

  navigateSearch: (offset) ->
    selected = @getSelectedResultEl()
    func = if offset > 0 then 'next' else 'prev'
    next = selected[func]('.treema-search-result-row')
    return unless next.length
    selected.removeClass('treema-search-selected')
    next.addClass('treema-search-selected')

  onClick: (e) ->
    newSelection = $(e.target).closest('.treema-search-result-row')
    return super(e) unless newSelection.length
    @getSelectedResultEl().removeClass('treema-search-selected')
    newSelection.addClass('treema-search-selected')
    @saveChanges()
    @flushChanges()
    @display()

  shouldTryToRemoveFromParent: ->
    return if @data?
    selected = @getSelectedResultEl()
    return not selected.length

module.exports.LatestVersionOriginalReferenceNode = class LatestVersionOriginalReferenceNode extends LatestVersionReferenceNode
  # Just for saving the original, not the major version.
  saveChanges: ->
    selected = @getSelectedResultEl()
    return unless selected.length
    fullValue = selected.data('value')
    @data = fullValue.attributes.original
    @instance = fullValue

module.exports.IDReferenceNode = class IDReferenceNode extends LatestVersionReferenceNode
  # Just for saving the _id
  saveChanges: ->
    selected = @getSelectedResultEl()
    return unless selected.length
    fullValue = selected.data('value')
    @data = fullValue.attributes._id
    @instance = fullValue

class LevelComponentReferenceNode extends LatestVersionReferenceNode
  # HACK: this list of properties is needed by the thang components edit view and config views.
  # need a better way to specify this, or keep the search models from bleeding into those
  # supermodels.
  buildSearchURL: (term) -> "#{@url}?term=#{term}&project=name,system,original,version,dependencies,configSchema,description"
  modelToString: (model) -> model.get('system') + '.' + model.get('name')
  canEdit: -> not @getData().original # only allow editing if the row's data hasn't been set yet

LatestVersionReferenceNode.prototype.search = _.debounce(LatestVersionReferenceNode.prototype.search, 200)

class SlugPropsObject extends TreemaNode.nodeMap.object
  getPropertyKey: ->
    res = super(arguments...)
    return res if @workingSchema.properties?[res]?
    _.string.slugify(res)

class TaskTreema extends TreemaNode.nodeMap.string
  buildValueForDisplay: (valEl) ->
    @taskCheckbox = $('<input type="checkbox">').prop 'checked', @data.complete
    task = $("<span>#{@data.name}</span>")
    valEl.append(@taskCheckbox).append(task)
    @taskCheckbox.on 'change', @onTaskChanged

  buildValueForEditing: (valEl, data) ->
    @nameInput = @buildValueForEditingSimply(valEl, data.name)
    @nameInput.parent().prepend(@taskCheckbox)

  onTaskChanged: (e) =>
    @markAsChanged()
    @saveChanges()
    @flushChanges()
    @broadcastChanges()

  onEditInputBlur: (e) =>
    @markAsChanged()
    @saveChanges()
    if @isValid() then @display() if @isEditing() else @nameInput.focus().select()
    @flushChanges()
    @broadcastChanges()

  saveChanges: (oldData) ->
    @data ?= {}
    @data.name = @nameInput.val() if @nameInput
    @data.complete = Boolean(@taskCheckbox.prop 'checked')

  destroy: ->
    @taskCheckbox.off()
    super()


#class CheckboxTreema extends TreemaNode.nodeMap.boolean
# TODO: try this out


module.exports.setup = ->
  TreemaNode.setNodeSubclass('date-time', DateTimeTreema)
  TreemaNode.setNodeSubclass('version', VersionTreema)
  TreemaNode.setNodeSubclass('markdown', LiveEditingMarkup)
  TreemaNode.setNodeSubclass('code-languages-object', CodeLanguagesObjectTreema)
  TreemaNode.setNodeSubclass('code-language', CodeLanguageTreema)
  TreemaNode.setNodeSubclass('code', CodeTreema)
  TreemaNode.setNodeSubclass('coffee', CoffeeTreema)
  TreemaNode.setNodeSubclass('javascript', JavaScriptTreema)
  TreemaNode.setNodeSubclass('image-file', ImageFileTreema)
  TreemaNode.setNodeSubclass('latest-version-reference', LatestVersionReferenceNode)
  TreemaNode.setNodeSubclass('latest-version-original-reference', LatestVersionOriginalReferenceNode)
  TreemaNode.setNodeSubclass('component-reference', LevelComponentReferenceNode)
  TreemaNode.setNodeSubclass('i18n', InternationalizationNode)
  TreemaNode.setNodeSubclass('sound-file', SoundFileTreema)
  TreemaNode.setNodeSubclass 'slug-props', SlugPropsObject
  TreemaNode.setNodeSubclass 'task', TaskTreema
  #TreemaNode.setNodeSubclass 'checkbox', CheckboxTreema
