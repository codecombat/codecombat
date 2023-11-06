/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ConvertToTeacherAccountView;
require('app/styles/teachers/teacher-trial-requests.sass');
const RootView = require('views/core/RootView');
const forms = require('core/forms');
const TrialRequest = require('models/TrialRequest');
const TrialRequests = require('collections/TrialRequests');
const AuthModal = require('views/core/AuthModal');
const errors = require('core/errors');
const User = require('models/User');
const ConfirmModal = require('views/core/ConfirmModal');
const algolia = require('core/services/algolia');
const countryList = require('country-list')();
const {
  UsaStates
} = require('usa-states');
const State = require('models/State');
const utils = require('core/utils');

const DISTRICT_NCES_KEYS = ['district', 'district_id', 'district_schools', 'district_students', 'phone'];
const SCHOOL_NCES_KEYS = DISTRICT_NCES_KEYS.concat(['id', 'name', 'students']);

module.exports = (ConvertToTeacherAccountView = (function() {
  ConvertToTeacherAccountView = class ConvertToTeacherAccountView extends RootView {
    static initClass() {
      this.prototype.id = 'convert-to-teacher-account-view';
      this.prototype.template = require('app/templates/teachers/convert-to-teacher-account-view');
      this.prototype.logoutRedirectURL = null;

      this.prototype.events = {
        'change form': 'onChangeForm',
        'submit form': 'onSubmitForm',
        'click #logout-link'() { return me.logout(); },
        'change input[name="city"]': 'invalidateNCES',
        'change input[name="state"]': 'invalidateNCES',
        'change select[name="state"]': 'invalidateNCES',
        'change input[name="district"]': 'invalidateNCES',
        'change select[name="country"]': 'onChangeCountry'
      };
    }

    getRenderData() {
      return _.merge(super.getRenderData(...arguments), { product: utils.getProductName() });
    }

    constructor () {
      super()
      if (me.isAnonymous()) {
        application.router.navigate('/teachers/signup', {trigger: true, replace: true});
        return;
      }
      this.trialRequest = new TrialRequest();
      this.trialRequests = new TrialRequests();
      this.trialRequests.fetchOwn();
      this.supermodel.trackCollection(this.trialRequests);
      this.countries = countryList.getNames();
      this.usaStates = new UsaStates().states;
      this.usaStatesAbbreviations = new UsaStates().arrayOf('abbreviations');
      if (window.tracker) {
        window.tracker.trackEvent('Teachers Convert Account Loaded', {category: 'Teachers'});
      }
      this.state = new State({
        showUsaStateDropdown: true,
        stateValue: null
      });
      this.listenTo(this.state, 'change:showUsaStateDropdown', function() { return this.renderSelectors('.state'); });
      this.listenTo(this.state, 'change:stateValue', function() { return this.renderSelectors('.state'); });
    }

    onLeaveMessage() {
      if (this.formChanged) {
        return 'Your account has not been updated! If you continue, your changes will be lost.';
      }
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

    onLoaded() {
      if (this.trialRequests.size() && me.isTeacher()) {
        return application.router.navigate('/teachers', { trigger: true, replace: true });
      }

      return super.onLoaded();
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
        return this.onChangeForm();
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
        return this.onChangeForm();
      });
    }

    onChangeForm() {
      if (!this.formChanged) {
        if (window.tracker != null) {
          window.tracker.trackEvent('Teachers Convert Account Form Started', {category: 'Teachers'});
        }
      }
      return this.formChanged = true;
    }

    onSubmitForm(e) {
      e.preventDefault();

      const form = this.$('form');
      const attrs = forms.formToObject(form);
      let trialRequestAttrs = _.cloneDeep(attrs);

      // Don't save n/a district entries, but do validate required district client-side
      if (trialRequestAttrs.district != null ? trialRequestAttrs.district.replace(/\s/ig, '').match(/^n\/?a$/ig) : undefined) { trialRequestAttrs = _.omit(trialRequestAttrs, 'district'); }

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
      if (!_.size(trialRequestAttrs.educationLevel)) {
        forms.setErrorToProperty(form, 'educationLevel', 'include at least one');
        error = true;
      }
      if (!attrs.district) {
        forms.setErrorToProperty(form, 'district', $.i18n.t('common.required_field'));
        error = true;
      }
      if (error) {
        forms.scrollToFirstError();
        return;
      }
      trialRequestAttrs['siteOrigin'] = 'convert teacher';
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
        return modal.once('confirm', this.saveTrialRequest, this);
      } else {
        return this.saveTrialRequest();
      }
    }

    saveTrialRequest() {
      this.trialRequest.notyErrors = false;
      this.$('#create-account-btn').text('Sending').attr('disabled', true);
      this.trialRequest.save();
      this.trialRequest.on('sync', this.onTrialRequestSubmit, this);
      return this.trialRequest.on('error', this.onTrialRequestError, this);
    }

    onTrialRequestError(model, jqxhr) {
      this.$('#submit-request-btn').text('Submit').attr('disabled', false);
      return errors.showNotyNetworkError(...arguments);
    }

    onTrialRequestSubmit() {
      if (window.tracker != null) {
        window.tracker.trackEvent('Teachers Convert Account Submitted', {category: 'Teachers'});
      }
      this.formChanged = false;
      me.setRole(this.trialRequest.get('properties').role.toLowerCase(), true);
      me.unsubscribe();
      return application.router.navigate('/teachers/classes', {trigger: true});
    }
  };
  ConvertToTeacherAccountView.initClass();
  return ConvertToTeacherAccountView;
})());

var formSchema = {
  type: 'object',
  required: ['firstName', 'lastName', 'role', 'numStudents', 'city', 'state', 'country'],
  properties: {
    firstName: { type: 'string' },
    lastName: { type: 'string' },
    phoneNumber: { type: 'string' },
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
