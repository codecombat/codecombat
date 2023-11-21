/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let RequestQuoteView;
require('app/styles/teachers/teacher-trial-requests.sass');
const RootView = require('views/core/RootView');
const forms = require('core/forms');
const TrialRequest = require('models/TrialRequest');
const TrialRequests = require('collections/TrialRequests');
const AuthModal = require('views/core/AuthModal');
const errors = require('core/errors');
const ConfirmModal = require('views/core/ConfirmModal');
const User = require('models/User');
const algolia = require('core/services/algolia');
const State = require('models/State');
const {
  parseFullName
} = require('parse-full-name');
const countryList = require('country-list')();
const {
  UsaStates
} = require('usa-states');
const utils = require('core/utils');

const SIGNUP_REDIRECT = '/teachers';
const DISTRICT_NCES_KEYS = ['district', 'district_id', 'district_schools', 'district_students', 'phone'];
const SCHOOL_NCES_KEYS = DISTRICT_NCES_KEYS.concat(['id', 'name', 'students']);

module.exports = (RequestQuoteView = (function() {
  RequestQuoteView = class RequestQuoteView extends RootView {
    static initClass() {
      this.prototype.id = 'request-quote-view';
      this.prototype.template = require('app/templates/teachers/request-quote-view');
      this.prototype.logoutRedirectURL = null;

      this.prototype.events = {
        'change #request-form': 'onChangeRequestForm',
        'submit #request-form': 'onSubmitRequestForm',
        'change input[name="city"]': 'invalidateNCES',
        'change input[name="state"]': 'invalidateNCES',
        'change select[name="state"]': 'invalidateNCES',
        'change input[name="district"]': 'invalidateNCES',
        'change select[name="country"]': 'onChangeCountry',
        'click #email-exists-login-link': 'onClickEmailExistsLoginLink',
        'submit #signup-form': 'onSubmitSignupForm',
        'click #logout-link'() { return me.logout(); },
        'click #google-login-button-ctav': 'onClickGPlusSignupButton',
        'click #facebook-signup-btn': 'onClickFacebookSignupButton',
        'change input[name="email"]': 'onChangeEmail',
        'change input[name="name"]': 'onChangeName',
        'click #submit-request-btn': 'onClickRequestButton'
      };
    }

    getRenderData() {
      return _.merge(super.getRenderData(...arguments), {
        product: utils.getProductName(),
        isOzaria: utils.isOzaria
      });
    }

    getTitle() { return $.i18n.t('new_home.request_quote'); }

    constructor () {
      super(...arguments)
      this.trialRequest = new TrialRequest();
      this.trialRequests = new TrialRequests();
      this.trialRequests.fetchOwn();
      this.supermodel.trackCollection(this.trialRequests);
      this.formChanged = false;
      if (window.tracker) {
        window.tracker.trackEvent('Teachers Request Demo Loaded', {category: 'Teachers'});
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
        return 'Your request has not been submitted! If you continue, your changes will be lost.';
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
        forms.objectToForm(this.$('#request-form'), properties);
      }

      $("#organization-control").algolia_autocomplete({hint: false}, [{
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
        this.$('input[name="district"]').val(suggestion.district);
        this.$('input[name="city"]').val(suggestion.city);
        this.$('input[name="state"]').val(suggestion.state);
        this.$('select[name="state"]').val(suggestion.state);
        this.$('select[name="country"]').val('United States');
        this.state.set({showUsaStateDropdown: true});
        this.state.set({stateValue: suggestion.state});
        for (var key of Array.from(SCHOOL_NCES_KEYS)) {
          this.$('input[name="nces_' + key + '"]').val(suggestion[key]);
        }
        return this.onChangeRequestForm();
      });

      return $("#district-control").algolia_autocomplete({hint: false}, [{
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
        this.$('input[name="organization"]').val(''); // TODO: does not persist on tabbing: back to school, back to district
        this.$('input[name="city"]').val(suggestion.city);
        this.$('input[name="state"]').val(suggestion.state);
        this.$('select[name="state"]').val(suggestion.state);
        this.$('select[name="country"]').val('United States');
        this.state.set({showUsaStateDropdown: true});
        this.state.set({stateValue: suggestion.state});
        for (var key of Array.from(DISTRICT_NCES_KEYS)) {
          this.$('input[name="nces_' + key + '"]').val(suggestion[key]);
        }
        return this.onChangeRequestForm();
      });
    }

    onChangeRequestForm() {
      if (!this.formChanged) {
        if (window.tracker != null) {
          window.tracker.trackEvent('Teachers Request Demo Form Started', {category: 'Teachers'});
        }
      }
      return this.formChanged = true;
    }

    onClickRequestButton(e) {
      const eventAction = $(e.target).data('event-action');
      if (eventAction) {
        return (window.tracker != null ? window.tracker.trackEvent(eventAction, {category: 'Teachers'}) : undefined);
      }
    }

    onSubmitRequestForm(e) {
      e.preventDefault();
      const form = this.$('#request-form');
      const attrs = forms.formToObject(form);
      let trialRequestAttrs = _.cloneDeep(attrs);

      // Don't save n/a district entries, but do validate required district client-side
      if (trialRequestAttrs.district != null ? trialRequestAttrs.district.replace(/\s/ig, '').match(/n\/a/ig) : undefined) { trialRequestAttrs = _.omit(trialRequestAttrs, 'district'); }

      forms.clearFormAlerts(form);
      const requestFormSchema = me.isAnonymous() ? requestFormSchemaAnonymous : requestFormSchemaLoggedIn;
      const result = tv4.validateMultiple(trialRequestAttrs, requestFormSchemaAnonymous);
      let error = false;
      if (!result.valid) {
        forms.applyErrorsToForm(form, result.errors);
        error = true;
      }
      if (!error && !forms.validateEmail(trialRequestAttrs.email)) {
        forms.setErrorToProperty(form, 'email', 'invalid email');
        error = true;
      }

      if (!attrs.district) {
        forms.setErrorToProperty(form, 'district', $.i18n.t('common.required_field'));
        error = true;
      }

      trialRequestAttrs['siteOrigin'] = 'demo request';

      try {
        const parsedName = parseFullName(trialRequestAttrs['fullName'], 'all', -1, true);
        if (parsedName.first && parsedName.last) {
          trialRequestAttrs['firstName'] = parsedName.first;
          trialRequestAttrs['lastName'] = parsedName.last;
        }
      } catch (error1) { e = error1; }
        // TODO handle_error_ozaria

      if (!trialRequestAttrs['firstName'] || !trialRequestAttrs['lastName']) {
        error = true;
        forms.clearFormAlerts($('#full-name'));
        forms.setErrorToProperty(form, 'fullName', $.i18n.t('teachers_quote.full_name_required'));
      }

      if (error) {
        forms.scrollToFirstError();
        return;
      }

      this.trialRequest = new TrialRequest({
        type: 'course',
        properties: trialRequestAttrs
      });
      if ((me.get('role') === 'student') && !me.isAnonymous()) {
        const modal = new ConfirmModal({
          title: '',
          body: `<p>${$.i18n.t('teachers_quote.conversion_warning')}</p><p>${$.i18n.t('teachers_quote.learn_more_modal')}</p>`,
          confirm: $.i18n.t('common.continue'),
          decline: $.i18n.t('common.cancel')
        });
        this.openModalView(modal);
        return modal.once('confirm', (function() {
          modal.hide();
          return this.saveTrialRequest();
        }), this);
      } else {
        return this.saveTrialRequest();
      }
    }

    saveTrialRequest() {
      this.trialRequest.notyErrors = false;
      this.$('#submit-request-btn').text('Sending').attr('disabled', true);
      this.trialRequest.save();
      this.trialRequest.on('sync', this.onTrialRequestSubmit, this);
      return this.trialRequest.on('error', this.onTrialRequestError, this);
    }

    onTrialRequestError(model, jqxhr) {
      this.$('#submit-request-btn').text('Submit').attr('disabled', false);
      if (jqxhr.status === 409) {
        const userExists = $.i18n.t('teachers_quote.email_exists');
        const logIn = $.i18n.t('login.log_in');
        this.$('#email-form-group')
          .addClass('has-error')
          .append($(`<div class='help-block error-help-block'>${userExists} <a id='email-exists-login-link'>${logIn}</a>`));
        return forms.scrollToFirstError();
      } else {
        return errors.showNotyNetworkError(...arguments);
      }
    }

    onClickEmailExistsLoginLink() {
      return this.openModalView(new AuthModal({ initialValues: this.state.get('authModalInitialValues') }));
    }

    onTrialRequestSubmit() {
      if (window.tracker != null) {
        window.tracker.trackEvent('Teachers Request Demo Form Submitted', {category: 'Teachers'});
      }
      this.formChanged = false;
      const trialRequestProperties = this.trialRequest.get('properties');
      me.setRole(trialRequestProperties.role.toLowerCase(), true);
      const defaultName = [trialRequestProperties.firstName, trialRequestProperties.lastName].join(' ');
      this.$('input[name="name"]').val(defaultName);
      this.$('#request-form, #form-submit-success').toggleClass('hide');
      this.scrollToTop(0);
      return $('#flying-focus').css({top: 0, left: 0}); // Hack copied from Router.coffee#187. Ideally we'd swap out the view and have view-swapping logic handle this
    }

    onClickGPlusSignupButton() {
      const btn = this.$('#google-login-button-ctav');
      btn.attr('disabled', true);
      return application.gplusHandler.loadAPI({
        context: this,
        success() {
          btn.attr('disabled', false);
          return application.gplusHandler.connect({
            context: this,
            elementId: 'google-login-button-ctav',
            success(resp) {
              if (resp == null) { resp = {}; }
              btn.find('.sign-in-blurb').text($.i18n.t('signup.creating'));
              btn.attr('disabled', true);
              return application.gplusHandler.loadPerson({
                resp,
                context: this,
                success(gplusAttrs) {
                  me.set(gplusAttrs);
                  return me.save(null, {
                    url: `/db/user?gplusID=${gplusAttrs.gplusID}&gplusAccessToken=${application.gplusHandler.token()}`,
                    type: 'PUT',
                    success() {
                      if (window.tracker != null) {
                        window.tracker.trackEvent('Teachers Request Demo Create Account Google', {category: 'Teachers'});
                      }
                      application.router.navigate(SIGNUP_REDIRECT);
                      return window.location.reload();
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

    onClickFacebookSignupButton() {
      const btn = this.$('#facebook-signup-btn');
      btn.attr('disabled', true);
      return application.facebookHandler.loadAPI({
        context: this,
        success() {
          btn.attr('disabled', false);
          return application.facebookHandler.connect({
            context: this,
            success() {
              btn.find('.sign-in-blurb').text($.i18n.t('signup.creating'));
              btn.attr('disabled', true);
              return application.facebookHandler.loadPerson({
                context: this,
                success(facebookAttrs) {
                  me.set(facebookAttrs);
                  return me.save(null, {
                    url: `/db/user?facebookID=${facebookAttrs.facebookID}&facebookAccessToken=${application.facebookHandler.token()}`,
                    type: 'PUT',
                    success() {
                      if (window.tracker != null) {
                        window.tracker.trackEvent('Teachers Request Demo Create Account Facebook', {category: 'Teachers'});
                      }
                      application.router.navigate(SIGNUP_REDIRECT);
                      return window.location.reload();
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


    onSubmitSignupForm(e) {
      e.preventDefault();
      const form = this.$('#signup-form');
      const attrs = forms.formToObject(form);

      forms.clearFormAlerts(form);
      const result = tv4.validateMultiple(attrs, signupFormSchema);
      let error = false;
      if (!result.valid) {
        forms.applyErrorsToForm(form, result.errors);
        error = true;
      }
      if (attrs.password1 !== attrs.password2) {
        forms.setErrorToProperty(form, 'password1', 'Passwords do not match');
        error = true;
      }
      if (error) { return; }

      me.set({
        password: attrs.password1,
        name: attrs.name,
        email: this.trialRequest.get('properties').email
      });
      if (me.inEU()) {
        const emails = _.assign({}, me.get('emails'));
        if (emails.generalNews == null) { emails.generalNews = {}; }
        emails.generalNews.enabled = false;
        me.set('emails', emails);
        me.set('unsubscribedFromMarketingEmails', true);
      }
      return me.save(null, {
        success() {
          if (window.tracker != null) {
            window.tracker.trackEvent('Teachers Request Demo Create Account', {category: 'Teachers'});
          }
          application.router.navigate(SIGNUP_REDIRECT);
          return window.location.reload();
        },
        error: errors.showNotyNetworkError
      });
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
  RequestQuoteView.initClass();
  return RequestQuoteView;
})());

var requestFormSchemaAnonymous = {
  type: 'object',
  required: [
    'fullName', 'email', 'role', 'numStudents', 'numStudentsTotal', 'city', 'state',
    'country', 'organization', 'phoneNumber'
  ],
  properties: {
    fullName: { type: 'string' },
    email: { type: 'string', format: 'email' },
    phoneNumber: { type: 'string' },
    role: { type: 'string' },
    organization: { type: 'string' },
    district: { type: 'string' },
    city: { type: 'string' },
    state: { type: 'string' },
    country: { type: 'string' },
    numStudents: { type: 'string' },
    numStudentsTotal: { type: 'string' }
  }
};

for (var key of Array.from(SCHOOL_NCES_KEYS)) {
  requestFormSchemaAnonymous['nces_' + key] = {type: 'string'};
}

// same form, but add username input
var requestFormSchemaLoggedIn = _.cloneDeep(requestFormSchemaAnonymous);
requestFormSchemaLoggedIn.required.push('name');

var signupFormSchema = {
  type: 'object',
  required: ['name', 'password1', 'password2'],
  properties: {
    name: { type: 'string' },
    password1: { type: 'string' },
    password2: { type: 'string' }
  }
};

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}