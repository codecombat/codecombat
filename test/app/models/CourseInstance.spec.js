/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const CourseInstance = require('models/CourseInstance');
const factories = require('test/app/factories');

describe('CourseInstance', function() {
  
  beforeEach(function() {
    return this.courseInstance = factories.makeCourseInstance();
  });
  
  describe('addMember(userID, opts)', () => it('returns a jqxhr', function() {
    const res = this.courseInstance.addMember('1234');
    return expect(res.readyState).toBe(1);
  }));

  describe('addMembers(userIDs, opts)', () => it('returns a jqxhr', function() {
    const res = this.courseInstance.addMembers(['1234']);
    return expect(res.readyState).toBe(1);
  }));

  return describe('removeMember(userID, opts)', () => it('returns a jqxhr', function() {
    const res = this.courseInstance.removeMember('1234');
    return expect(res.readyState).toBe(1);
  }));
});
