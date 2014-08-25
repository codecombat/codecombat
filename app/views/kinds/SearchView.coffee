RootView = require 'views/kinds/RootView'
NewModelModal = require 'views/modal/NewModelModal'
template = require 'templates/kinds/search'
app = require 'application'

class SearchCollection extends Backbone.Collection
  initialize: (modelURL, @model, @term, @projection) ->
    @url = "#{modelURL}?project="
    if @projection? and not (@projection == [])
      @url += projection[0]
      @url += ',' + projected for projected in projection[1..]
    else @url += 'true'
    @url += "&term=#{term}" if @term

module.exports = class SearchView extends RootView
  template: template
  className: 'search-view'

  # to overwrite in subclasses
  modelLabel: '' # 'Article'
  model: null # Article
  modelURL: null # '/db/article'
  tableTemplate: null # require 'templates/editor/article/table'
  projected: null # ['name', 'description', 'version'] or null for default

  events:
    'change input#search': 'runSearch'
    'keydown input#search': 'runSearch'
    'click #new-model-button': 'newModel'
    'hidden.bs.modal #new-model-modal': 'onModalHidden'

  constructor: (options) ->
    @runSearch = _.debounce(@runSearch, 500)
    super options

  afterRender: ->
    super()
    hash = document.location.hash[1..]
    searchInput = @$el.find('#search')
    searchInput.val(hash) if hash?
    delete @collection?.term
    searchInput.trigger('change')
    searchInput.focus()

  runSearch: =>
    return if @destroyed
    term = @$el.find('input#search').val()
    return if @sameSearch(term)
    @removeOldSearch()

    @collection = new SearchCollection(@modelURL, @model, term, @projection)
    @collection.term = term # needed?
    @listenTo(@collection, 'sync', @onSearchChange)
    @showLoading(@$el.find('.results'))

    @updateHash(term)
    @collection.fetch()

  updateHash: (term) ->
    newPath = document.location.pathname + (if term then '#' + term else '')
    currentPath = document.location.pathname + document.location.hash
    app.router.navigate(newPath) if newPath isnt currentPath

  sameSearch: (term) ->
    return false unless @collection
    return term is @collection.term

  onSearchChange: ->
    @hideLoading()
    documents = @collection.models
    table = $(@tableTemplate(documents:documents))
    @$el.find('table').replaceWith(table)
    @$el.find('table').i18n()

  removeOldSearch: ->
    return unless @collection?
    @collection.off()
    @collection = null

  onNewModelSaved: (@model) ->
    base = document.location.pathname[1..] + '/'
    app.router.navigate(base + (@model.get('slug') or @model.id), {trigger: true})

  newModel: (e) ->
    modal = new NewModelModal model: @model, modelLabel: @modelLabel
    modal.once 'model-created', @onNewModelSaved
    @openModalView modal
