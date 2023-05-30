// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
import fetchJson from './fetch-json';

export default {
  getDirectory({path}, options) {
    if (options == null) { options = {}; }
    if (!_.string.endsWith(path, '/')) {
      path = path + '/';
    }
    return fetchJson(`/file/${path}`, options).then(res => JSON.parse(res));
  },
    
  saveFile({url, filename, mimetype, path, force}, options) {
    if (options == null) { options = {}; }
    return fetchJson('/file', _.assign({}, options, {
      method: 'POST',
      json: { url, filename, mimetype, path, force }
    }));
  }
};
