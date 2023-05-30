// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AdventurerView;
import ContributeClassView from './ContributeClassView';
import template from 'app/templates/contribute/adventurer';
import { me } from 'core/auth';

export default AdventurerView = (function() {
  AdventurerView = class AdventurerView extends ContributeClassView {
    static initClass() {
      this.prototype.id = 'adventurer-view';
      this.prototype.template = template;
    }

    initialize() {
      return this.contributorClassName = 'adventurer';
    }
  };
  AdventurerView.initClass();
  return AdventurerView;
})();
