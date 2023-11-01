// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
/*
  Same interface as the normal fetch API, except that:

  * credentials are 'same-origin' by default
  * if a "json" option is included, the options are set up to
    properly submit the value as JSON data.
  * if a "data" option is included, it should be an object of
    GET query string parameters. These will be appended to the
    url. This matches the jQuery.ajax behavior.
  * if the response is json, it's parsed
  * if the response is an error, an error (plain) object is thrown
*/
const utils = require('core/utils');

const fetchWrapper = function(url, options) {
  if (options == null) { options = {}; }
  options = _.cloneDeep(options);
  if (!_.isUndefined(options.json)) {
    if (options.headers == null) { options.headers = {}; }
    options.headers['content-type'] = 'application/json';
    options.body = JSON.stringify(options.json);
    delete options.json;
  }
  if (options.data) {
    // shore up fetch API: https://github.com/github/fetch/issues/256
    url = url.split('?')[0] + '?' + $.param(options.data);
    delete options.data;
  }
  if (options.callOz) {
    url = utils.getProductUrl('OZ', url);
  }
  if (options.credentials == null) { options.credentials = 'same-origin'; }

  return fetch(url, options).then(function(res) {
    const isJson = _.string.startsWith(res.headers.get('content-type'), 'application/json');
    if (res.status >= 400) {
      if (isJson) {
        // should be a standard server error response, see /server/commons/errors.coffee for schema
        return res.json().then(json => Promise.reject(Object.assign({ code: res.status }, json)));
      } else {
        // old style (handler) raw text response. Wrap it in an object.
        return res.text().then(message => Promise.reject({message, code: res.status }));
      }
    }
    if (isJson) { return res.json(); } else { return res.text(); }
  });
};

module.exports = fetchWrapper;
