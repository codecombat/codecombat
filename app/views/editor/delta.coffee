CocoView = require 'views/kinds/CocoView'
template = require 'templates/editor/delta'
deltasLib = require 'lib/deltas'

TEXTDIFF_OPTIONS =
  baseTextName: "Old"
  newTextName: "New"
  contextSize: 5
  viewType: 1
  
module.exports = class DeltaView extends CocoView
  @deltaCounter: 0
  className: "delta-view"
  template: template

  constructor: (options) ->
    super(options)
    @model = options.model
    @headModel = options.headModel
    @expandedDeltas = @model.getExpandedDelta()
    if @headModel
      @headDeltas = @headModel.getExpandedDelta()
      @conflicts = deltasLib.getConflicts(@headDeltas, @expandedDeltas)

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
    treemaOptions = { schema: deltaData.schema, readOnly: true }
    
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
    delta