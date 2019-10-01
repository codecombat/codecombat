fetchJson = require('core/api/fetch-json')

describe 'fetchJson', ->
  beforeEach ->
    spyOn(window, 'fetch').and.returnValue(Promise.resolve({
      status: 200
      json: -> {}
      text: -> '{}'
      headers: {
        get: (attr) ->
          if attr is 'content-type'
            return 'application/json'
          else
            throw new Error("Tried to access a value on the response that we didn't stub!")
        }
      }))

  it 'should leave the original `options` intact', ->
    options = {
      url: 'foo'
      json: {
        thing: 'stuff'
      }
      data: {
        something: 1
        another: 30
      }
    }
    originalOptions = _.cloneDeep(options)
    fetchJson("/db/classroom/classroomID/courses/courseID/levels", options)
    expect(options).toDeepEqual(originalOptions)
