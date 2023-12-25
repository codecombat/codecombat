/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
describe('merge', function() {
  it('combines nested objects recursively', function() {
    const a = { i: 0, nest: { iii: 0 }};
    const b = { ii: 0, nest: { iv: 0 }};
    const res = _.merge(a, b);
    return expect(_.isEqual(res, { i: 0, ii: 0, nest: {iii:0, iv:0}})).toBeTruthy();
  });
    
  it('overwrites values from source to object', function() {
    const a = { i: 0 };
    const b = { i: 1 };
    const res = _.merge(a, b);
    return expect(_.isEqual(res, b)).toBeTruthy();
  });
    
  return it('treats arrays as atomic', function() {
    let a = { i: 0 };
    let b = { i: [1,2,3] };
    let res = _.merge(a, b);
    expect(_.isEqual(res, b)).toBeTruthy();

    a = { i: [5,4,3] };
    b = { i: [1,2,3] };
    res = _.merge(a, b);
    return expect(_.isEqual(res, b)).toBeTruthy();
  });
});