// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let InteractiveSession;
import CocoModel from './CocoModel';
import schema from 'schemas/models/interactives/interactive_session.schema';

export default InteractiveSession = (function() {
  InteractiveSession = class InteractiveSession extends CocoModel {
    static initClass() {
      this.className = 'InteractiveSession';
      this.schema = schema;
      this.prototype.urlRoot = '/db/interactive.session';
    }
  };
  InteractiveSession.initClass();
  return InteractiveSession;
})();
