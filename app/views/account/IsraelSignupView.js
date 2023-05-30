// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let IsraelSignupView;
import RootView from 'views/core/RootView';
import template from 'app/templates/account/israel-signup-view';
import forms from 'core/forms';
import errors from 'core/errors';
import utils from 'core/utils';
import User from 'models/User';
import State from 'models/State';

class AbortError extends Error {}

const formSchema = {
  type: 'object',
  properties: _.pick(User.schema.properties, 'name', 'password'),
  required: ['name', 'password']
};


export default IsraelSignupView = (function() {
  IsraelSignupView = class IsraelSignupView extends RootView {
    static initClass() {
      this.prototype.id = 'israel-signup-view';
      this.prototype.template = template;
  
      this.prototype.events = {
        'submit form': 'onSubmitForm',
        'input input[name="name"]': 'onChangeName',
        'input input[name="password"]': 'onChangePassword'
      };
    }

    initialize() {
      this.state = new State({
        fatalError: null,
        // Possible errors:
        //   'signed-in': They are logged in
        //   'missing-input': Required query parameters are not provided
        //   'email-exists': Given email exists in our system
        //   Any other string will be shown directly to user

        formError: null,
        loading: true,
        submitting: false,
        queryParams: _.pick(utils.getQueryVariables(),
          'israelId',
          'firstName',
          'lastName',
          'email',
          'school',
          'city',
          'state',
          'district'
        ),
        name: '',
        password: ''
      });

      const { israelId, email } = this.state.get('queryParams');

      // sanity checks
      if (!me.isAnonymous()) {
        this.state.set({fatalError: 'signed-in', loading: false});

      } else if (!israelId) {
        this.state.set({fatalError: 'missing-input', loading: false});

      } else if (email && !forms.validateEmail(email)) {
        this.state.set({fatalError: 'invalid-email', loading: false});

      } else if (!email) {
        this.state.set({loading: false});

      } else {
        User.checkEmailExists(email)
        .then(({exists}) => {
          this.state.set({loading: false});
          if (exists) {
            return this.state.set({fatalError: 'email-exists'});
          }
      }).catch(() => {
          return this.state.set({fatalError: $.i18n.t('loading_error.unknown'), loading: false});
        });
      }

      return this.listenTo(this.state, 'change', _.debounce(this.render));
    }

    getRenderData() {
      const c = super.getRenderData();
      return _.extend({}, this.state.attributes, c);
    }

    onChangeName(e) {
      // sync form info with state, but do not re-render
      return this.state.set({name: $(e.currentTarget).val()}, {silent: true});
    }

    onChangePassword(e) {
      return this.state.set({password: $(e.currentTarget).val()}, {silent: true});
    }

    displayFormSubmitting() {
      this.$('#create-account-btn').text($.i18n.t('signup.creating')).attr('disabled', true);
      return this.$('input').attr('disabled', true);
    }

    displayFormStandingBy() {
      this.$('#create-account-btn').text($.i18n.t('login.sign_up')).attr('disabled', false);
      return this.$('input').attr('disabled', false);
    }

    onSubmitForm(e) {

      // validate form with schema
      e.preventDefault();
      forms.clearFormAlerts(this.$el);
      this.state.set('formError', null);
      const data = forms.formToObject(e.currentTarget);
      const res = tv4.validateMultiple(data, formSchema);
      if (!res.valid) {
        forms.applyErrorsToForm(this.$('form'), res.errors);
        return;
      }

      // check for name conflicts
      const queryParams = this.state.get('queryParams');
      this.displayFormSubmitting();
      return User.checkNameConflicts(data.name)
      .then(({ suggestedName, conflicts }) => {
        const nameField = this.$('input[name="name"]');
        if (conflicts) {
          const suggestedNameText = $.i18n.t('signup.name_taken').replace('{{suggestedName}}', suggestedName);
          forms.setErrorToField(nameField, suggestedNameText);
          throw AbortError;
        }

        // Save new user settings, particularly properties handed in
        const school = _.pick(queryParams, 'state', 'city', 'district');
        if (queryParams.school) { school.name = queryParams.school; }
        me.set(_.pick(queryParams, 'firstName', 'lastName', 'israelId'));
        me.set({school});
        return me.save();
    }).then(() => {
        // sign up
        return me.signupWithPassword(
          this.state.get('name'),
          queryParams.email || '',
          this.state.get('password')
        );
      }).then(() => {
        // successful signup
        return application.router.navigate('/play', { trigger: true });
      }).catch(e => {
        // if we threw the AbortError, the error was handled
        this.displayFormStandingBy();
        if (e === AbortError) {
          return;
        } else {
          // Otherwise, show a generic error
          console.error('IsraelSignupView form submission Promise error:', e);
          return this.state.set('formError', (e.responseJSON != null ? e.responseJSON.message : undefined) || e.message || 'Unknown Error');
        }
      });
    }
  };
  IsraelSignupView.initClass();
  return IsraelSignupView;
})();
