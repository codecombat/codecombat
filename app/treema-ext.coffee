CocoModel = require 'models/CocoModel'
CocoCollection = require 'collections/CocoCollection'
{me} = require('lib/auth')
locale = require 'locale/locale'

class DateTimeTreema extends TreemaNode.nodeMap.string
  valueClass: 'treema-date-time'
  buildValueForDisplay: (el) -> el.text(moment(@data).format('llll'))
  buildValueForEditing: (valEl) ->
    @buildValueForEditingSimply valEl, null, 'date'

class VersionTreema extends TreemaNode
  valueClass: 'treema-version'
  buildValueForDisplay: (valEl) -> @buildValueForDisplaySimply(valEl, "#{@data.major}.#{@data.minor}")

class LiveEditingMarkup extends TreemaNode.nodeMap.ace
  valueClass: 'treema-markdown treema-multiline treema-ace'

  constructor: ->
    super(arguments...)
    @schema.aceMode = 'ace/mode/markdown'

  buildValueForEditing: (valEl) ->
    super(valEl)
    @editor.on('change', @onEditorChange)
    @addImageUpload(valEl)

  addImageUpload: (valEl) ->
    return unless me.isAdmin()
    valEl.append(
      $('<div></div>').append(
        $('<button>Pick Image</button>')
          .addClass('btn btn-sm btn-primary')
          .click(=> filepicker.pick @onFileChosen)
      )
    )

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

  onEditorChange: =>
    @saveChanges()
    @flushChanges()
    @getRoot().broadcastChanges()

  buildValueForDisplay: (valEl) ->
    @editor?.destroy()
    valEl.html(marked(@data))

class SoundFileTreema extends TreemaNode.nodeMap.string
  valueClass: 'treema-sound-file'
  editable: false
  soundCollection: 'files'

  onClick: (e) ->
    return if $(e.target).closest('.btn').length
    super(arguments...)

  getFiles: ->
    @settings[@soundCollection]?.models or []

  buildValueForDisplay: (valEl) ->
    mimetype = "audio/#{@keyForParent}"
    pickButton = $('<a class="btn btn-primary btn-xs"><span class="glyphicon glyphicon-upload"></span></a>')
      .click(=> filepicker.pick {mimetypes:[mimetype]}, @onFileChosen)
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
      continue unless file.get('contentType') is mimetype
      path = file.get('metadata').path
      filename = file.get 'filename'
      fullPath = [path, filename].join('/')
      li = $('<li></li>')
        .data('fullPath', fullPath)
        .text(filename)
      menu.append(li)
    menu.click (e) =>
      @data = $(e.target).data('fullPath') or @data
      @reset()
    dropdown.append(menu)

    valEl.append(pickButton)
    if @data
      valEl.append(playButton)
      valEl.append(stopButton)
    valEl.append(dropdown) # if files.length and @canEdit()
    if @data
      path = @data.split('/')
      name = path[path.length-1]
      valEl.append($('<span></span>').text(name))

  reset: ->
    @instance = null
    @flushChanges()
    @refreshDisplay()

  playFile: =>
    @src = "/file/#{@data}"

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

  onClick: (e) ->
    return if $(e.target).closest('.btn').length
    super(arguments...)

  buildValueForDisplay: (valEl) ->
    mimetype = 'image/*'
    pickButton = $('<a class="btn btn-sm btn-primary"><span class="glyphicon glyphicon-upload"></span> Upload Picture</a>')
      .click(=> filepicker.pick {mimetypes:[mimetype]}, @onFileChosen)

    valEl.append(pickButton)
    if @data
      valEl.append $('<img />').attr('src', "/file/#{@data}")

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


codeLanguages =
  javascript: 'ace/mode/javascript'
  coffeescript: 'ace/mode/coffee'
  python: 'ace/mode/python'
  clojure: 'ace/mode/clojure'
  lua: 'ace/mode/lua'
  io: 'ace/mode/text'

class CodeLanguagesObjectTreema extends TreemaNode.nodeMap.object
  childPropertiesAvailable: ->
    (key for key in _.keys(codeLanguages) when not @data[key]?)

class CodeLanguageTreema extends TreemaNode.nodeMap.string
  buildValueForEditing: (valEl) ->
    super(valEl)
    valEl.find('input').autocomplete(source: _.keys(codeLanguages), minLength: 0, delay: 0, autoFocus: true)
    valEl

class CodeTreema extends TreemaNode.nodeMap.ace
  constructor: ->
    super(arguments...)
    @schema.aceTabSize = 4

  buildValueForEditing: (valEl) ->
    super(valEl)
    if not @schema.aceMode and mode = codeLanguages[@keyForParent]
      @editor.getSession().setMode mode
    valEl

class CoffeeTreema extends CodeTreema
  constructor: ->
    super(arguments...)
    @schema.aceMode = 'ace/mode/coffee'
    @schema.aceTabSize = 2

class JavaScriptTreema extends CodeTreema
  constructor: ->
    super(arguments...)
    @schema.aceMode = 'ace/mode/javascript'
    @schema.aceTabSize = 4


class InternationalizationNode extends TreemaNode.nodeMap.object
  findLanguageName: (languageCode) ->
    # to get around mongoose emtpy object bug, there's a prop in the object which needs to be ignored
    return '' if languageCode is '-'
    locale[languageCode]?.nativeDescription or "#{languageCode} Not Found"

  getChildren: ->
    res = super(arguments...)
    res = (r for r in res when r[0] isnt '-')
    res

  getChildSchema: (key) ->
    #construct the child schema here

    i18nChildSchema = {
      title: @findLanguageName(key)
      type: 'object'
      properties: {}
    }
    return i18nChildSchema unless @parent
    unless @schema.props?
      console.warn 'i18n props array is empty! Filling with all parent properties by default'
      @schema.props = (prop for prop,_ of @parent.schema.properties when prop isnt 'i18n')

    for i18nProperty in @schema.props
      i18nChildSchema.properties[i18nProperty] = @parent.schema.properties[i18nProperty]
    return i18nChildSchema
    #this must be filled out in order for the i18n node to work

  childPropertiesAvailable: ->
    (key for key in _.keys(locale) when not @data[key]?)


class LatestVersionCollection extends CocoCollection

class LatestVersionReferenceNode extends TreemaNode
  searchValueTemplate: '<input placeholder="Search" /><div class="treema-search-results"></div>'
  valueClass: 'treema-latest-version'
  url: '/db/article'
  lastTerm: null

  constructor: ->
    super(arguments...)

    # to dynamically build the search url, inspect the links url that should be included
    links = @schema.links or []
    link = (l for l in links when l.rel is 'db')[0]
    return unless link
    parts = (p for p in link.href.split('/') when p.length)
    @url = "/db/#{parts[1]}"
    @model = require('models/' + _.string.classify(parts[1]))

  buildValueForDisplay: (valEl) ->
    val = if @data then @formatDocument(@data) else 'None'
    @buildValueForDisplaySimply(valEl, val)

  buildValueForEditing: (valEl) ->
    valEl.html(@searchValueTemplate)
    input = valEl.find('input')
    input.focus().keyup @search
    input.attr('placeholder', @formatDocument(@data)) if @data
    
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
    m = CocoModel.getReferencedModel(@data, @schema)
    urlGoingFor = m.url()
    m = @settings.supermodel.getModel(urlGoingFor)
    if @instance and not m
      m = @instance
      m.url = -> urlGoingFor
      @settings.supermodel.registerModel(m)
    return 'Unknown' unless m
    return @modelToString(m)

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

  onDeletePressed: (e) ->
    super(arguments...)

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
    
class LevelComponentReferenceNode extends LatestVersionReferenceNode
  # HACK: this list of properties is needed by the thang components edit view and config views.
  # need a better way to specify this, or keep the search models from bleeding into those
  # supermodels.
  buildSearchURL: (term) -> "#{@url}?term=#{term}&project=name,system,original,version,dependencies,configSchema,description"
  modelToString: (model) -> model.get('system') + '.' + model.get('name')
  canEdit: -> not @data.original # only allow editing if the row's data hasn't been set yet

LatestVersionReferenceNode.prototype.search = _.debounce(LatestVersionReferenceNode.prototype.search, 200)

class SlugPropsObject extends TreemaNode.nodeMap.object
  getPropertyKey: ->
    res = super(arguments...)
    return res if @schema.properties?[res]?
    _.string.slugify(res)

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
  TreemaNode.setNodeSubclass('component-reference', LevelComponentReferenceNode)
  TreemaNode.setNodeSubclass('i18n', InternationalizationNode)
  TreemaNode.setNodeSubclass('sound-file', SoundFileTreema)
  TreemaNode.setNodeSubclass 'slug-props', SlugPropsObject
