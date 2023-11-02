/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let InteractiveSession;
const CocoModel = require('./CocoModel');
const schema = require('schemas/models/interactives/interactive_session.schema');

module.exports = (InteractiveSession = (function() {
  InteractiveSession = class InteractiveSession extends CocoModel {
    static initClass() {
      this.className = 'InteractiveSession';
      this.schema = schema;
      this.prototype.urlRoot = '/db/interactive.session';
    }
  };
  InteractiveSession.initClass();
  return InteractiveSession;
})());
