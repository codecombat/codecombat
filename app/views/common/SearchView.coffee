RootView = require 'views/core/RootView'
NewModelModal = require 'views/editor/modal/NewModelModal'
template = require 'templates/common/search-view'
CreateAccountModal = require 'views/core/CreateAccountModal'

class SearchCollection extends Backbone.Collection
  initialize: (modelURL, @model, @term, @projection) ->
    @url = "#{modelURL}?project="
    if @projection?.length
      @url += 'created,permissions'
      @url += ',' + projected for projected in @projection
    else @url += 'true'
    @url += "&term=#{@term}" if @term

  comparator: (a, b) ->
    score = 0
    score -= 9001900190019001 if a.getOwner() is me.id
    score += 9001900190019001 if b.getOwner() is me.id
    score -= new Date(a.get 'created')
    score -= -(new Date(b.get 'created'))
    if score < 0 then -1 else (if score > 0 then 1 else 0)

module.exports = class SearchView extends RootView
  template: template
  className: 'search-view'

  # to overwrite in subclasses
  modelLabel: '' # 'Article'
  model: null # Article
  modelURL: null # '/db/article'
  tableTemplate: null # require 'templates/editor/article/table'
  projected: null # ['name', 'description', 'version'] or null for default
  canMakeNew: true

  events:
    'change input#search': 'runSearch'
    'keydown input#search': 'runSearch'
    'click #new-model-button': 'newModel'
    'hidden.bs.modal #new-model-modal': 'onModalHidden'
    'click [data-toggle="coco-modal"][data-target="core/CreateAccountModal"]': 'openCreateAccountModal'

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
    application.router.navigate(newPath) if newPath isnt currentPath

  sameSearch: (term) ->
    return false unless @collection
    return term is @collection.term

  onSearchChange: ->
    @hideLoading()
    @collection.sort()
    documents = @collection.models
    table = $(@tableTemplate(documents: documents, me: me, page: @page, moment: moment))
    @$el.find('table').replaceWith(table)
    @$el.find('table').i18n()
    @applyRTLIfNeeded()

  removeOldSearch: ->
    return unless @collection?
    @collection.off()
    @collection = null

  onNewModelSaved: (@model) ->
    base = document.location.pathname[1..] + '/'
    application.router.navigate(base + (@model.get('slug') or @model.id), {trigger: true})

  newModel: (e) ->
    modal = new NewModelModal model: @model, modelLabel: @modelLabel
    modal.once 'model-created', @onNewModelSaved
    @openModalView modal

  openCreateAccountModal: (e) ->
    e.stopPropagation()
    @openModalView new CreateAccountModal()
