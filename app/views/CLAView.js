// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CLAView;
import 'app/styles/cla.sass';
import RootView from 'views/core/RootView';
import template from 'app/templates/cla';
import { me } from 'core/auth';

export default CLAView = (function() {
  CLAView = class CLAView extends RootView {
    constructor(...args) {
      this.onAgreeSucceeded = this.onAgreeSucceeded.bind(this);
      this.onAgreeFailed = this.onAgreeFailed.bind(this);
      super(...args);
    }

    static initClass() {
      this.prototype.id = 'cla-view';
      this.prototype.template = template;
  
      this.prototype.events =
        {'click #agreement-button': 'onAgree'};
    }

    onAgree() {
      this.$el.find('#agreement-button').prop('disabled', true).text('Saving');
      return $.ajax({
        url: '/db/user/me/agreeToCLA',
        data: {'githubUsername': this.$el.find('#github-username').val()},
        method: 'POST',
        success: this.onAgreeSucceeded,
        error: this.onAgreeFailed
      });
    }

    onAgreeSucceeded() {
      return this.$el.find('#agreement-button').text('Success');
    }

    onAgreeFailed() {
      return this.$el.find('#agreement-button').text('Failed');
    }
  };
  CLAView.initClass();
  return CLAView;
})();
