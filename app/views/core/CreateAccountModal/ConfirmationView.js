/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ConfirmationView;
require('app/styles/modal/create-account-modal/confirmation-view.sass');
const CocoView = require('views/core/CocoView');
const State = require('models/State');
const template = require('app/templates/core/create-account-modal/confirmation-view');
const forms = require('core/forms');
const NcesSearchInput = require('./teacher/NcesSearchInput');
const userUtils = require('../../../lib/user-utils');

module.exports = (ConfirmationView = (function() {
  ConfirmationView = class ConfirmationView extends CocoView {
    static initClass() {
      this.prototype.id = 'confirmation-view';
      this.prototype.template = template;
  
      this.prototype.events =
        {'click #start-btn': 'onClickStartButton'};
    }

    initialize(param) {
      if (param == null) { param = {}; }
      const { signupState } = param;
      this.signupState = signupState;
      this.saveUserPromise = Promise.resolve();
      // I think it can go to Ozaria as well.
      return this.hideEmail = userUtils.shouldHideEmail();
    }

    onClickStartButton() {
      return this.saveUserPromise.then(() => {
        // I think it can go to Ozaria as well.
        if (window.nextURL) {
          window.location.href = window.nextURL;
          return;
        }

        const classroom = this.signupState.get('classroom');
        if (this.signupState.get('path') === 'student') {
          // force clearing of _cc GET param from url if on /students
          application.router.navigate('/', {replace: true});
          application.router.navigate('/students');
        } else {
          application.router.navigate('/play');
        }
        return document.location.reload();
      });
    }

    afterRender() {
      const target = this.$el.find('#nces-search-input');
      if (!target[0]) { return; }
      if (this.ncesSearchInput) {
        return target.replaceWith(this.ncesSearchInput.$el);
      } else {
        this.ncesSearchInput = new NcesSearchInput({
          el: target[0],
          propsData: {
            label: $.i18n.t("teachers_quote.school_name"),
            displayKey: 'name',
            name: 'School Name',
            initialValue: ''
          }
        });
        return this.ncesSearchInput.$on('navSearchChoose', (displayKey, fullNcesEntry) => {
          // Ignore updateValue event (what they typed), only use selected search result values
          me.set({
            school: fullNcesEntry
          });
          this.ncesSearchInput.$data.value = fullNcesEntry[displayKey];
          return this.saveUserPromise = new Promise(me.save().then);
        });
      }
    }
  };
  ConfirmationView.initClass();
  return ConfirmationView;
})());
