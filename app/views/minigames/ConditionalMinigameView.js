/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ConditionalMinigameView;
import RootComponent from 'views/core/RootComponent';
import template from 'app/templates/base-flat';
import ConditionalMinigameComponent from './ConditionalMinigameComponent.vue';

export default ConditionalMinigameView = (function() {
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
})();
