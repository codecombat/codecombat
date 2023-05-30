/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const fetchJson = require('./fetch-json');

module.exports = {
  getMarkdownFile(fileName, options) {
    console.log('get markdown file', fileName);
    return fetchJson('/markdown/'+fileName, options);
  }
};
