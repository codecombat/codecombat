CocoView = require 'views/kinds/CocoView'
template = require 'templates/editor/delta'
deltaLib = require 'lib/deltas'

module.exports = class DeltaListView extends CocoView
  @deltaCounter: 0
  className: "delta-list-view"
  template: template

  constructor: (options) ->
    super(options)
    @model = options.model

  getRenderData: ->
    c = super()
    c.deltas = @processedDeltas = @model.getExpandedDelta()
    c.counter = DeltaListView.deltaCounter
    DeltaListView.deltaCounter += c.deltas.length
    c
    
  afterRender: ->
    deltas = @$el.find('.delta')
    for delta, i in deltas
      deltaEl = $(delta)
      deltaData = @processedDeltas[i]
      console.log 'delta', deltaEl, deltaData
      if _.isObject(deltaData.left) and leftEl = deltaEl.find('.old-value')
        options =
          data: deltaData.left
          schema: deltaData.schema
          readOnly: true
        treema = TreemaNode.make(leftEl, options)
        treema.build()

      if _.isObject(deltaData.right) and rightEl = deltaEl.find('.new-value')
        options =
          data: deltaData.right
          schema: deltaData.schema
          readOnly: true
        treema = TreemaNode.make(rightEl, options)
        treema.build()
