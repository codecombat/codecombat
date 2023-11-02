// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Prepaid;
const CocoModel = require('./CocoModel');
const schema = require('schemas/models/prepaid.schema');
const utils = require('../core/utils');

const { STARTER_LICENSE_COURSE_IDS } = require('core/constants');

module.exports = (Prepaid = (function() {
  Prepaid = class Prepaid extends CocoModel {
    static initClass() {
      this.className = "Prepaid";
      this.prototype.urlRoot = '/db/prepaid';
    }

    openSpots() {
      if (this.get('redeemers') != null) { return this.get('maxRedeemers') - __guard__(this.get('redeemers'), x => x.length); }
      return this.get('maxRedeemers');
    }

    usedSpots() {
      return _.size(this.get('redeemers'));
    }

    totalSpots() {
      return this.get('maxRedeemers');
    }

    userHasRedeemed(userID) {
      for (var redeemer of Array.from(this.get('redeemers'))) {
        if (redeemer.userID === userID) { return redeemer.date; }
      }
      return null;
    }

    initialize() {
      this.listenTo(this, 'add', function() {
        const maxRedeemers = this.get('maxRedeemers');
        if (_.isString(maxRedeemers)) {
          return this.set('maxRedeemers', parseInt(maxRedeemers));
        }
      });
      return super.initialize(...arguments);
    }

    status() {
      const endDate = this.get('endDate');
      if (endDate && (new Date(endDate) < new Date())) {
        return 'expired';
      }

      const startDate = this.get('startDate');
      if (startDate && (new Date(startDate) > new Date())) {
        return 'pending';
      }

      if (this.openSpots() <= 0) {
        return 'empty';
      }

      return 'available';
    }

    typeDescription() {
      const type = this.get('type');
      if (type === 'starter_license') {
        return i18n.t('teacher.starter_license');
      }
      const includedCourseIDs = this.get('includedCourseIDs');
      if (includedCourseIDs) {
        return i18n.t('teacher.customized_license')+ ': '+ (includedCourseIDs.map(id => utils.courseAcronyms[id])).join('+');
      } else {
        return i18n.t('teacher.full_license');
      }
    }

    typeDescriptionWithTime() {
      const type = this.get('type');
      const endDate = moment(this.get('endDate')).utc().format('ll');
      let endAt = `<br>${i18n.t('teacher.status_enrolled')}`;
      endAt = endAt.replace('{{date}}', endDate);
      if (type === 'starter_license') {
        return i18n.t('teacher.starter_license') + endAt;
      }
      const includedCourseIDs = this.get('includedCourseIDs');
      if (includedCourseIDs) {
        return i18n.t('teacher.customized_license') + ': ' + (includedCourseIDs.map(id => utils.courseAcronyms[id])).join('+') + endAt;
      } else {
        return i18n.t('teacher.full_license') + endAt;
      }
    }


    redeem(user, options) {
      if (options == null) { options = {}; }
      options.url = _.result(this, 'url')+'/redeemers';
      options.type = 'POST';
      if (options.data == null) { options.data = {}; }
      options.data.userID = user.id || user;
      return this.fetch(options);
    }

    includesCourse(course) {
      const courseID = (typeof course.get === 'function' ? course.get('name') : undefined) || course;
      if (this.get('type') === 'starter_license') {
        let left, needle;
        return (needle = courseID, Array.from(((left = this.get('includedCourseIDs')) != null ? left : [])).includes(needle));
      } else {
        // no includedCourseIDs means full-license, so always return true
        let left1, needle1;
        return (needle1 = courseID, Array.from(((left1 = this.get('includedCourseIDs')) != null ? left1 : [ courseID ])).includes(needle1));
      }
    }

    numericalCourses() {
      if (!__guard__(this.get('includedCourseIDs'), x => x.length)) { return utils.courseNumericalStatus['FULL_ACCESS']; }
      const fun = (s, k) => {
        return s + utils.courseNumericalStatus[k];
      };
      return _.reduce(this.get('includedCourseIDs'), fun, 0);
    }

    revoke(user, options) {
      if (options == null) { options = {}; }
      options.url = _.result(this, 'url')+'/redeemers';
      options.type = 'DELETE';
      if (options.data == null) { options.data = {}; }
      options.data.userID = user.id || user;
      return this.fetch(options);
    }

    convertToProduct() {
      return {
        product: 'course',
        startDate: this.get('startDate'),
        endDate: this.get('endDate'),
        prepaid: this.get('_id'),
        productOptions: {
          includedCourseIDs: this.get('includedCourseIDs')
        }
      };
    }

    hasBeenUsedByTeacher(userID) {
      if ((this.get('creator') === userID) && _.detect(this.get('redeemers'), { teacherID: undefined })) {
        return true;
      }
      return _.detect(this.get('redeemers'), { teacherID: userID });
    }
  };
  Prepaid.initClass();
  return Prepaid;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}