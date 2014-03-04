View = require 'views/kinds/RootView'
template = require 'templates/kinds/search'
forms = require('lib/forms')
app = require('application')

class SearchCollection extends Backbone.Collection
  initialize: (modelURL, @model, @term) ->
    @url = "#{modelURL}/search?project=yes"
    @url += "&term=#{term}" if @term

module.exports = class ThangTypeHomeView extends View
  template: template
  className: 'search-view'

  # to overwrite in subclasses
  modelLabel: '' # 'Article'
  model: null # Article
  modelURL: null # '/db/article'
  tableTemplate: null # require 'templates/editor/article/table'

  events:
    'change input#search': 'runSearch'
    'keydown input#search': 'runSearch'
    'click button.new-model-submit': 'makeNewModel'
    'shown.bs.modal #new-model-modal': 'focusOnName'

  getRenderData: ->
    c = super()
    c.modelLabel = @modelLabel
    c

  constructor: (options) ->
    @runSearch = _.debounce(@runSearch, 500)
    super options

  afterRender: ->
    super()
    hash = document.location.hash[1..]
    searchInput = @$el.find('#search')
    searchInput.val(hash) if hash?
    searchInput.trigger('change')
    searchInput.focus()

  runSearch: =>
    term = @$el.find('input#search').val()
    return if @sameSearch(term)
    @removeOldSearch()

    @collection = new SearchCollection(@modelURL, @model, term)
    @collection.term = term # needed?
    @collection.on('sync', @onSearchChange)
    @showLoading(@$el.find('.results'))

    @updateHash(term)
    @collection.fetch()

  updateHash: (term) ->
    newPath = document.location.pathname + (if term then "#" + term else "")
    currentPath = document.location.pathname + document.location.hash
    app.router.navigate(newPath) if newPath isnt currentPath

  sameSearch: (term) ->
    return false unless @collection
    return term is @collection.term

  onSearchChange: =>
    @hideLoading()
    documents = @collection.models
    table = $(@tableTemplate(documents:documents))
    @$el.find('table').replaceWith(table)

  removeOldSearch: ->
    return unless @collection?
    @collection.off()
    @collection = null

  makeNewModel: (e) ->
    e.preventDefault()
    name = @$el.find('#name').val()
    model = new @model()
    model.set('name', name)
    if @model.schema.get('properties').permissions
      model.set 'permissions', [{access: 'owner', target: me.id}]
    res = model.save()
    return unless res

    modal = @$el.find('.modal')
    forms.clearFormAlerts(modal)
    @showLoading(modal.find('.modal-body'))
    res.error =>
      @hideLoading()
      forms.applyErrorsToForm(modal, JSON.parse(res.responseText))
    res.success ->
      modal.modal('hide')
      base = document.location.pathname[1..] + '/'
      app.router.navigate(base + (model.get('slug') or model.id), {trigger:true})

  focusOnName: ->
    @$el.find('#name').focus()
