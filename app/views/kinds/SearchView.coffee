View = require 'views/kinds/RootView'
template = require 'templates/kinds/search'
forms = require('lib/forms')
app = require('application')

class SearchCollection extends Backbone.Collection
  initialize: (modelURL, @model, @term, @projection) ->
    @url = "#{modelURL}?project="
    if @projection? and not (@projection == [])
      @url += projection[0]
      @url += ',' + projected for projected in projection[1..]
    else @url += "true"
    @url += "&term=#{term}" if @term

module.exports = class SearchView extends View
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
    'click button.new-model-submit': 'makeNewModel'
    'submit form': 'makeNewModel'
    'shown.bs.modal #new-model-modal': 'focusOnName'
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
    newPath = document.location.pathname + (if term then "#" + term else "")
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

  makeNewModel: (e) ->
    e.preventDefault()
    name = @$el.find('#name').val()
    model = new @model()
    model.set('name', name)
    if @model.schema.properties.permissions
      model.set 'permissions', [{access: 'owner', target: me.id}]
    res = model.save()
    return unless res

    modal = @$el.find('#new-model-modal')
    forms.clearFormAlerts(modal)
    @showLoading(modal.find('.modal-body'))
    res.error =>
      @hideLoading()
      forms.applyErrorsToForm(modal, JSON.parse(res.responseText))
    that = @
    res.success ->
      that.model = model
      modal.modal('hide')

  onModalHidden: ->
    # Can only redirect after the modal hidden event has triggered
    base = document.location.pathname[1..] + '/'
    app.router.navigate(base + (@model.get('slug') or @model.id), {trigger:true})

  focusOnName: ->
    @$el.find('#name').focus()
