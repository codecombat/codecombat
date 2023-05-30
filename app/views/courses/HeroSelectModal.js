// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let HeroSelectModal;
import 'app/styles/courses/hero-select-modal.sass';
import ModalView from 'views/core/ModalView';
import HeroSelectView from 'views/core/HeroSelectView';
import template from 'app/templates/courses/hero-select-modal';
import Classroom from 'models/Classroom';
import ThangTypes from 'collections/ThangTypes';
import State from 'models/State';
import ThangType from 'models/ThangType';
import User from 'models/User';

export default HeroSelectModal = (function() {
  HeroSelectModal = class HeroSelectModal extends ModalView {
    static initClass() {
      this.prototype.id = 'hero-select-modal';
      this.prototype.template = template;
      this.prototype.retainSubviews = true;
  
      this.prototype.events =
        {'click .select-hero-btn': 'onClickSelectHeroButton'};
    }

    initialize() {
      return this.listenTo(this.insertSubView(new HeroSelectView({ showCurrentHero: true })),
        'hero-select:success', function(hero) {
          if (!this.destroyed) { return this.trigger('hero-select:success', hero); }
      });
    }

    onClickSelectHeroButton() {
      return this.hide();
    }
  };
  HeroSelectModal.initClass();
  return HeroSelectModal;
})();
