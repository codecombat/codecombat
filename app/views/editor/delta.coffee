CocoView = require 'views/kinds/CocoView'
template = require 'templates/editor/delta'
deltaLib = require 'lib/deltas'

module.exports = class DeltaListView extends CocoView
  id: "delta-list-view"
  template: template

  constructor: (options) ->
    super(options)
    @delta = options.delta
    @schema = options.schema or {}
    @left = options.left

  getRenderData: ->
    c = super()
    deltas = deltaLib.flattenDelta @delta
    deltas = (deltaLib.interpretDelta(d.delta, d.path, @left, @schema) for d in deltas)
    c.deltas = deltas
    @processedDeltas = deltas
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

      if _.isObject(deltaData.right) and rightEl = deltaEl.find('.old-value')
        options =
          data: deltaData.right
          schema: deltaData.schema
          readOnly: true
        treema = TreemaNode.make(rightEl, options)
        treema.build()
