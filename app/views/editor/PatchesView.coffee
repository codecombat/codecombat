CocoView = require 'views/core/CocoView'
template = require 'templates/editor/patches'
PatchesCollection = require 'collections/PatchesCollection'
nameLoader = require 'core/NameLoader'
PatchModal = require './PatchModal'

module.exports = class PatchesView extends CocoView
  template: template
  className: 'patches-view'
  status: 'pending'

  events:
    'change .status-buttons': 'onStatusButtonsChanged'
    'click .patch-row': 'openPatchModal'

  constructor: (@model, options) ->
    super(options)
    @initPatches()

  initPatches: ->
    @startedLoading = false
    @patches = @model.fetchPatchesWithStatus()

  load: ->
    @initPatches()
    @patches = @model.fetchPatchesWithStatus(@status, {cache: false})
    @supermodel.trackCollection(@patches)
    @listenTo @patches, 'sync', @onPatchesLoaded

  onPatchesLoaded: ->
    ids = (p.get('creator') for p in @patches.models)
    jqxhrOptions = nameLoader.loadNames ids
    @supermodel.addRequestResource('user_names', jqxhrOptions).load() if jqxhrOptions

  getRenderData: ->
    c = super()
    patch.userName = nameLoader.getName(patch.get('creator')) for patch in @patches.models
    c.patches = @patches.models
    c.status
    c

  afterRender: ->
    @$el.find(".#{@status}").addClass 'active'
    super()

  onStatusButtonsChanged: (e) ->
    @status = $(e.target).val()
    @reloadPatches()

  reloadPatches: ->
    @supermodel.resetProgress()
    @load()
    @render()

  openPatchModal: (e) ->
    row = $(e.target).closest '.patch-row'
    patch = _.find @patches.models, {id: row.data('patch-id')}
    modal = new PatchModal(patch, @model)
    @openModalView(modal)
    @listenTo modal, 'accepted-patch', (attrs) -> @trigger 'accepted-patch', attrs
    @listenTo modal, 'hide', ->
      f = => @reloadPatches()
      setTimeout(f, 400)
      @stopListening modal
