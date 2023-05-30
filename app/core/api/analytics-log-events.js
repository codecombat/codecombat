// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const fetchJson = require('./fetch-json');

module.exports = {
  post({event, properties}, options) {
    return fetchJson('/db/analytics.log.event/-/log_event', _.assign({}, options, {
      method: 'POST',
      json: {
        event,
        properties
      }
    }));
  }
};
