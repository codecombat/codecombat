RootView = require 'views/core/RootView'
VersionHistoryView = require './ArticleVersionsModal'
template = require 'templates/editor/article/edit'
Article = require 'models/Article'
SaveVersionModal = require 'views/editor/modal/SaveVersionModal'
PatchesView = require 'views/editor/PatchesView'
require 'views/modal/RevertModal'
require 'vendor/treema'

module.exports = class ArticleEditView extends RootView
  id: 'editor-article-edit-view'
  template: template

  events:
    'click #preview-button': 'openPreview'
    'click #history-button': 'showVersionHistory'
    'click #save-button': 'openSaveModal'

  constructor: (options, @articleID) ->
    super options
    @article = new Article(_id: @articleID)
    @article.saveBackups = true
    @supermodel.loadModel @article, 'article'
    @pushChangesToPreview = _.throttle(@pushChangesToPreview, 500)

  onLoaded: ->
    super()
    @buildTreema()
    @listenTo @article, 'change', =>
      @article.updateI18NCoverage()
      @treema.set('/', @article.attributes)

  buildTreema: ->
    return if @treema? or (not @article.loaded)
    unless @article.attributes.body
      @article.set('body', '')
    data = $.extend(true, {}, @article.attributes)
    options =
      data: data
      filePath: "db/thang.type/#{@article.get('original')}"
      schema: Article.schema
      readOnly: me.get('anonymous')
      callbacks:
        change: @pushChangesToPreview
    @treema = @$el.find('#article-treema').treema(options)
    @treema.build()

  pushChangesToPreview: =>
    for key, value of @treema.data
      @article.set(key, value)
    return unless @treema and @preview
    m = marked(@treema.data.body)
    b = $(@preview.document.body)
    onLoadHandler = =>
      if b.find('#insert').length == 1
        b.find('#insert').html(m)
        b.find('#title').text(@treema.data.name)
        clearInterval(id)
    id = setInterval(onLoadHandler, 100)

  afterRender: ->
    super()
    return unless @supermodel.finished()
    @showReadOnly() if me.get('anonymous')
    @patchesView = @insertSubView(new PatchesView(@article), @$el.find('.patches-view'))
    @patchesView.load()

  openPreview: ->
    if not @preview or @preview.closed
      @preview = window.open('/editor/article/preview', 'preview', 'height=800,width=600')
    @preview.focus() if window.focus
    @preview.onload = => @pushChangesToPreview()
    return false

  openSaveModal: ->
    modal = new SaveVersionModal({model: @article})
    @openModalView(modal)
    @listenToOnce modal, 'save-new-version', @saveNewArticle
    @listenToOnce modal, 'hidden', -> @stopListening(modal)

  saveNewArticle: (e) ->
    @treema.endExistingEdits()
    for key, value of @treema.data
      @article.set(key, value)

    newArticle = if e.major then @article.cloneNewMajorVersion() else @article.cloneNewMinorVersion()
    newArticle.set('commitMessage', e.commitMessage)
    res = newArticle.save(null, {type: 'POST'})  # Override PUT so we can trigger postNewVersion logic
    return unless res
    modal = @$el.find('#save-version-modal')
    @enableModalInProgress(modal)

    res.error =>
      @disableModalInProgress(modal)

    res.success =>
      @article.clearBackup()
      modal.modal('hide')
      url = "/editor/article/#{newArticle.get('slug') or newArticle.id}"
      document.location.href = url

  showVersionHistory: (e) ->
    versionHistoryView = new VersionHistoryView article: @article, @articleID
    @openModalView versionHistoryView
    Backbone.Mediator.publish 'editor:view-switched', {}
