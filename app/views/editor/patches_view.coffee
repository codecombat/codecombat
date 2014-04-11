CocoView = require 'views/kinds/CocoView'
template = require 'templates/editor/patches'
PatchesCollection = require 'collections/PatchesCollection'
nameLoader = require 'lib/NameLoader'

module.exports = class PatchesView extends CocoView
  template: template
  className: 'patches-view'
  status: 'pending'
  
  events:
    'change .status-buttons': 'onStatusButtonsChanged'

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
    @loaded = false
    @status = $(e.target).val()
    @initPatches()
    @load()
    @render()
