/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ConditionalMinigameView;
const RootComponent = require('views/core/RootComponent');
const template = require('app/templates/base-flat');
const ConditionalMinigameComponent = require('./ConditionalMinigameComponent.vue').default;

module.exports = (ConditionalMinigameView = (function() {
  ConditionalMinigameView = class ConditionalMinigameView extends RootComponent {
    static initClass() {
      this.prototype.id = 'conditional-minigame-view';
      this.prototype.template = template;
      this.prototype.VueComponent = ConditionalMinigameComponent;
    }

    constructor(options) {
      super(options);
    }
  };
  ConditionalMinigameView.initClass();
  return ConditionalMinigameView;
})());
