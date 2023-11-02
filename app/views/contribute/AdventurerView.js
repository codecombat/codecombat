/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AdventurerView;
const ContributeClassView = require('./ContributeClassView');
const template = require('app/templates/contribute/adventurer');
const {me} = require('core/auth');

module.exports = (AdventurerView = (function() {
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
})());
