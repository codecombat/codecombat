/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AdministerUserModal;
const _ = require('lodash');
require('app/styles/admin/administer-user-modal.sass');
const ModelModal = require('views/modal/ModelModal');
const template = require('app/templates/admin/administer-user-modal');
const User = require('models/User');
const Prepaid = require('models/Prepaid');
const StripeCoupons = require('collections/StripeCoupons');
const forms = require('core/forms');
const errors = require('core/errors');
const Prepaids = require('collections/Prepaids');
const Classrooms = require('collections/Classrooms');
const TrialRequests = require('collections/TrialRequests');
const fetchJson = require('core/api/fetch-json');
const utils = require('core/utils');
const api = require('core/api');
const NameLoader = require('core/NameLoader');
const momentTimezone = require('moment-timezone');
const { LICENSE_PRESETS, ESPORTS_PRODUCT_STATS } = require('core/constants');

// TODO: the updateAdministratedTeachers method could be moved to an afterRender lifecycle method.
// TODO: Then we could use @render in the finally method, and remove the repeated use of both of them through the file.

module.exports = (AdministerUserModal = (function() {
  AdministerUserModal = class AdministerUserModal extends ModelModal {
    static initClass() {
      this.prototype.id = 'administer-user-modal';
      this.prototype.template = template;

      this.prototype.events = {
        'click #save-changes': 'onClickSaveChanges',
        'click #create-payment-btn': 'onClickCreatePayment',
        'click #add-seats-btn': 'onClickAddSeatsButton',
        'click #add-esports-product-btn': 'onClickAddEsportsProductButton',
        'click #user-spy-btn': 'onClickUserSpyButton',
        'click #destudent-btn': 'onClickDestudentButton',
        'click #deteacher-btn': 'onClickDeteacherButton',
        'click #reset-progress-btn': 'onClickResetProgressButton',
        'click .update-classroom-btn': 'onClickUpdateClassroomButton',
        'click .add-new-courses-btn': 'onClickAddNewCoursesButton',
        'click .user-link': 'onClickUserLink',
        'click #verified-teacher-checkbox': 'onClickVerifiedTeacherCheckbox',
        'click .edit-prepaids-info-btn': 'onClickEditPrepaidsInfoButton',
        'click .cancel-prepaid-info-edit-btn': 'onClickCancelPrepaidInfoEditButton',
        'click .save-prepaid-info-btn': 'onClickSavePrepaidInfo',
        'click .edit-product-info-btn': 'onClickEditProductInfoButton',
        'click .cancel-product-info-edit-btn': 'onClickCancelProductInfoEditButton',
        'click .save-product-info-btn': 'onClickSaveProductInfo',
        'click #school-admin-checkbox': 'onClickSchoolAdminCheckbox',
        'click #online-teacher-checkbox': 'onClickOnlineTeacherCheckbox',
        'click #beta-tester-checkbox': 'onClickBetaTesterCheckbox',
        'click #edit-school-admins-link': 'onClickEditSchoolAdmins',
        'submit #teacher-search-form': 'onSubmitTeacherSearchForm',
        'click .add-administer-teacher': 'onClickAddAdministeredTeacher',
        'click #clear-teacher-search-button': 'onClearTeacherSearchResults',
        'click #teacher-search-button': 'onSubmitTeacherSearchForm',
        'click .remove-teacher-button': 'onClickRemoveAdministeredTeacher',
        'click #license-type-select>.radio': 'onSelectLicenseType',
        'click #esports-type-select>.radio': 'onSelectEsportsType',
        'click #esports-product-addon': 'onSelectEsportsAddon',
        'click .other-user-link': 'onClickOtherUserLink',
        'click .modal-nav-link': 'onClickModalNavLink',
        'click #volume-checkbox': 'onClickVolumeCheckbox',
        'click #music-checkbox': 'onClickMusicCheckbox'
      };
    }

    constructor (options, userHandle) {
      const user = new User({ _id: userHandle })
      if (!options) {
        options = {}
      }
      options.models = [user]
      super(options)
      this.userHandle = userHandle;
      this.ESPORTS_PRODUCT_STATS = ESPORTS_PRODUCT_STATS;
      this.user = user
      this.classrooms = new Classrooms();
      this.supermodel.trackRequest(this.user.fetch({ cache: false }))
      this.listenTo(this.user, 'sync', () => {
        if (this.user.isStudent()) {
          this.supermodel.loadCollection(this.classrooms, { data: {memberID: this.user.id}, cache: false });
          this.listenTo(this.classrooms, 'sync', this.loadClassroomTeacherNames);
        } else if (this.user.isTeacher()) {
          this.supermodel.trackRequest(this.classrooms.fetchByOwner(this.userHandle));
        }
        this.esportsProducts = this.user.getProductsByType('esports');
        return this.renderSelectors('#esports-products');
      });
      this.coupons = new StripeCoupons();
      if (me.isAdmin()) { this.supermodel.trackRequest(this.coupons.fetch({cache: false})); }
      this.prepaids = new Prepaids();
      if (me.isAdmin()) { this.supermodel.trackRequest(this.prepaids.fetchByCreator(this.userHandle, { data: {includeShared: true} })); }
      this.listenTo(this.prepaids, 'sync', () => {
        return this.prepaids.each(prepaid => {
          if (prepaid.loaded && !prepaid.creator) {
            prepaid.creator = new User();
            return this.supermodel.trackRequest(prepaid.creator.fetchCreatorOfPrepaid(prepaid));
          }
        });
      });
      this.esportsProducts = this.user.getProductsByType('esports');
      this.trialRequests = new TrialRequests();
      if (me.isAdmin()) { this.supermodel.trackRequest(this.trialRequests.fetchByApplicant(this.userHandle)); }
      this.timeZone = features?.chinaInfra ? 'Asia/Shanghai' : 'America/Los_Angeles'
      this.licenseType = 'all'
      this.licensePresets = LICENSE_PRESETS;
      this.esportsType = 'basic';
      this.utils = utils;
      options.models = [this.user];  // For ModelModal to generate a Treema of this user
      this.momentTimezone = momentTimezone;
    }

    onLoaded() {
      this.updateStripeStatus();
      this.trialRequest = this.trialRequests.first();
      if (this.trialRequest) { this.models.push(this.trialRequest); }
      this.prepaidTableState={};
      this.productTableState={};
      this.foundTeachers = [];
      this.administratedTeachers = [];
      this.trialRequests = new TrialRequests();
      if (me.isAdmin()) { this.supermodel.trackRequest(this.trialRequests.fetchByApplicant(this.userHandle)); }

      return super.onLoaded();
    }

    afterInsert() {
      if ((window.location.pathname === '/admin') && (window.location.search !== ('?user=' + this.user.id))) {
        window.history.pushState({}, '', '/admin?user=' + this.user.id);
      }
      return super.afterInsert();
    }

    willDisappear() {
      if ((window.location.pathname === '/admin') && (window.location.search === ('?user=' + this.user.id))) {
        window.history.pushState({}, '', '/admin');  // Remove ?user=id query parameter
      }
      return super.willDisappear();
    }

    updateStripeStatus() {
      const stripe = this.user.get('stripe') || {};
      this.free = stripe.free === true;
      this.freeUntil = _.isString(stripe.free);
      this.freeUntilDate = (() => { switch (false) {
        case !this.freeUntil: return stripe.free;
        case !me.isOnlineTeacher(): return moment().add(1, "day").toISOString().slice(0, 10);  // Default to tomorrow
        default: return new Date().toISOString().slice(0, 10)
      }
      })()
      this.currentCouponID = stripe.couponID;
      return this.none = !(this.free || this.freeUntil || this.coupon);
    }

    onClickCreatePayment() {
      const service = this.$('#payment-service').val();
      let amount = parseInt(this.$('#payment-amount').val());
      if (isNaN(amount)) { amount = 0; }
      let gems = parseInt(this.$('#payment-gems').val());
      if (isNaN(gems)) { gems = 0; }
      if (_.isEmpty(service)) {
        alert('Service cannot be empty');
        return;
      } else if (amount < 0) {
        alert('Payment cannot be negative');
        return;
      } else if (gems < 0) {
        alert('Gems cannot be negative');
        return;
      }

      const data = {
        purchaser: this.user.get('_id'),
        recipient: this.user.get('_id'),
        service,
        created: new Date().toISOString(),
        gems,
        amount,
        description: this.$('#payment-description').val()
      };
      return $.post('/db/payment/admin', data, () => this.hide());
    }

    onClickSaveChanges() {
      const stripe = _.clone(this.user.get('stripe') || {});
      delete stripe.free;
      delete stripe.couponID;
      const selection = this.$el.find('input[name="stripe-benefit"]:checked').val();
      const dateVal = this.$el.find('#free-until-date').val();
      const couponVal = this.$el.find('#coupon-select').val();
      switch (selection) {
        case 'free': stripe.free = true; break;
        case 'free-until': stripe.free = dateVal; break;
        case 'coupon': stripe.couponID = couponVal; break;
      }
      this.user.set('stripe', stripe);

      let newGems = parseInt(this.$('#stripe-add-gems').val());
      if (isNaN(newGems)) { newGems = 0; }
      if (newGems > 0) {
        let left;
        const purchased = _.clone((left = this.user.get('purchased')) != null ? left : {});
        if (purchased.gems == null) { purchased.gems = 0; }
        purchased.gems += newGems;
        this.user.set('purchased', purchased);
      }

      const options = {};
      options.success = () => {
        this.updateStripeStatus?.()
        return this.render?.()
      };
      return this.user.patch(options);
    }

    onClickAddSeatsButton() {
      const attrs = forms.formToObject(this.$('#prepaid-form'));
      attrs.maxRedeemers = parseInt(attrs.maxRedeemers);
      if (!_.all(_.values(attrs))) { return; }
      if (!(attrs.maxRedeemers > 0)) { return; }
      if (!attrs.endDate || !attrs.startDate || !(attrs.endDate > attrs.startDate)) { return; }
      attrs.endDate = attrs.endDate + " " + "23:59";   // Otherwise, it ends at 12 am by default which does not include the date indicated
      let {
        timeZone
      } = this
      if (attrs.userTimeZone?.[0] === 'on') {
        timeZone = this.getUserTimeZone()
      }
      attrs.startDate = momentTimezone.tz(attrs.startDate, timeZone).toISOString();
      attrs.endDate = momentTimezone.tz(attrs.endDate, timeZone).toISOString();

      if (attrs.licenseType in this.licensePresets) {
        attrs.includedCourseIDs = this.licensePresets[attrs.licenseType];
      }
      if ((attrs.licenseType !== 'all') && !attrs.includedCourseIDs.length) { return; }
      delete attrs.licenseType;

      _.extend(attrs, {
        type: 'course',
        creator: this.user.id,
        properties: {
          adminAdded: me.id
        }
      });
      const prepaid = new Prepaid(attrs);
      prepaid.save();
      this.state = 'creating-prepaid';
      this.renderSelectors('#prepaid-form');
      return this.listenTo(prepaid, 'sync', function() {
        this.state = 'made-prepaid';
        this.renderSelectors('#prepaid-form');
        this.prepaids.push(prepaid);
        this.renderSelectors('#prepaids-table');
        $('#prepaids-table').addClass('in');
        return setTimeout(() => {
          this.state = '';
          return this.renderSelectors('#prepaid-form');
        }
        , 1000);
      });
    }

    onClickAddEsportsProductButton() {
      const attrs = forms.formToObject(this.$('#esports-product-form'));

      if (!_.all(_.values(attrs))) { return; }
      if (!attrs.endDate || !attrs.startDate || !(attrs.endDate > attrs.startDate)) { return; }
      attrs.endDate = attrs.endDate + " " + "23:59";   // Otherwise, it ends at 12 am by default which does not include the date indicated

      attrs.startDate = momentTimezone.tz(attrs.startDate, this.timeZone ).toISOString();
      attrs.endDate = momentTimezone.tz(attrs.endDate, this.timeZone).toISOString();

      attrs.productOptions = {type: attrs.esportsType, id: _.uniqueId(), createdTournaments: 0};
      delete attrs.esportsType;

      if (attrs.addon.length) {
        attrs.productOptions.teams = parseInt(attrs.teams);
        attrs.productOptions.tournaments = parseInt(attrs.tournaments);
        if (attrs.arenas) { attrs.productOptions.arenas = attrs.arenas; }
      } else {
        const upperType = attrs.productOptions.type.toUpperCase();
        attrs.productOptions.teams = ESPORTS_PRODUCT_STATS.TEAMS[upperType];
        attrs.productOptions.tournaments = ESPORTS_PRODUCT_STATS.TOURNAMENTS[upperType];
      }

      delete attrs.teams;
      delete attrs.tournaments;
      delete attrs.arenas;
      delete attrs.addon;

      _.extend(attrs, {
        product: 'esports',
        purchaser: this.user.id,
        recipient: this.user.id,
        paymentService: 'external',
        paymentDetails: {
          adminAdded: me.id
        }
      });
      this.state = 'creating-esports-product';
      this.renderSelectors('#esports-product-form');
      $('#esports-product-form').addClass('in');
      return api.users.putUserProducts({
        user: this.user.id,
        product: attrs,
        kind: 'new'
      }).then(res => {
        this.state = 'made-esports-product';
        this.renderSelectors('#esports-product-form');
        $('#esports-product-form').addClass('in');
        this.esportsProducts.push(attrs);
        this.renderSelectors('#esports-product-table');
        $('#esports-product-table').addClass('in');
        return setTimeout(() => {
          this.state = '';
          this.renderSelectors('#esports-product-form');
          return $('#esports-product-form').addClass('in');
        }
        , 1000);
      });
    }

    onClickUserSpyButton(e) {
      e.stopPropagation();
      const button = $(e.currentTarget);
      forms.disableSubmit(button);
      return me.spy(this.user.id, {
        success() { return window.location.reload(); },
        error() {
          forms.enableSubmit(button);
          return errors.showNotyNetworkError(...arguments);
        }
      }
      );
    }

    onClickDestudentButton(e) {
      const button = this.$(e.currentTarget);
      button.attr('disabled', true).text('...');
      return Promise.resolve(this.user.destudent())
      .then(() => {
        return button.remove();
    }).catch(e => {
        button.attr('disabled', false).text('Destudent');
          noty({
            text: e.message || e.responseJSON?.message || e.responseText || 'Unknown Error',
            type: 'error'
        });
        if (e.stack) {
          throw e;
        }
      });
    }

    onClickDeteacherButton(e) {
      const button = this.$(e.currentTarget);
      button.attr('disabled', true).text('...');
      return Promise.resolve(this.user.deteacher())
      .then(() => {
        return button.remove();
    }).catch(e => {
        button.attr('disabled', false).text('Destudent');
          noty({
            text: e.message || e.responseJSON?.message || e.responseText || 'Unknown Error',
            type: 'error'
        });
        if (e.stack) {
          throw e;
        }
      });
    }

    onClickResetProgressButton() {
      if (confirm("Really RESET this person's progress?")) {
        return api.users.resetProgress({ userID: this.user.id });
      }
    }

    onClickUpdateClassroomButton(e) {
      const classroom = this.classrooms.get(this.$(e.currentTarget).data('classroom-id'));
      if (confirm(`Really update ${classroom.get('name')}?`)) {
        return Promise.resolve(classroom.updateCourses())
        .then(() => {
          noty({text: 'Updated classroom courses.'});
          return this.renderSelectors('#classroom-table');
      }).catch(() => noty({text: 'Failed to update classroom courses.', type: 'error'}));
      }
    }

    onClickAddNewCoursesButton(e) {
      const classroom = this.classrooms.get(this.$(e.currentTarget).data('classroom-id'));
      if (confirm(`Really update ${classroom.get('name')}?`)) {
        return Promise.resolve(classroom.updateCourses({data: {addNewCoursesOnly: true}}))
        .then(() => {
          noty({text: 'Updated classroom courses.'});
          return this.renderSelectors('#classroom-table');
      }).catch(() => noty({text: 'Failed to update classroom courses.', type: 'error'}));
      }
    }

    onClickUserLink(e) {
      const userID = this.$(e.target).data('user-id');
      if (userID) { return this.openModalView(new AdministerUserModal({}, userID)); }
    }

    userIsVerifiedTeacher() {
      return this.user.get('verifiedTeacher');
    }

    onClickVerifiedTeacherCheckbox(e) {
      const checked = this.$(e.target).prop('checked');
      this.userSaveState = 'saving';
      this.render();
      fetchJson(`/db/user/${this.user.id}/verifiedTeacher`, {
        method: 'PUT',
        json: checked
      }).then(res => {
        this.userSaveState = 'saved';
        this.user.set('verifiedTeacher', res.verifiedTeacher);
        this.render();
        return setTimeout((()=> {
          this.userSaveState = null;
          return this.render();
        }
        ), 2000);
      });
      return null;
    }

    onClickEditPrepaidsInfoButton(e) {
      const prepaidId=this.$(e.target).data('prepaid-id');
      this.prepaidTableState[prepaidId] = 'editMode';
      return this.renderSelectors('#'+prepaidId);
    }

    onClickCancelPrepaidInfoEditButton(e) {
      this.prepaidTableState[this.$(e.target).data('prepaid-id')] = 'viewMode';
      return this.renderSelectors('#'+this.$(e.target).data('prepaid-id'));
    }

    onClickSavePrepaidInfo(e) {
      const prepaidId= this.$(e.target).data('prepaid-id');
      const prepaidStartDate= this.$el.find("#startDate-"+prepaidId).val();
      const prepaidEndDate= this.$el.find("#endDate-"+prepaidId).val();
      const prepaidTotalLicenses=this.$el.find("#totalLicenses-"+prepaidId).val();
      return this.prepaids.each(prepaid => {
        if (prepaid.get('_id') === prepaidId) {
          //validations
          if (!prepaidStartDate || !prepaidEndDate || !prepaidTotalLicenses) {
            return;
          }
          if(prepaidStartDate >= prepaidEndDate) {
            alert('End date cannot be on or before start date');
            return;
          }
          if(prepaidTotalLicenses < (prepaid.get('redeemers') || []).length) {
            alert('Total number of licenses cannot be less than used licenses');
            return;
          }
          prepaid.set('startDate', momentTimezone.tz(prepaidStartDate, this.timeZone).toISOString());
          prepaid.set('endDate',  momentTimezone.tz(prepaidEndDate, this.timeZone).toISOString());
          prepaid.set('maxRedeemers', prepaidTotalLicenses);
          const options = {};
          prepaid.patch(options);
          this.listenTo(prepaid, 'sync', function() {
            this.prepaidTableState[prepaidId] = 'viewMode';
            return this.renderSelectors('#'+prepaidId);
          });
          return;
        }
      });
    }

    onClickEditProductInfoButton(e) {
      const productId=this.$(e.target).data('product-id');
      this.productTableState[productId] = 'editMode';
      return this.renderSelectors('#product-'+productId);
    }

    onClickCancelProductInfoEditButton(e) {
      const productId=this.$(e.target).data('product-id');
      this.productTableState[productId] = 'viewMode';
      return this.renderSelectors('#product-'+productId);
    }

    onClickSaveProductInfo(e) {
      const productId = '' + this.$(e.target).data('product-id'); // make sure it is string
      const productStartDate = this.$el.find('#product-startDate-' + productId).val();
      const productEndDate = this.$el.find('#product-endDate-' + productId).val();
      const tournaments = this.$el.find('#product-tournaments-' + productId).val();
      const teams = this.$el.find('#product-teams-' + productId).val();
      const arenas = this.$el.find('#product-arenas-' + productId).val();

      return this.esportsProducts.forEach((product, i) => {
        if (product.productOptions.id === productId) {
          //validations
          if (!productStartDate || !productEndDate) {
            return;
          }
          if(productStartDate >= productEndDate) {
            alert('End date cannot be on or before start date');
            return;
          }
          product.startDate = momentTimezone.tz(productStartDate, this.timeZone).toISOString();
          product.endDate = momentTimezone.tz(productEndDate, this.timeZone).toISOString();
          product.productOptions.teams = parseInt(teams);
          product.productOptions.tournaments = parseInt(tournaments);
          product.productOptions.arenas = arenas;
          return api.users.putUserProducts({
            user: this.user.id,
            product,
            kind: 'edit'
          }).then(res => {
            this.productTableState[productId] = 'viewMode';
            this.esportsProducts[i] = product;
            return this.renderSelectors('#product-' + productId);
          });
        }
      });
    }

    userIsSchoolAdmin() { return this.user.isSchoolAdmin(); }

    userIsOnlineTeacher() { return this.user.isOnlineTeacher(); }

    userIsBetaTester() { return this.user.isBetaTester(); }

    onClickOnlineTeacherCheckbox(e) {
      const checked = this.$(e.target).prop('checked');
      if (!this.updateUserPermission(User.PERMISSIONS.ONLINE_TEACHER, checked)) {
        return e.preventDefault();
      }
    }

    onClickSchoolAdminCheckbox(e) {
      const checked = this.$(e.target).prop('checked');
      if (!this.updateUserPermission(User.PERMISSIONS.SCHOOL_ADMINISTRATOR, checked)) {
        return e.preventDefault();
      }
    }

    onClickBetaTesterCheckbox(e) {
      const checked = this.$(e.target).prop('checked');
      if (!this.updateUserPermission(User.PERMISSIONS.BETA_TESTER, checked)) {
        return e.preventDefault();
      }
    }

    updateUserPermission(permission, enabled) {
      let cancelled = false;
      if (enabled) {
        if (!window.confirm(`ENABLE ${permission} for ${this.user.get('email') || this.user.broadName()}?`)) {
          cancelled = true;
        }
      } else {
        if (!window.confirm(`DISABLE ${permission} for ${this.user.get('email') || this.user.broadName()}?`)) {
          cancelled = true;
        }
      }
      if (cancelled) {
        this.userSaveState = null;
        this.render();
        return false;
      }

      this.userSaveState = 'saving';
      this.render();
      fetchJson(`/db/user/${this.user.id}/${permission}`, {
        method: 'PUT',
        json: {
          enabled
        }
      }).then(res => {
        this.userSaveState = 'saved';
        return this.user.fetch({cache: false}).then(() => this.render());
      });
      return true;
    }

    onClickEditSchoolAdmins(e) {
      if (typeof this.editingSchoolAdmins === 'undefined') {
        const administrated = this.user.get('administratedTeachers');

        if (administrated?.length) {
          api.users.fetchByIds({
            fetchByIds: administrated,
            teachersOnly: true,
            includeTrialRequests: true
          }).then(teachers => {
            this.administratedTeachers = teachers || [];
            return this.updateAdministratedTeachers();
        }).catch(jqxhr => {
            const errorString = "There was an error getting existing administratedTeachers, see the console";
            this.userSaveState = errorString;
            this.render();
            return console.error(errorString, jqxhr);
          });
        }
      }

      this.editingSchoolAdmins = !this.editingSchoolAdmins;
      return this.render();
    }

    onClickAddAdministeredTeacher(e) {
      const teacher = _.find(this.foundTeachers, t => t._id === $(e.target).closest('tr').data('user-id'));
      this.foundTeachers = _.filter(this.foundTeachers, t => t._id !== teacher._id);
      this.render();

      fetchJson(`/db/user/${this.user.id}/schoolAdministrator/administratedTeacher`, {
        method: 'POST',
        json: {
          administratedTeacherId: teacher._id
        }
      }).then(res => {
        return this.administratedTeachers.push(teacher);
    }).catch(jqxhr => {
        const errorString = "There was an error adding teacher, see the console";
        this.userSaveState = errorString;
        console.error(errorString, jqxhr);
        return this.render();
      }).finally(() => {
        return this.updateAdministratedTeachers();
      });
      return null;
    }

    onClickRemoveAdministeredTeacher(e) {
      const teacher = $(e.target).closest('tr').data('user-id');
      this.render();

      fetchJson(`/db/user/${this.user.id}/schoolAdministrator/administratedTeacher/${teacher}`, {
        method: 'DELETE'
      }).then(res => {
        this.administratedTeachers = this.administratedTeachers.filter(t => t._id !== teacher);
        return this.updateAdministratedTeachers();
      });
      return null;
    }

    onSearchRequestSuccess(teachers) {
      forms.enableSubmit(this.$('#teacher-search-button'));

      // Filter out the existing administrated teachers and themselves:
      const existingTeachers = _.pluck(this.administratedTeachers, '_id');
      existingTeachers.push(this.user.id);
      this.foundTeachers = _.filter(teachers, teacher => !Array.from(existingTeachers).includes(teacher._id));

      let result = _.map(this.foundTeachers, teacher => `\
<tr data-user-id='${teacher._id}'> \
<td> \
<button class='add-administer-teacher'>Add</button> \
</td> \
<td><code>${teacher._id}</code></td> \
<td>${_.escape(teacher.name || 'Anonymous')}</td> \
<td>${_.escape(teacher.email)}</td> \
<td>${teacher.firstName || 'No first name'}</td> \
<td>${teacher.lastName || 'No last name'}</td> \
<td>${teacher.schoolName || 'Other'}</td> \
<td>Verified teacher: ${teacher.verifiedTeacher || 'false'}</td> \
</tr>\
`);

      result = `<table class=\"table\">${result.join('\n')}</table>`;
      return this.$el.find('#teacher-search-result').html(result);
    }

    onSearchRequestFailure(jqxhr, status, error) {
      if (this.destroyed) { return; }
      forms.enableSubmit(this.$('#teacher-search-button'));
      return console.warn(`There was an error looking up ${this.lastTeacherSearchValue}:`, error);
    }

    onClearTeacherSearchResults(e) {
      return this.$el.find('#teacher-search-result').html('');
    }

    onSubmitTeacherSearchForm(e) {
      this.userSaveState = null;
      e.preventDefault();
      forms.disableSubmit(this.$('#teacher-search-button'));

      return $.ajax({
        type: 'GET',
        url: '/db/user',
        data: {
          adminSearch: this.$el.find('#teacher-search').val()
        },
        success: this.onSearchRequestSuccess,
        error: this.onSearchRequestFailure
      });
    }

    updateAdministratedTeachers() {
      const schools = this.administratedSchools(this.administratedTeachers);
      const schoolNames = Object.keys(schools);

      let result = _.map(schoolNames, function(schoolName) {
        const teachers = _.map(schools[schoolName], teacher => `\
<tr data-user-id='${teacher._id}'> \
<td>${teacher.firstName} ${teacher.lastName}</td> \
<td>${teacher.role}</td> \
<td>${teacher.email}</td> \
<td><button class='btn btn-primary btn-large remove-teacher-button'>Remove</button></td> \
</tr>\
`);

        return `\
<tr> \
<th>${schoolName}</th> \
${teachers.join('\n')} \
</tr>\
`;
      });

      result = `<table class=\"table\">${result.join('\n')}</table>`;
      return this.$el.find('#school-admin-result').html(result);
    }

    onSelectLicenseType(e) {
      this.licenseType = $(e.target).parent().children('input').val();
      return this.renderSelectors("#license-type-select");
    }

    onSelectEsportsType(e) {
      this.esportsType = $(e.target).parent().children('input').val();
      this.renderSelectors("#esports-type-select");
      return this.renderSelectors("#esports-product-addon-items");
    }

    onSelectEsportsAddon(e) {
      this.esportsAddon = $(e.target).parent().children('input').is(':checked');
      return this.renderSelectors('#esports-product-addon-items');
    }

    administratedSchools(teachers) {
      const schools = {};
      _.forEach(teachers, teacher => {
        const school = teacher?._trialRequest?.organization || 'Other'
        if (!schools[school]) {
          return schools[school] = [teacher];
        } else {
          return schools[school].push(teacher);
        }
      });

      return schools;
    }

    loadClassroomTeacherNames() {
      let left;
      const ownerIDs = (left = _.map(this.classrooms.models, c => c.get('ownerID'))) != null ? left : [];
      return Promise.resolve($.ajax(NameLoader.loadNames(ownerIDs)))
      .then(() => {
          this.ownerNameMap = {}
          for (const ownerID of Array.from(ownerIDs)) { this.ownerNameMap[ownerID] = NameLoader.getName(ownerID) }
          return this.render?.()
        })
    }

    onClickOtherUserLink(e) {
      e.preventDefault();
      const userID = $(e.target).closest('a').data('user-id');
      return this.openModalView(new AdministerUserModal({}, userID));
    }

    onClickModalNavLink(e) {
      e.preventDefault();
      return this.$el.animate({scrollTop: $($(e.target).attr('href')).offset().top}, 0);
    }

    onClickMusicCheckbox(e) {
      const val = this.$(e.target).prop('checked');
      this.user.set('music', val);
      this.user.patch();
      return this.modelTreemas[this.user.id].set('music', val);
    }

    onClickVolumeCheckbox(e) {
      let checked;
      const val = (checked = this.$(e.target).prop('checked')) ? 1.0 : 0.0;
      this.user.set('volume', val);
      this.user.patch();
      return this.modelTreemas[this.user.id].set('volume', val);
    }

    getUserTimeZone() {
      const geo = this.user.get('geo')
      if (geo?.timeZone) {
        return geo.timeZone
      } else {
        return this.timeZone;
      }
    }
  };
  AdministerUserModal.initClass();
  return AdministerUserModal;
})());
