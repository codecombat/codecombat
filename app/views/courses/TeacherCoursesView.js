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
let TeacherCoursesView;
require('app/styles/courses/teacher-courses-view.sass');
const Courses = require('collections/Courses');
const Campaigns = require('collections/Campaigns');
const Prepaids = require('collections/Prepaids');
const RootView = require('views/core/RootView');
const template = require('app/templates/courses/teacher-courses-view');
const HeroSelectModal = require('views/courses/HeroSelectModal');
const Classrooms = require('collections/Classrooms')
const utils = require('core/utils');
const api = require('core/api');

module.exports = (TeacherCoursesView = (function() {
  TeacherCoursesView = class TeacherCoursesView extends RootView {
    static initClass() {
      this.prototype.id = 'teacher-courses-view';
      this.prototype.template = template;

      this.prototype.events = {
        'click .guide-btn': 'onClickGuideButton',
        'click .play-level-button': 'onClickPlayLevel',
        'click .show-change-log': 'onClickShowChange',
        'click .video-thumbnail': 'onClickVideoThumbnail'
      };
    }

    getTitle() { return $.i18n.t('teacher.courses_coco'); }

    constructor (options) {
      super(options)
      application.setHocCampaign(''); // teachers playing levels from here return here
      this.utils = require('core/utils');
      this.enableCpp = me.enableCpp();
      this.enableJava = me.enableJava();
      this.ownedClassrooms = new Classrooms();
      this.ownedClassrooms.fetchMine({data: { project: '_id' }});
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
      this.videoLevels = utils.videoLevels || {};
      if (window.tracker) {
        window.tracker.trackEvent('Classes Guides Loaded', { category: 'Teachers' })
      }
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
      this.fetchResourceHubResources();
      __guard__(me.getClientCreatorPermissions(), x => x.then(() => (typeof this.render === 'function' ? this.render() : undefined)));
      return (typeof this.render === 'function' ? this.render() : undefined);
    }

    fetchResourceHubResources() {
      this.resourcesByCourse = {};
      return api.resourceHubResources.getResourceHubResources().then(allResources => {
        if (this.destroyed) { return; }
        for (var resource of Array.from(allResources)) {
          if ((resource.hidden !== false) && (resource.courses != null ? resource.courses.length : undefined)) {
            for (var course of Array.from(resource.courses)) {
              if (this.resourcesByCourse[course] == null) { this.resourcesByCourse[course] = []; }
              this.resourcesByCourse[course].push(resource);
            }
          }
        }
        for (var courseAcronym in this.resourcesByCourse) {
          var resources = this.resourcesByCourse[courseAcronym];
          this.resourcesByCourse[courseAcronym] = _.sortBy(resources, 'priority');
        }
        return this.render();
      }).catch(e => {
        return console.error(e);
      });
    }

    fetchChangeLog() {
      return;  // 2021-04-25: Haven't been any relevant changes for a while, so disable fetching this; can re-enable and filter to only recent-ish changes if we get back on the course change wagon someday
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
      const form = $(e.currentTarget).closest('.play-level-form');
      const levelSlug = form.find('.level-select').val();
      const courseID = form.data('course-id');
      const language = form.find('.language-select').val() || 'javascript';
      if (window.tracker != null) {
        window.tracker.trackEvent('Classes Guides Play Level', {category: 'Teachers', courseID, language, levelSlug});
      }
      const url = `/play/level/${levelSlug}?course=${courseID}&codeLanguage=${language}`;
      const firstLevelSlug = this.campaigns.get(this.courses.at(0).get('campaignID')).getLevels().at(0).get('slug');
      if (levelSlug === firstLevelSlug) {
        return this.listenToOnce(this.openModalView(new HeroSelectModal()), {
          'hidden'() {
            return application.router.navigate(url, { trigger: true });
          }
        }
        );
      } else {
        return application.router.navigate(url, { trigger: true });
      }
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

    onClickVideoThumbnail(e) {
      let video_url;
      this.$('#video-modal').modal('show');
      const image_src = e.target.src.slice(e.target.src.search('/images'));
      const video = (Object.values(this.videoLevels || {}).find(l => l.thumbnail_unlocked === image_src) || {});
      if (me.showChinaVideo()) {
        video_url = video.cn_url;
      } else {
        video_url = video.url;
        const preferred = me.get('preferredLanguage') || 'en';
        const video_language_code = (video.captions_available || [])
          .find(language_code => (language_code === preferred) || (language_code === preferred.split('-')[0]));
        video_url = video_url.replace(/defaultTextTrack=[\w\d-]+/, 'defaultTextTrack=' + (video_language_code || 'en'));
      }
      this.$('.video-player')[0].src = video_url;

      if (!me.showChinaVideo()) {
        require.ensure(['@vimeo/player'], require => {
          const VideoPlayer = require('@vimeo/player').default;
          this.videoPlayer = new VideoPlayer(this.$('.video-player')[0]);
          return this.videoPlayer.play().catch(err => console.error("Error while playing the video:", err));
        }
        , e => {
          return console.error(e);
        }
        , 'vimeo');
      }
      return this.$('#video-modal').on(('hide.bs.modal'), e=> {
        if (me.showChinaVideo()) {
          return this.$('.video-player').attr('src', '');
        } else {
          return (this.videoPlayer != null ? this.videoPlayer.pause() : undefined);
        }
      });
    }

    destroy() {
      this.$('#video-modal').modal('hide');
      return super.destroy();
    }
  };
  TeacherCoursesView.initClass();
  return TeacherCoursesView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}