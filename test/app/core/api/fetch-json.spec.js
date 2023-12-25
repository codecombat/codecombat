/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const fetchJson = require('core/api/fetch-json');

describe('fetchJson', function() {
  beforeEach(() => spyOn(window, 'fetch').and.returnValue(Promise.resolve({
    status: 200,
    json() { return {}; },
    text() { return '{}'; },
    headers: {
      get(attr) {
        if (attr === 'content-type') {
          return 'application/json';
        } else {
          throw new Error("Tried to access a value on the response that we didn't stub!");
        }
      }
      }
    })));

  return it('should leave the original `options` intact', function() {
    const options = {
      url: 'foo',
      json: {
        thing: 'stuff'
      },
      data: {
        something: 1,
        another: 30
      }
    };
    const originalOptions = _.cloneDeep(options);
    fetchJson("/db/classroom/classroomID/courses/courseID/levels", options);
    return expect(options).toDeepEqual(originalOptions);
  });
});
