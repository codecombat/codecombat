// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let HeroSelectModal;
require('app/styles/courses/hero-select-modal.sass');
const ModalView = require('views/core/ModalView');
const HeroSelectView = require('views/core/HeroSelectView');
const template = require('app/templates/courses/hero-select-modal');
const Classroom = require('models/Classroom');
const ThangTypes = require('collections/ThangTypes');
const State = require('models/State');
const ThangType = require('models/ThangType');
const User = require('models/User');

module.exports = (HeroSelectModal = (function() {
  HeroSelectModal = class HeroSelectModal extends ModalView {
    static initClass() {
      this.prototype.id = 'hero-select-modal';
      this.prototype.template = template;
      this.prototype.retainSubviews = true;

      this.prototype.events =
        {'click .select-hero-btn': 'onClickSelectHeroButton'};
    }

    constructor () {
      super()
      this.listenTo(this.insertSubView(new HeroSelectView({ showCurrentHero: true })),
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
})());
