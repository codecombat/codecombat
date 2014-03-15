View = require 'views/kinds/RootView'
VersionHistoryView = require './versions_view'
template = require 'templates/editor/article/edit'
Article = require 'models/Article'

module.exports = class ArticleEditView extends View
  id: "editor-article-edit-view"
  template: template
  startsLoading: true

  events:
    'click #preview-button': 'openPreview'
    'click #history-button': 'showVersionHistory'

  subscriptions:
    'save-new-version': 'saveNewArticle'

  constructor: (options, @articleID) ->
    super options
    @article = new Article(_id: @articleID)
    @article.saveBackups = true
    @article.fetch()
    @article.once('sync', @onArticleSync)
    @article.on('schema-loaded', @buildTreema)
    @pushChangesToPreview = _.throttle(@pushChangesToPreview, 500)

  onArticleSync: =>
    @article.loaded = true
    @buildTreema()

  buildTreema: =>
    return if @treema? or (not @article.loaded) or (not Article.hasSchema())
    unless @article.attributes.body
      @article.set('body', '')
    @startsLoading = false
    @render()
    data = $.extend(true, {}, @article.attributes)
    options =
      data: data
      filePath: "db/thang.type/#{@article.get('original')}"
      schema: Article.schema.attributes
      readOnly: true unless me.isAdmin() or @article.hasWriteAccess(me)
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
    b.find('#insert').html(m)
    b.find('#title').text(@treema.data.name)

  getRenderData: (context={}) ->
    context = super(context)
    context.article = @article
    context.authorized = me.isAdmin() or @article.hasWriteAccess(me)
    context

  openPreview: =>
    @preview = window.open('/editor/article/x/preview', 'preview', 'height=800,width=600')
    @preview.focus() if window.focus
    @preview.onload = => @pushChangesToPreview()
    return false

  saveNewArticle: (e) ->
    @treema.endExistingEdits()
    for key, value of @treema.data
      @article.set(key, value)

    newArticle = if e.major then @article.cloneNewMajorVersion() else @article.cloneNewMinorVersion()
    newArticle.set('commitMessage', e.commitMessage)
    res = newArticle.save()
    return unless res
    modal = @$el.find('#save-version-modal')
    @enableModalInProgress(modal)

    res.error =>
      @disableModalInProgress(modal)

    res.success =>
      modal.modal('hide')
      url = "/editor/article/#{newArticle.get('slug') or newArticle.id}"
      document.location.href = url

  showVersionHistory: (e) ->
    versionHistoryView = new VersionHistoryView article:@article, @articleID
    @openModalView versionHistoryView
    Backbone.Mediator.publish 'level:view-switched', e
