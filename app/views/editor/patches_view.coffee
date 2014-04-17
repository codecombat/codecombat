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
    @listenToOnce @patches, 'sync', @gotPatches
    @addResourceToLoad @patches, 'patches'
    
  gotPatches: ->
    ids = (p.get('creator') for p in @patches.models)
    jqxhr = nameLoader.loadNames ids
    if jqxhr then @addRequestToLoad(jqxhr, 'user_names', 'gotPatches') else @render()
    
  load: ->
    return if @startedLoading
    @patches.fetch()
    @startedLoading = true
    
  getRenderData: ->
    c = super()
    patch.userName = nameLoader.getName(patch.get('creator')) for patch in @patches.models
    c.patches = @patches.models
    c.status
    c
    
  afterRender: ->
    @$el.find(".#{@status}").addClass 'active'

  onStatusButtonsChanged: (e) ->
    @status = $(e.target).val()
    @reloadPatches()
    
  reloadPatches: ->
    @loaded = false
    @initPatches()
    @load()
    @render()

  openPatchModal: (e) ->
    patch = _.find @patches.models, {id:$(e.target).data('patch-id')}
    modal = new PatchModal(patch, @model)
    @openModalView(modal)
    @listenTo modal, 'accepted-patch', -> @trigger 'accepted-patch'
    @listenTo modal, 'hide', ->
      f = => @reloadPatches()
      setTimeout(f, 400)
      @stopListening modal