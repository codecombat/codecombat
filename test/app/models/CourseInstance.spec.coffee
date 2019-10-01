CourseInstance = require 'models/CourseInstance'
factories = require 'test/app/factories'

describe 'CourseInstance', ->
  
  beforeEach ->
    @courseInstance = factories.makeCourseInstance()
  
  describe 'addMember(userID, opts)', ->
    it 'returns a jqxhr', ->
      res = @courseInstance.addMember('1234')
      expect(res.readyState).toBe(1)

  describe 'addMembers(userIDs, opts)', ->
    it 'returns a jqxhr', ->
      res = @courseInstance.addMembers(['1234'])
      expect(res.readyState).toBe(1)

  describe 'removeMember(userID, opts)', ->
    it 'returns a jqxhr', ->
      res = @courseInstance.removeMember('1234')
      expect(res.readyState).toBe(1)
