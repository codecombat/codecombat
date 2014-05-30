CocoView = require 'views/kinds/CocoView'
template = require 'templates/editor/delta'
deltasLib = require 'lib/deltas'

TEXTDIFF_OPTIONS =
  baseTextName: "Old"
  newTextName: "New"
  contextSize: 5
  viewType: 1
  
module.exports = class DeltaView extends CocoView
  
  ###
  Takes a CocoModel instance (model) and displays changes since the 
  last save (attributes vs _revertAttributes).
  
  * If headModel is included, will look for and display conflicts with the changes in model.
  * If comparisonModel is included, will show deltas between model and comparisonModel instead
    of changes within model itself.
    
  ###
  
  @deltaCounter: 0
  className: "delta-view"
  template: template

  constructor: (options) ->
    super(options)
    @expandedDeltas = []
    @skipPaths = options.skipPaths
    
    for modelName in ['model', 'headModel', 'comparisonModel']
      continue unless m = options[modelName]
      @[modelName] = @supermodel.loadModel(m, 'document').model
    
    @buildDeltas() if @supermodel.finished()
    
  onLoaded: ->
    @buildDeltas()
    super()
    
  buildDeltas: ->
    if @comparisonModel
      @expandedDeltas = @model.getExpandedDeltaWith(@comparisonModel)
    else
      @expandedDeltas = @model.getExpandedDelta()
    [@expandedDeltas, @skippedDeltas] = @filterDeltas(@expandedDeltas)
      
    if @headModel
      @headDeltas = @headModel.getExpandedDelta()
      @headDeltas = @filterDeltas(@headDeltas)[0]
      @conflicts = deltasLib.getConflicts(@headDeltas, @expandedDeltas)

  filterDeltas: (deltas) ->
    return [deltas, []] unless @skipPaths
    for path, i in @skipPaths
      @skipPaths[i] = [path] if _.isString(path)
    newDeltas = []
    skippedDeltas = []
    for delta in deltas
      skip = false
      for skipPath in @skipPaths
        if _.isEqual _.first(delta.dataPath, skipPath.length), skipPath
          skip = true
          break
      if skip then skippedDeltas.push delta else newDeltas.push delta
    [newDeltas, skippedDeltas]

  getRenderData: ->
    c = super()
    c.deltas = @expandedDeltas
    c.counter = DeltaView.deltaCounter
    DeltaView.deltaCounter += @expandedDeltas.length
    c
    
  afterRender: ->
    deltas = @$el.find('.details')
    for delta, i in deltas
      deltaEl = $(delta)
      deltaData = @expandedDeltas[i]
      @expandDetails(deltaEl, deltaData)
      
    conflictDeltas = @$el.find('.conflict-details')
    conflicts = (delta.conflict for delta in @expandedDeltas when delta.conflict)
    for delta, i in conflictDeltas
      deltaEl = $(delta)
      deltaData = conflicts[i]
      @expandDetails(deltaEl, deltaData)
      
  expandDetails: (deltaEl, deltaData) ->
    treemaOptions = { schema: deltaData.schema or {}, readOnly: true }
    
    if _.isObject(deltaData.left) and leftEl = deltaEl.find('.old-value')
      options = _.defaults {data: deltaData.left}, treemaOptions
      TreemaNode.make(leftEl, options).build()
      
    if _.isObject(deltaData.right) and rightEl = deltaEl.find('.new-value')
      options = _.defaults {data: deltaData.right}, treemaOptions
      TreemaNode.make(rightEl, options).build()
      
    if deltaData.action is 'text-diff'
      left = difflib.stringAsLines deltaData.left
      right = difflib.stringAsLines deltaData.right
      sm = new difflib.SequenceMatcher(left, right)
      opcodes = sm.get_opcodes()
      el = deltaEl.find('.text-diff')
      options = {baseTextLines: left, newTextLines: right, opcodes: opcodes}
      args = _.defaults options, TEXTDIFF_OPTIONS
      el.append(diffview.buildView(args))

  getApplicableDelta: ->
    delta = @model.getDelta()
    delta = deltasLib.pruneConflictsFromDelta delta, @conflicts if @conflicts
    delta = deltasLib.pruneExpandedDeltasFromDelta delta, @skippedDeltas if @skippedDeltas
    delta