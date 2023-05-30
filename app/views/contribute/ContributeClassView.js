/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ContributeClassView;
const CreateAccountModal = require('views/core/CreateAccountModal');
const RootView = require('views/core/RootView');
const {me} = require('core/auth');
const contributorSignupAnonymousTemplate = require('app/templates/contribute/contributor_signup_anonymous');
const contributorSignupTemplate = require('app/templates/contribute/contributor_signup');
const contributorListTemplate = require('app/templates/contribute/contributor_list');

module.exports = (ContributeClassView = (function() {
  ContributeClassView = class ContributeClassView extends RootView {
    static initClass() {
  
      this.prototype.events =
        {'change input[type="checkbox"]': 'onCheckboxChanged'};
    }

    afterRender() {
      super.afterRender();
      this.$el.find('.contributor-signup-anonymous').replaceWith(contributorSignupAnonymousTemplate({me}));
      this.$el.find('.contributor-signup').each(function() {
        const context = {me, contributorClassName: $(this).data('contributor-class-name')};
        return $(this).replaceWith(contributorSignupTemplate(context));
      });
      this.$el.find('#contributor-list').replaceWith(contributorListTemplate({contributors: this.contributors, contributorClassName: this.contributorClassName}));

      const checkboxes = this.$el.find('input[type="checkbox"]').toArray();
      return _.forEach(checkboxes, function(el) {
        el = $(el);
        if (me.isEmailSubscriptionEnabled(el.attr('name')+'News')) { return el.prop('checked', true); }
      });
    }

    onCheckboxChanged(e) {
      const el = $(e.target);
      const checked = el.prop('checked');
      const subscription = el.attr('name');

      me.setEmailSubscription(subscription+'News', checked);
      me.patch();
      if (me.get('anonymous')) { this.openModalView(new CreateAccountModal()); }
      return el.parent().find('.saved-notification').finish().show('fast').delay(3000).fadeOut(2000);
    }
  };
  ContributeClassView.initClass();
  return ContributeClassView;
})());
