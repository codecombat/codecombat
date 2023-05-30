// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ChooseLanguageModal;
import 'app/styles/courses/choose-language-modal.sass';
import ModalView from 'views/core/ModalView';
import template from 'app/templates/courses/choose-language-modal';

export default ChooseLanguageModal = (function() {
  ChooseLanguageModal = class ChooseLanguageModal extends ModalView {
    static initClass() {
      this.prototype.id = 'choose-language-modal';
      this.prototype.template = template;
  
      this.prototype.events =
        {'click .lang-choice-btn': 'onClickLanguageChoiceButton'};
    }

    initialize(options) {
      if (options == null) { options = {}; }
      return this.logoutFirst = options.logoutFirst;
    }

    onClickLanguageChoiceButton(e) {
      this.chosenLanguage = $(e.target).closest('.lang-choice-btn').data('language');
      if (this.logoutFirst) {
        return this.logoutUser();
      } else {
        return this.saveLanguageSetting();
      }
    }

    logoutUser() {
      return $.ajax({
        method: 'POST',
        url: '/auth/logout',
        context: this,
        success: this.onUserLoggedOut
      });
    }

    onUserLoggedOut() {
      me.clear();
      me.fetch({
        url: '/auth/whoami'
      });
      return this.listenToOnce(me, 'sync', this.saveLanguageSetting);
    }

    saveLanguageSetting() {
      const aceConfig = _.clone(me.get('aceConfig') || {});
      aceConfig.language = this.chosenLanguage;
      me.set('aceConfig', aceConfig);
      const res = me.patch();
      if (res) {
        this.$('#choice-area').hide();
        this.$('#saving-progress').removeClass('hide');
        return this.listenToOnce(me, 'sync', this.onLanguageSettingSaved);
      } else {
        return this.onLanguageSettingSaved();
      }
    }

    onLanguageSettingSaved() {
      this.trigger('set-language');
      if (window.tracker != null) {
        window.tracker.trackEvent('Chose language', {category: 'Courses', label: this.chosenLanguage});
      }
      return this.hide();
    }
  };
  ChooseLanguageModal.initClass();
  return ChooseLanguageModal;
})();
