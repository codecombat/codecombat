// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let State;
import CocoModel from './CocoModel';
import schema from 'schemas/models/poll.schema';

export default State = (function() {
  State = class State extends CocoModel {
    static initClass() {
      this.className = 'State';
    }
  };
  State.initClass();
  return State;
})();
