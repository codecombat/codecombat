/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CreateTeacherAccountView;
require('app/styles/teachers/teacher-trial-requests.sass');
const RootView = require('views/core/RootView');
const forms = require('core/forms');
const TrialRequest = require('models/TrialRequest');
const TrialRequests = require('collections/TrialRequests');
const AuthModal = require('views/core/AuthModal');
const errors = require('core/errors');
const User = require('models/User');
const algolia = require('core/services/algolia');
const State = require('models/State');
const countryList = require('country-list')();
const {
  UsaStates
} = require('usa-states');
const globalVar = require('core/globalVar');
const utils = require('core/utils');


const SIGNUP_REDIRECT = '/teachers/classes';
const DISTRICT_NCES_KEYS = ['district', 'district_id', 'district_schools', 'district_students', 'phone'];
const SCHOOL_NCES_KEYS = DISTRICT_NCES_KEYS.concat(['id', 'name', 'students']);

module.exports = (CreateTeacherAccountView = (function() {
  CreateTeacherAccountView = class CreateTeacherAccountView extends RootView {
    static initClass() {
      this.prototype.id = 'create-teacher-account-view';
      this.prototype.template = require('app/templates/teachers/create-teacher-account-view');

      this.prototype.events = {
        'click .login-link': 'onClickLoginLink',
        'change form#signup-form': 'onChangeForm',
        'submit form#signup-form': 'onSubmitForm',
        'click #google-login-button-ctav': 'onClickGPlusSignupButton',
        'click #facebook-signup-btn': 'onClickFacebookSignupButton',
        'change input[name="city"]': 'invalidateNCES',
        'change input[name="state"]': 'invalidateNCES',
        'change select[name="state"]': 'invalidateNCES',
        'change input[name="district"]': 'invalidateNCES',
        'change select[name="country"]': 'onChangeCountry',
        'change input[name="email"]': 'onChangeEmail',
        'change input[name="name"]': 'onChangeName'
      };
    }

    getRenderData() {
      return _.merge(super.getRenderData(...arguments), { product: utils.getProductName() });
    }

    constructor () {
      super(...arguments)
      this.trialRequest = new TrialRequest();
      this.trialRequests = new TrialRequests();
      this.trialRequests.fetchOwn();
      this.supermodel.trackCollection(this.trialRequests);
      if (window.tracker) {
        window.tracker.trackEvent('Teachers Create Account Loaded', {category: 'Teachers'});
      }
      this.state = new State({
        suggestedNameText: '...',
        checkEmailState: 'standby', // 'checking', 'exists', 'available'
        checkEmailValue: null,
        checkEmailPromise: null,
        checkNameState: 'standby', // same
        checkNameValue: null,
        checkNamePromise: null,
        authModalInitialValues: {},
        showUsaStateDropdown: true,
        stateValue: null
      });
      this.countries = countryList.getNames();
      this.usaStates = new UsaStates().states;
      this.usaStatesAbbreviations = new UsaStates().arrayOf('abbreviations');
      this.listenTo(this.state, 'change:checkEmailState', function() { return this.renderSelectors('.email-check'); });
      this.listenTo(this.state, 'change:checkNameState', function() { return this.renderSelectors('.name-check'); });
      this.listenTo(this.state, 'change:error', function() { return this.renderSelectors('.error-area'); });
      this.listenTo(this.state, 'change:showUsaStateDropdown', function() { return this.renderSelectors('.state'); });
      this.listenTo(this.state, 'change:stateValue', function() { return this.renderSelectors('.state'); });
    }

    onLeaveMessage() {
      if (this.formChanged) {
        return 'Your account has not been created! If you continue, your changes will be lost.';
      }
    }

    onLoaded() {
      if (this.trialRequests.size()) {
        this.trialRequest = this.trialRequests.first();
        this.state.set({
          authModalInitialValues: {
            email: __guard__(this.trialRequest != null ? this.trialRequest.get('properties') : undefined, x => x.email)
          }
        });
      }
      this.onClickGPlusSignupButton();
      return super.onLoaded();
    }

    invalidateNCES() {
      return Array.from(SCHOOL_NCES_KEYS).map((key) =>
        this.$('input[name="nces_' + key + '"]').val(''));
    }

    onChangeCountry(e) {
      this.invalidateNCES();

      let stateElem = this.$('select[name="state"]');
      if (this.$('[name="state"]').prop('nodeName') === 'INPUT') {
        stateElem = this.$('input[name="state"]');
      }
      const stateVal = stateElem.val();
      this.state.set({stateValue: stateVal});

      if (e.target.value === 'United States') {
        this.state.set({showUsaStateDropdown: true});
        if (!this.usaStatesAbbreviations.includes(stateVal)) {
          return this.state.set({stateValue: ''});
        }
      } else {
        return this.state.set({showUsaStateDropdown: false});
      }
    }

    afterRender() {
      super.afterRender();

      // apply existing trial request on form
      const properties = this.trialRequest.get('properties');
      if (properties) {
        forms.objectToForm(this.$('form'), properties);
        const commonLevels = _.map(this.$('[name="educationLevel"]'), el => $(el).val());
        const submittedLevels = properties.educationLevel || [];
        const otherLevel = _.first(_.difference(submittedLevels, commonLevels)) || '';
        this.$('#other-education-level-checkbox').attr('checked', !!otherLevel);
        this.$('#other-education-level-input').val(otherLevel);
      }

      this.$("#organization-control").algolia_autocomplete({hint: false}, [{
        source(query, callback) {
          return algolia.schoolsIndex.search(query, { hitsPerPage: 5, aroundLatLngViaIP: false }).then(answer => callback(answer.hits)
          , () => callback([]));
        },
        displayKey: 'name',
        templates: {
          suggestion(suggestion) {
            const hr = suggestion._highlightResult;
            return `<div class='school'> ${hr.name.value} </div>` +
              `<div class='district'>${hr.district.value}, ` +
                `<span>${(hr.city != null ? hr.city.value : undefined)}, ${hr.state.value}</span></div>`;
          }
        }
      }
      ]).on('autocomplete:selected', (event, suggestion, dataset) => {
        // Tell Algolioa about the change but don't open the suggestion dropdown
        this.$('input[name="district"]').val(suggestion.district).trigger('input').trigger('blur');
        this.$('input[name="city"]').val(suggestion.city);
        this.$('input[name="state"]').val(suggestion.state);
        this.$('select[name="state"]').val(suggestion.state);
        this.$('select[name="country"]').val('United States');
        this.state.set({showUsaStateDropdown: true});
        this.state.set({stateValue: suggestion.state});
        for (var key of Array.from(SCHOOL_NCES_KEYS)) {
          this.$('input[name="nces_' + key + '"]').val(suggestion[key]);
        }
        return this.onChangeForm();
      });

      return this.$("#district-control").algolia_autocomplete({hint: false}, [{
        source(query, callback) {
          return algolia.schoolsIndex.search(query, { hitsPerPage: 5, aroundLatLngViaIP: false }).then(answer => callback(answer.hits)
          , () => callback([]));
        },
        displayKey: 'district',
        templates: {
          suggestion(suggestion) {
            const hr = suggestion._highlightResult;
            return `<div class='district'>${hr.district.value}, ` +
              `<span>${(hr.city != null ? hr.city.value : undefined)}, ${hr.state.value}</span></div>`;
          }
        }
      }
      ]).on('autocomplete:selected', (event, suggestion, dataset) => {
        this.$('input[name="organization"]').val('').trigger('input').trigger('blur');
        this.$('input[name="city"]').val(suggestion.city);
        this.$('input[name="state"]').val(suggestion.state);
        this.$('select[name="state"]').val(suggestion.state);
        this.$('select[name="country"]').val('United States');
        this.state.set({showUsaStateDropdown: true});
        this.state.set({stateValue: suggestion.state});
        for (var key of Array.from(DISTRICT_NCES_KEYS)) {
          this.$('input[name="nces_' + key + '"]').val(suggestion[key]);
        }
        return this.onChangeForm();
      });
    }

    onClickLoginLink() {
      return this.openModalView(new AuthModal({ initialValues: this.state.get('authModalInitialValues') }));
    }

    onChangeForm() {
      if (!this.formChanged) {
        if (window.tracker != null) {
          window.tracker.trackEvent('Teachers Create Account Form Started', {category: 'Teachers'});
        }
      }
      return this.formChanged = true;
    }

    onSubmitForm(e) {
      e.preventDefault();

      // Creating Trial Request first, validate user attributes but do not use them
      const form = this.$('form');
      const allAttrs = forms.formToObject(form);
      let trialRequestAttrs = _.omit(allAttrs, 'name', 'password1', 'password2');

      // Don't save n/a district entries, but do validate required district client-side
      if (trialRequestAttrs.district != null ? trialRequestAttrs.district.replace(/\s/ig, '').match(/n\/a/ig) : undefined) { trialRequestAttrs = _.omit(trialRequestAttrs, 'district'); }

      if (this.$('#other-education-level-checkbox').is(':checked')) {
        const val = this.$('#other-education-level-input').val();
        if (val) { trialRequestAttrs.educationLevel.push(val); }
      }

      forms.clearFormAlerts(form);

      const result = tv4.validateMultiple(trialRequestAttrs, formSchema);
      let error = false;
      if (!result.valid) {
        forms.applyErrorsToForm(form, result.errors);
        error = true;
      }
      if (!error && !forms.validateEmail(trialRequestAttrs.email)) {
        forms.setErrorToProperty(form, 'email', 'invalid email');
        error = true;
      }
      if (!error && forms.validateEmail(allAttrs.name)) {
        forms.setErrorToProperty(form, 'name', 'username may not be an email');
        error = true;
      }
      if (!_.size(trialRequestAttrs.educationLevel)) {
        forms.setErrorToProperty(form, 'educationLevel', 'include at least one');
        error = true;
      }
      if (!allAttrs.name) {
        forms.setErrorToProperty(form, 'name', $.i18n.t('common.required_field'));
        error = true;
      }
      if (!allAttrs.district) {
        forms.setErrorToProperty(form, 'district', $.i18n.t('common.required_field'));
        error = true;
      }
      if (!this.gplusAttrs && !this.facebookAttrs) {
        if (!allAttrs.password1) {
          forms.setErrorToProperty(form, 'password1', $.i18n.t('common.required_field'));
          error = true;
        } else if (!allAttrs.password2) {
          forms.setErrorToProperty(form, 'password2', $.i18n.t('common.required_field'));
          error = true;
        } else if (allAttrs.password1 !== allAttrs.password2) {
          forms.setErrorToProperty(form, 'password1', 'Password fields are not equivalent');
          error = true;
        }
      }
      if (error) {
        forms.scrollToFirstError();
        return;
      }
      trialRequestAttrs['siteOrigin'] = 'create teacher';
      this.trialRequest = new TrialRequest({
        type: 'course',
        properties: trialRequestAttrs
      });
      this.trialRequest.notyErrors = false;
      this.$('#create-account-btn').text('Sending').attr('disabled', true);
      this.trialRequest.save();
      this.trialRequest.on('sync', this.onTrialRequestSubmit, this);
      return this.trialRequest.on('error', this.onTrialRequestError, this);
    }

    onTrialRequestError(model, jqxhr) {
      this.$('#create-account-btn').text('Submit').attr('disabled', false);
      if (jqxhr.status === 409) {
        const userExists = $.i18n.t('teachers_quote.email_exists');
        const logIn = $.i18n.t('login.log_in');
        this.$('#email-form-group')
          .addClass('has-error')
          .append($(`<div class='help-block error-help-block'>${userExists} <a class='login-link'>${logIn}</a>`));
        return forms.scrollToFirstError();
      } else {
        return errors.showNotyNetworkError(...arguments);
      }
    }

    onTrialRequestSubmit() {
      if (window.tracker != null) {
        window.tracker.trackEvent('Teachers Create Account Submitted', {category: 'Teachers'});
      }
      this.formChanged = false;

      return Promise.resolve()
      .then(() => {
        const attrs = _.pick(forms.formToObject(this.$('form')), 'role', 'firstName', 'lastName');
        attrs.role = attrs.role.toLowerCase();
        me.set(attrs);
        if (this.gplusAttrs) { me.set(_.omit(this.gplusAttrs, 'gplusID', 'email')); }
        if (this.facebookAttrs) { me.set(_.omit(this.facebookAttrs, 'facebookID', 'email')); }
        if (me.inEU()) {
          const emails = _.assign({}, me.get('emails'));
          if (emails.generalNews == null) { emails.generalNews = {}; }
          emails.generalNews.enabled = false;
          me.set('emails', emails);
          me.set('unsubscribedFromMarketingEmails', true);
        }
        const jqxhr = me.save();
        if (!jqxhr) {
          throw new Error('Could not save user');
        }
        this.trigger('update-settings');
        return jqxhr;
    }).then(() => {
        let jqxhr;
        let { name, email } = forms.formToObject(this.$('form'));
        if (this.gplusAttrs) {
          let gplusID;
          ({ email, gplusID } = this.gplusAttrs);
          ({ name } = forms.formToObject(this.$el));
          jqxhr = me.signupWithGPlus(name, email, this.gplusAttrs.gplusID);
        } else if (this.facebookAttrs) {
          let facebookID;
          ({ email, facebookID } = this.facebookAttrs);
          ({ name } = forms.formToObject(this.$el));
          jqxhr = me.signupWithFacebook(name, email, facebookID);
        } else {
          let password1;
          ({ name, email, password1 } = forms.formToObject(this.$el));
          jqxhr = me.signupWithPassword(name, email, password1);
        }
        this.trigger('signup');
        return jqxhr;
      }).then(() => {
        const trialRequestIdentifyData = _.pick(this.trialRequest.attributes.properties, ["siteOrigin", "marketingReferrer", "referrer", "notes", "numStudentsTotal", "numStudents", "purchaserRole", "role", "phoneNumber", "country", "state", "city", "district", "organization", "nces_students", "nces_name", "nces_id", "nces_phone", "nces_district_students", "nces_district_schools", "nces_district_id", "nces_district"]);
        trialRequestIdentifyData.educationLevel_elementary = _.contains(this.trialRequest.attributes.properties.educationLevel, "Elementary");
        trialRequestIdentifyData.educationLevel_middle = _.contains(this.trialRequest.attributes.properties.educationLevel, "Middle");
        trialRequestIdentifyData.educationLevel_high = _.contains(this.trialRequest.attributes.properties.educationLevel, "High");
        trialRequestIdentifyData.educationLevel_college = _.contains(this.trialRequest.attributes.properties.educationLevel, "College+");

        application.tracker.identifyAfterNextPageLoad();
        return globalVar.application.tracker.identify(trialRequestIdentifyData);
      }).then(() => {
        const trackerCalls = [];

        let loginMethod = 'CodeCombat';
        if (this.gplusAttrs) {
          loginMethod = 'GPlus';
          trackerCalls.push(
            window.tracker != null ? window.tracker.trackEvent('Google Login', {category: "Signup", label: 'GPlus'})
           : undefined);
        } else if (this.facebookAttrs) {
          loginMethod = 'Facebook';
          trackerCalls.push(
            window.tracker != null ? window.tracker.trackEvent('Facebook Login', {category: "Signup", label: 'Facebook'})
           : undefined);
        }

        return Promise.all(trackerCalls).catch(function() {});
      }).then(() => {
        application.router.navigate(SIGNUP_REDIRECT, { trigger: true });
        return application.router.reload();
      }).then(() => {
        return this.trigger('on-trial-request-submit-complete');
      }).catch(function(e) {
        if (e instanceof Error) {
          noty({
            text: e.message,
            layout: 'topCenter',
            type: 'error',
            timeout: 5000,
            killer: false,
            dismissQueue: true
          });
        } else {
          errors.showNotyNetworkError(...arguments);
        }
        return this.$('#create-account-btn').text('Submit').attr('disabled', false);
      }.bind(this));
    }


    // GPlus signup

    onClickGPlusSignupButton() {
      const btn = this.$('#google-login-button-ctav');
      btn.attr('disabled', true);
      return application.gplusHandler.loadAPI({
        success: () => {
          btn.attr('disabled', false);
          return application.gplusHandler.connect({
            elementId: 'google-login-button-ctav',
            success: resp => {
              if (resp == null) { resp = {}; }
              btn.find('.sign-in-blurb').text($.i18n.t('signup.creating'));
              btn.attr('disabled', true);
              return application.gplusHandler.loadPerson({
                resp,
                success: gplusAttrs => {
                  this.gplusAttrs = gplusAttrs;
                  const existingUser = new User();
                  return existingUser.fetchGPlusUser(this.gplusAttrs.gplusID, this.gplusAttrs.email, {
                    error: (user, jqxhr) => {
                      if (jqxhr.status === 404) {
                        return this.onGPlusConnected();
                      } else {
                        return errors.showNotyNetworkError(jqxhr);
                      }
                    },
                    success: () => {
                      return me.loginGPlusUser(this.gplusAttrs.gplusID, {
                        success() {
                          return application.router.navigate('/teachers/update-account', {trigger: true});
                        },
                        error: errors.showNotyNetworkError
                      });
                    }
                  });
                }
              });
            }
          });
        }
      });
    }

    onGPlusConnected() {
      this.formChanged = true;
      forms.objectToForm(this.$('form'), this.gplusAttrs);
      for (var field of ['email', 'firstName', 'lastName']) {
        var input = this.$(`input[name='${field}']`);
        if (input.val()) {
          input.attr('disabled', true);
        }
      }
      this.$('input[type="password"]').attr('disabled', true);
      return this.$('#gplus-logged-in-row, #social-network-signups').toggleClass('hide');
    }

    // Facebook signup

    onClickFacebookSignupButton() {
      const btn = this.$('#facebook-signup-btn');
      btn.attr('disabled', true);
      return application.facebookHandler.loadAPI({
        success: () => {
          btn.attr('disabled', false);
          return application.facebookHandler.connect({
            success: () => {
              btn.find('.sign-in-blurb').text($.i18n.t('signup.creating'));
              btn.attr('disabled', true);
              return application.facebookHandler.loadPerson({
                success: facebookAttrs => {
                  this.facebookAttrs = facebookAttrs;
                  const existingUser = new User();
                  return existingUser.fetchFacebookUser(this.facebookAttrs.facebookID, {
                    error: (user, jqxhr) => {
                      if (jqxhr.status === 404) {
                        return this.onFacebookConnected();
                      } else {
                        return errors.showNotyNetworkError(jqxhr);
                      }
                    },
                    success: () => {
                      return me.loginFacebookUser(this.facebookAttrs.facebookID, {
                        success() {
                          return application.router.navigate('/teachers/update-account', {trigger: true});
                        },
                        error: errors.showNotyNetworkError
                      });
                    }
                  });
                }
              });
            }
          });
        }
      });
    }

    onFacebookConnected() {
      this.formChanged = true;
      forms.objectToForm(this.$('form'), this.facebookAttrs);
      for (var field of ['email', 'firstName', 'lastName']) {
        var input = this.$(`input[name='${field}']`);
        if (input.val()) {
          input.attr('disabled', true);
        }
      }
      this.$('input[type="password"]').attr('disabled', true);
      return this.$('#facebook-logged-in-row, #social-network-signups').toggleClass('hide');
    }

    updateAuthModalInitialValues(values) {
      return this.state.set({
        authModalInitialValues: _.merge(this.state.get('authModalInitialValues'), values)
      }, { silent: true });
    }

    onChangeName(e) {
      this.updateAuthModalInitialValues({ name: this.$(e.currentTarget).val() });
      return this.checkName();
    }

    checkName() {
      const name = this.$('input[name="name"]').val();

      if (name === this.state.get('checkNameValue')) {
        return this.state.get('checkNamePromise');
      }

      if (!name) {
        this.state.set({
          checkNameState: 'standby',
          checkNameValue: name,
          checkNamePromise: null
        });
        return Promise.resolve();
      }

      this.state.set({
        checkNameState: 'checking',
        checkNameValue: name,

        checkNamePromise: (User.checkNameConflicts(name)
        .then(({ suggestedName, conflicts }) => {
          if (name !== this.$('input[name="name"]').val()) { return; }
          if (conflicts) {
            const suggestedNameText = $.i18n.t('signup.name_taken').replace('{{suggestedName}}', suggestedName);
            return this.state.set({ checkNameState: 'exists', suggestedNameText });
          } else {
            return this.state.set({ checkNameState: 'available' });
          }
      })
        .catch(error => {
          this.state.set('checkNameState', 'standby');
          throw error;
        }))
      });

      return this.state.get('checkNamePromise');
    }

    onChangeEmail(e) {
      this.updateAuthModalInitialValues({ email: this.$(e.currentTarget).val() });
      return this.checkEmail();
    }

    checkEmail() {
      const email = this.$('[name="email"]').val();

      if (!_.isEmpty(email) && (email === this.state.get('checkEmailValue'))) {
        return this.state.get('checkEmailPromise');
      }

      if (!(email && forms.validateEmail(email))) {
        this.state.set({
          checkEmailState: 'standby',
          checkEmailValue: email,
          checkEmailPromise: null
        });
        return Promise.resolve();
      }

      this.state.set({
        checkEmailState: 'checking',
        checkEmailValue: email,

        checkEmailPromise: (User.checkEmailExists(email)
        .then(({exists}) => {
          if (email !== this.$('[name="email"]').val()) { return; }
          if (exists) {
            return this.state.set('checkEmailState', 'exists');
          } else {
            return this.state.set('checkEmailState', 'available');
          }
      }).catch(e => {
          this.state.set('checkEmailState', 'standby');
          throw e;
        }))
      });
      return this.state.get('checkEmailPromise');
    }
  };
  CreateTeacherAccountView.initClass();
  return CreateTeacherAccountView;
})());


var formSchema = {
  type: 'object',
  required: ['firstName', 'lastName', 'email', 'role', 'numStudents', 'numStudentsTotal', 'city', 'state', 'country'],
  properties: {
    password1: { type: 'string' },
    password2: { type: 'string' },
    firstName: { type: 'string' },
    lastName: { type: 'string' },
    name: { type: 'string', minLength: 1 },
    email: { type: 'string', format: 'email' },
    phoneNumber: { type: 'string', format: 'phoneNumber' },
    role: { type: 'string' },
    organization: { type: 'string' },
    district: { type: 'string' },
    city: { type: 'string' },
    state: { type: 'string' },
    country: { type: 'string' },
    numStudents: { type: 'string' },
    numStudentsTotal: { type: 'string' },
    educationLevel: {
      type: 'array',
      items: { type: 'string' }
    },
    notes: { type: 'string' }
  }
};

for (var key of Array.from(SCHOOL_NCES_KEYS)) {
  formSchema['nces_' + key] = {type: 'string'};
}

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}