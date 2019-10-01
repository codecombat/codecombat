deltas = require 'core/deltas'

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
      
  describe 'expandDelta', ->
    it 'should not be confused by array index changes', ->
      copy = (x) -> JSON.parse(JSON.stringify(x))
      x = ({value: y, id: "ID:#{y}", squared: y*y} for y in [0..7])
      x[3].target = 1;
      x1 = copy(x)
      x[3].target = -1;
      x.splice(0, 0, {id: 'New'})
      x2 = copy(x)

      differ = deltas.makeJSONDiffer()
      delta = deltas.expandDelta(differ.diff({V: x1},  {V: x2}), {V: x1})

      expect(delta[1].humanPath).toEqual "V :: ID:3 :: Target"
      expect(delta[1].oldValue).toEqual 1
      expect(delta[1].newValue).toEqual -1
      