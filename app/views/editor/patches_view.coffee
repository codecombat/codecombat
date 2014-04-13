CocoView = require 'views/kinds/CocoView'
template = require 'templates/editor/patches'
PatchesCollection = require 'collections/PatchesCollection'
nameLoader = require 'lib/NameLoader'
PatchModal = require './patch_modal'

module.exports = class PatchesView extends CocoView
  template: template
  className: 'patches-view'
  status: 'pending'
  
  events:
    'change .status-buttons': 'onStatusButtonsChanged'
    'click .patch-icon': 'openPatchModal'

  constructor: (@model, options) ->
    super(options)
    @initPatches()
    
  initPatches: ->
    @startedLoading = false
    @patches = new PatchesCollection([], {}, @model, @status)
    @patchesRes = @supermodel.addModelResource(@patches, 'patches')

    ids = (p.get('creator') for p in @patches.models)
    jqxhrOptions = nameLoader.loadNames ids
    @nameLoaderRes = @supermodel.addRequestResource('name_loader', jqxhrOptions)
    @nameLoaderRes.addDependency(@patchesRes)
    
  load: ->
    @nameLoaderRes.load()

  getRenderData: ->
    c = super()
    patch.userName = nameLoader.getName(patch.get('creator')) for patch in @patches.models
    c.patches = @patches.models
    c.status
    c
    
  afterRender: ->
    @$el.find(".#{@status}").addClass 'active'

  onStatusButtonsChanged: (e) ->
    @loaded = false
    @status = $(e.target).val()
    @initPatches()
    @load()
    @render()

  openPatchModal: (e) ->
    patch = _.find @patches.models, {id:$(e.target).data('patch-id')}
    modal = new PatchModal(patch, @model)
    @openModalView(modal)