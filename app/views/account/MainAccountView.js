// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let MainAccountView;
import 'app/styles/account/main-account-view.sass';
import RootView from 'views/core/RootView';
import template from 'app/templates/account/main-account-view';

export default MainAccountView = (function() {
  MainAccountView = class MainAccountView extends RootView {
    static initClass() {
      this.prototype.id = 'main-account-view';
      this.prototype.template = template;
  
      this.prototype.events =
        {'click .logout-btn': 'logoutAccount'};
    }

    getMeta() {
      return {title: $.i18n.t('account.title')};
    }
  };
  MainAccountView.initClass();
  return MainAccountView;
})();
