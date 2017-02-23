domainFilter = require '../../../server/middleware/domain-filter'

describe 'domainFilter', ->
  it 'works if hostname is not provided', ->
    req = { }
    res = { redirect: _.noop }
    next = jasmine.createSpy()
    domainFilter(req, res, next)
    expect(next).toHaveBeenCalled()
