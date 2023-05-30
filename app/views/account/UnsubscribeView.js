// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let UnsubscribeView;
import 'app/styles/account/unsubscribe-view.sass';
import RootView from 'views/core/RootView';
import template from 'app/templates/account/unsubscribe-view';
import { me } from 'core/auth';
import utils from 'core/utils';

export default UnsubscribeView = (function() {
  UnsubscribeView = class UnsubscribeView extends RootView {
    static initClass() {
      this.prototype.id = 'unsubscribe-view';
      this.prototype.template = template;
  
      this.prototype.events =
        {'click #unsubscribe-button': 'onUnsubscribeButtonClicked'};
    }

    initialize() {
      return this.email = utils.getQueryVariable('email');
    }

    getMeta() {
      return {title: $.i18n.t('account.unsubscribe_title')};
    }

    onUnsubscribeButtonClicked() {
      this.$el.find('#unsubscribe-button').hide();
      this.$el.find('.progress').show();
      this.$el.find('.alert').hide();

      const email = utils.getQueryVariable('email');
      const url = `/auth/unsubscribe?email=${encodeURIComponent(email)}`;

      const success = () => {
        this.$el.find('.progress').hide();
        this.$el.find('#success-alert').show();
        return me.fetch({cache: false});
      };

      const error = () => {
        this.$el.find('.progress').hide();
        this.$el.find('#fail-alert').show();
        return this.$el.find('#unsubscribe-button').show();
      };

      return $.ajax({ url, success, error, cache: false });
    }
  };
  UnsubscribeView.initClass();
  return UnsubscribeView;
})();
