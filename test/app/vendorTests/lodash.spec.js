describe 'merge', ->
  it 'combines nested objects recursively', ->
    a = { i: 0, nest: { iii: 0 }}
    b = { ii: 0, nest: { iv: 0 }}
    res = _.merge(a, b)
    expect(_.isEqual(res, { i: 0, ii: 0, nest: {iii:0, iv:0}})).toBeTruthy()
    
  it 'overwrites values from source to object', ->
    a = { i: 0 }
    b = { i: 1 }
    res = _.merge(a, b)
    expect(_.isEqual(res, b)).toBeTruthy()
    
  it 'treats arrays as atomic', ->
    a = { i: 0 }
    b = { i: [1,2,3] }
    res = _.merge(a, b)
    expect(_.isEqual(res, b)).toBeTruthy()

    a = { i: [5,4,3] }
    b = { i: [1,2,3] }
    res = _.merge(a, b)
    expect(_.isEqual(res, b)).toBeTruthy()