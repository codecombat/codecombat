// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let PreapidActivationCodesModal;
const _ = require('lodash');
require('app/styles/admin/administer-user-modal.sass');
const ModalView = require('views/core/ModalView');
const template = require('templates/courses/prepaid-activation-codes-modal.pug');
const User = require('models/User');
const Prepaid = require('models/Prepaid');
const StripeCoupons = require('collections/StripeCoupons');
const forms = require('core/forms');
const Prepaids = require('collections/Prepaids');
const Classrooms = require('collections/Classrooms');
const TrialRequests = require('collections/TrialRequests');
const fetchJson = require('core/api/fetch-json');
const utils = require('core/utils');
const api = require('core/api');
const momentTimezone = require('moment-timezone');
const { LICENSE_PRESETS } = require('core/constants');

// TODO: the updateAdministratedTeachers method could be moved to an afterRender lifecycle method.
// TODO: Then we could use @render in the finally method, and remove the repeated use of both of them through the file.

module.exports = (PreapidActivationCodesModal = (function() {
  PreapidActivationCodesModal = class PreapidActivationCodesModal extends ModalView {
    static initClass() {
      this.prototype.id = 'administer-user-modal';
      this.prototype.template = template;

      this.prototype.events = {
        'click .edit-prepaids-info-btn': 'onClickEditPrepaidsInfoButton',
        'click .cancel-prepaid-info-edit-btn': 'onClickCancelPrepaidInfoEditButton',
        'click .save-prepaid-info-btn': 'onClickSavePrepaidInfo',
        'click #license-type-select>.radio': 'onSelectLicenseType',
        'click #add-seats-btn': 'onClickAddSeatsButton'
      };
    }

    constructor (options, classroom) {
      super(...arguments)
      this.classroom = classroom;
      this.user = me;
      this.supermodel.trackRequest(this.user.fetch({cache: false}));
      this.prepaids = new Prepaids();
      this.supermodel.trackRequest(this.prepaids.fetchByCreator(me.get('_id'), { data: {includeShared: true, onlyActivationCodes: true} }));
      this.listenTo(this.prepaids, 'sync', () => {
        return this.prepaids.forEach(prepaid => {
          if (prepaid.loaded && !prepaid.creator) {
            prepaid.creator = new User();
            return this.supermodel.trackRequest(prepaid.creator.fetchCreatorOfPrepaid(prepaid));
          }
        });
      });
      this.timeZone = (typeof features !== 'undefined' && features !== null ? features.chinaInfra : undefined) ? 'Asia/Shanghai' : 'America/Los_Angeles';
      this.licenseType = 'all';
      this.licensePresets = LICENSE_PRESETS;
      this.utils = utils;
      this.momentTimezone = momentTimezone;
    }

    onLoaded() {
      // TODO: Figure out a better way to expose this info, perhaps User methods?
      this.prepaidTableState={};

      return super.onLoaded();
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
      const prepaidEndDate= this.$el.find("#endDate-"+prepaidId).val();
      const prepaidStartDate = this.$el.find("#startDate-"+prepaidId).val();
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

    onSelectLicenseType(e) {
      this.licenseType = $(e.target).parent().children('input').val();
      console.log('select liscense', this.licenseType);
      return this.renderSelectors("#license-type-select");
    }

    onClickAddSeatsButton() {
      const attrs = forms.formToObject(this.$('#prepaid-form'));
      attrs.maxRedeemers = parseInt(attrs.maxRedeemers);
      if (!_.all(_.values(attrs))) { return; }
      if (!(attrs.maxRedeemers > 0)) { return; }
      if (!(attrs.duration > 0)) { return; }
      if (!attrs.endDate || !moment().isBefore(attrs.endDate)) { return; }
      attrs.endDate = attrs.endDate + " " + "23:59";   // Otherwise, it ends at 12 am by default which does not include the date indicated
      attrs.startDate = momentTimezone.tz(this.timeZone ).toISOString();
      attrs.endDate = momentTimezone.tz(attrs.endDate, this.timeZone).toISOString();
      const days = attrs.duration;
      delete attrs.duration;

      if (attrs.licenseType in this.licensePresets) {
        attrs.includedCourseIDs = this.licensePresets[attrs.licenseType];
      }
      if ((attrs.licenseType !== 'all') && !attrs.includedCourseIDs.length) { return; }
      delete attrs.licenseType;

      _.extend(attrs, {
        type: 'course',
        creator: this.user.id,
        generateActivationCodes: true,
        properties: {
          adminAdded: me.id,
          classroom: this.classroom,
          days
        }
      });
      const prepaid = new Prepaid(attrs);
      prepaid.save();
      this.state = 'creating-prepaid';
      this.renderSelectors('#prepaid-form');
      return this.listenTo(prepaid, 'sync', function() {
        let csvContent = 'Code,Expires\n';
        const ocode = prepaid.get('code').toUpperCase();
        for (var code of Array.from(prepaid.get('redeemers'))) {
          csvContent += `${ocode.slice(0, 4)}-${code.code.toUpperCase()}-${ocode.slice(4)},${code.date}\n`;
        }
        const file = new Blob([csvContent], {type: 'text/csv;charset=utf-8'});
        window.saveAs(file, 'ActivationCodes.csv');
        this.state = 'made-prepaid';
        return this.renderSelectors('#prepaid-form');
      });
    }
  };
  PreapidActivationCodesModal.initClass();
  return PreapidActivationCodesModal;
})());

