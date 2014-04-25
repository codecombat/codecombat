View = require 'views/kinds/ModalView'
template = require 'templates/play/level/modal/docs'
Article = require 'models/Article'
utils = require 'lib/utils'

# let's implement this once we have the docs database schema set up

module.exports = class DocsModal extends View
  template: template
  id: 'docs-modal'

  shortcuts:
    'enter': 'hide'

  constructor: (options) ->
    @docs = options?.docs
    general = @docs.generalArticles or []
    specific = @docs.specificArticles or []

    articles = options.supermodel.getModels(Article)
    articleMap = {}
    articleMap[article.get('original')] = article for article in articles
    general = (articleMap[ref.original] for ref in general)
    general = (article.attributes for article in general when article)

    @docs = specific.concat(general)
    @docs = $.extend(true, [], @docs)
    doc.html = marked(utils.i18n doc, 'body') for doc in @docs
    doc.name = (utils.i18n doc, 'name') for doc in @docs
    doc.slug = _.string.slugify(doc.name) for doc in @docs
    super()

  getRenderData: ->
    c = super()
    c.docs = @docs
    c

  afterRender: ->
    super()
    if @docs.length is 1
      @$el.find('.modal-body').html(@docs[0].html)
    else
      # incredible hackiness. Getting bootstrap tabs to work shouldn't be this complex
      @$el.find('.nav-tabs li:first').addClass('active')
      @$el.find('.tab-content .tab-pane:first').addClass('active')
      @$el.find('.nav-tabs a').click(@clickTab)

  clickTab: (e) =>
    @$el.find('li.active').removeClass('active')

  onHidden: ->
    Backbone.Mediator.publish 'level:docs-hidden'
