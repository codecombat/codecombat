// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ExtrasView;
import 'app/styles/modal/create-account-modal/extras-view.sass';
import CocoView from 'views/core/CocoView';
import HeroSelectView from 'views/core/HeroSelectView';
import template from 'app/templates/core/create-account-modal/extras-view';
import State from 'models/State';

export default ExtrasView = (function() {
  ExtrasView = class ExtrasView extends CocoView {
    static initClass() {
      this.prototype.id = 'extras-view';
      this.prototype.template = template;
      this.prototype.retainSubviews = true;
  
      this.prototype.events = {
        'click .next-button'() {
          if (this.signupState.get('path') === 'student') {
            if (window.tracker != null) {
              window.tracker.trackEvent('CreateAccountModal Student ExtrasView Next Clicked', {category: 'Students'});
            }
          }
          return this.trigger('nav-forward');
        }
      };
    }

    initialize(param) {
      if (param == null) { param = {}; }
      const { signupState } = param;
      this.signupState = signupState;
      return this.insertSubView(new HeroSelectView({ showCurrentHero: false, createAccount: true }));
    }
  };
  ExtrasView.initClass();
  return ExtrasView;
})();
