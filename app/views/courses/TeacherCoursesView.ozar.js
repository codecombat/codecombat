// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let TeacherCoursesView;
require('app/styles/courses/teacher-courses-view.sass');
const CocoCollection = require('collections/CocoCollection');
const CocoModel = require('models/CocoModel');
const Courses = require('collections/Courses');
const Campaigns = require('collections/Campaigns');
const Campaign = require('models/Campaign');
const Classroom = require('models/Classroom');
const Classrooms = require('collections/Classrooms');
const User = require('models/User');
const CourseInstance = require('models/CourseInstance');
const Prepaids = require('collections/Prepaids');
const RootView = require('views/core/RootView');
const template = require('app/templates/courses/teacher-courses-view');
const HeroSelectModal = require('views/courses/HeroSelectModal');
const utils = require('core/utils');
const api = require('core/api');
const ozariaUtils = require('ozaria/site/common/ozariaUtils');

module.exports = (TeacherCoursesView = (function() {
  TeacherCoursesView = class TeacherCoursesView extends RootView {
    static initClass() {
      this.prototype.id = 'teacher-courses-view';
      this.prototype.template = template;
  
      this.prototype.events = {
        'click .guide-btn': 'onClickGuideButton',
        'click .play-level-button': 'onClickPlayLevel',
        'click .show-change-log': 'onClickShowChange'
      };
    }

    getMeta() { return { title: `${$.i18n.t('teacher.courses_ozar')} | ${$.i18n.t('common.ozaria')}` }; }

    initialize(options) {
      super.initialize(options);
      application.setHocCampaign(''); // teachers playing levels from here return here
      this.utils = require('core/utils');
      this.enableCpp = me.enableCpp();
      this.enableJava = me.enableJava();
      this.ownedClassrooms = new Classrooms();
      this.ownedClassrooms.fetchMine({data: {project: '_id'}});
      this.supermodel.trackCollection(this.ownedClassrooms);
      this.courses = new Courses();
      this.prepaids = new Prepaids();
      this.paidTeacher = me.isAdmin() || me.isPaidTeacher();
      if (me.isAdmin()) {
        this.supermodel.trackRequest(this.courses.fetch());
      } else {
        this.supermodel.trackRequest(this.courses.fetchReleased());
        this.supermodel.trackRequest(this.prepaids.fetchMineAndShared());
      }
      this.campaigns = new Campaigns([], { forceCourseNumbering: true });
      this.supermodel.trackRequest(this.campaigns.fetchByType('course', { data: { project: 'levels,levelsUpdated' } }));
      this.campaignLevelNumberMap = {};
      this.courseChangeLog = {};
      this.campaignLevelsModuleMap = {};
      this.moduleNameMap = utils.courseModules;
      this.listenTo(this.campaigns, 'sync', function() {
        this.campaigns.models.map(campaign => Object.assign(this.campaignLevelsModuleMap, campaign.getLevelsByModules()));
        // since intro content data is only needed for display names in the dropdown
        // do not add it to supermodel.trackRequest which would increase the load time of the page
        return Campaign.fetchIntroContentDataForLevels(this.campaignLevelsModuleMap).then(() => (typeof this.render === 'function' ? this.render() : undefined));
      });
      if (window.tracker != null) {
        window.tracker.trackEvent('Classes Guides Loaded', {category: 'Teachers'});
      }
      this.getLevelDisplayNameWithLabel = level => ozariaUtils.getLevelDisplayNameWithLabel(level);
      return this.getIntroContentNameWithLabel = content => ozariaUtils.getIntroContentNameWithLabel(content);
    }

    onLoaded() {
      let needle;
      this.campaigns.models.forEach(campaign => {
        const levels = campaign.getLevels().models.map(level => {
          let left, left1;
          return {key: level.get('original'), practice: (left = level.get('practice')) != null ? left : false, assessment: (left1 = level.get('assessment')) != null ? left1 : false};
        });
        return this.campaignLevelNumberMap[campaign.id] = utils.createLevelNumberMap(levels);
      });
      this.paidTeacher = this.paidTeacher || (this.prepaids.find(p => (needle = p.get('type'), ['course', 'starter_license'].includes(needle)) && (p.get('maxRedeemers') > 0)) != null);
      this.fetchChangeLog();
      __guard__(me.getClientCreatorPermissions(), x => x.then(() => (typeof this.render === 'function' ? this.render() : undefined)));
      return (typeof this.render === 'function' ? this.render() : undefined);
    }

    fetchChangeLog() {
      return api.courses.fetchChangeLog().then(changeLogInfo => {
        this.courses.models.forEach(course => {
          let changeLog = _.filter(changeLogInfo, { 'id' : course.get('_id') });
          changeLog = _.sortBy(changeLog, 'date');
          return this.courseChangeLog[course.id] = _.mapValues(_.groupBy(changeLog, 'date'));
        });
        return (typeof this.render === 'function' ? this.render() : undefined);
      })
      .catch(e => {
        return console.error(e);
      });
    }

    onClickGuideButton(e) {
      const courseID = $(e.currentTarget).data('course-id');
      const courseName = $(e.currentTarget).data('course-name');
      const eventAction = $(e.currentTarget).data('event-action');
      return window.tracker != null ? window.tracker.trackEvent(eventAction, {category: 'Teachers', courseID, courseName}) : undefined;
    }

    onClickPlayLevel(e) {
      let url;
      const form = $(e.currentTarget).closest('.play-level-form');
      const levelSlug = form.find('.selectpicker').val();
      const introIndex = (form.find('.intro-content:selected').data() || {}).index;
      const courseID = form.data('course-id');
      const language = form.find('.language-select').val() || 'javascript';
      if (window.tracker != null) {
        window.tracker.trackEvent('Classes Guides Play Level', {category: 'Teachers', courseID, language, levelSlug});
      }

      // Because we don't know what classroom to match this with, this may have outdated campaign levels caching:
      const campaignLevels = this.campaigns.get(this.courses.get(courseID).get('campaignID')).getLevels() || [];
      if (__guard__(campaignLevels.find(l => l.get('slug') === levelSlug), x => x.get('type')) === 'intro') {
        url = `/play/intro/${levelSlug}?course=${courseID}&codeLanguage=${language}&intro-content=${introIndex}`;
      } else {
        url = `/play/level/${levelSlug}?course=${courseID}&codeLanguage=${language}`;
      }
      return application.router.navigate(url, { trigger: true });
    }

    onClickShowChange(e) {
      const showChangeLog = $(e.currentTarget);
      const changeLogDiv = showChangeLog.closest('.course-change-log');
      const changeLogText = changeLogDiv.find('.change-log');
      if (changeLogText.hasClass('hidden')) {
        changeLogText.removeClass('hidden');
        return showChangeLog.text($.i18n.t('courses.hide_change_log'));
      } else {
        changeLogText.addClass('hidden');
        return showChangeLog.text($.i18n.t('courses.show_change_log'));
      }
    }
  };
  TeacherCoursesView.initClass();
  return TeacherCoursesView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}