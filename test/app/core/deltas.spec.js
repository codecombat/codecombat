/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const deltas = require('core/deltas');

describe('deltas lib', function() {
  
  describe('getConflicts', () => it('handles conflicts where one change conflicts with several changes', function() {
    const originalData = {list:[1,2,3]};
    const forkA = {list:['1', 2, '3']};
    const forkB = {noList: '...'};
    const differ = deltas.makeJSONDiffer();
    
    const expandedDeltaA = deltas.expandDelta(differ.diff(originalData, forkA));
    const expandedDeltaB = deltas.expandDelta(differ.diff(originalData, forkB));
    deltas.getConflicts(expandedDeltaA, expandedDeltaB);
    return Array.from(expandedDeltaA).map((delta) =>
      expect(delta.conflict).toBeDefined());
  }));
      
  return describe('expandDelta', () => it('should not be confused by array index changes', function() {
    const copy = x => JSON.parse(JSON.stringify(x));
    const x = ([0, 1, 2, 3, 4, 5, 6, 7].map((y) => ({value: y, id: `ID:${y}`, squared: y*y})));
    x[3].target = 1;
    const x1 = copy(x);
    x[3].target = -1;
    x.splice(0, 0, {id: 'New'});
    const x2 = copy(x);

    const differ = deltas.makeJSONDiffer();
    const delta = deltas.expandDelta(differ.diff({V: x1},  {V: x2}), {V: x1});

    expect(delta[1].humanPath).toEqual("V :: ID:3 :: Target");
    expect(delta[1].oldValue).toEqual(1);
    return expect(delta[1].newValue).toEqual(-1);
  }));
});
      