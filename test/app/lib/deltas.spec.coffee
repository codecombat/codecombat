deltas = require 'lib/deltas'

describe 'deltas lib', ->
  
  describe 'getConflicts', ->
  
    it 'handles conflicts where one change conflicts with several changes', ->
      originalData = {list:[1,2,3]}
      forkA = {list:['1', 2, '3']}
      forkB = {noList: '...'}
      differ = deltas.makeJSONDiffer()
      
      expandedDeltaA = deltas.expandDelta(differ.diff originalData, forkA)
      expandedDeltaB = deltas.expandDelta(differ.diff originalData, forkB)
      deltas.getConflicts(expandedDeltaA, expandedDeltaB)
      for delta in expandedDeltaA
        expect(delta.conflict).toBeDefined()
      