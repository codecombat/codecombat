/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ProgressView;
require('app/styles/play/level/modal/progress-view.sass');
const CocoView = require('views/core/CocoView');
const utils = require('core/utils');
const urls = require('core/urls');

module.exports = (ProgressView = (function() {
  ProgressView = class ProgressView extends CocoView {
    static initClass() {
      // TODO: Clean up what was moved to CourseVictoryComponent
  
      this.prototype.id = 'progress-view';
      this.prototype.className = 'modal-content';
      this.prototype.template = require('app/templates/play/level/modal/progress-view');
  
      this.prototype.events = {
        'click #done-btn': 'onClickDoneButton',
        'click #next-level-btn': 'onClickNextLevelButton',
        'click #start-challenge-btn': 'onClickStartChallengeButton',
        'click #map-btn': 'onClickMapButton',
        'click #ladder-btn': 'onClickLadderButton',
        'click #publish-btn': 'onClickPublishButton',
        'click #share-level-btn': 'onClickShareLevelButton'
      };
    }

    initialize(options) {
      this.level = options.level;
      this.course = options.course;
      this.classroom = options.classroom; //not guaranteed to exist (eg. when teacher is playing)
      this.nextLevel = options.nextLevel;
      this.nextAssessment = options.nextAssessment;
      this.levelSessions = options.levelSessions;
      this.session = options.session;
      this.courseInstanceID = options.courseInstanceID;
      // Translate and Markdownify level description, but take out any images (we don't have room for arena banners, etc.).
      // Images in Markdown are like ![description](url)
      this.nextLevel.get('description', true);  // Make sure the defaults are available
      this.nextLevelDescription = marked(utils.i18n(this.nextLevel.attributesWithDefaults, 'description').replace(/!\[.*?\]\(.*?\)\n*/g, ''));
      this.nextAssessment.get('description', true);  // Make sure the defaults are available
      this.nextAssessmentDescription = marked(utils.i18n(this.nextAssessment.attributesWithDefaults, 'description').replace(/!\[.*?\]\(.*?\)\n*/g, ''));
      if (this.level.isProject()) {
        return this.shareURL = urls.playDevLevel({level: this.level, session: this.session, course: this.course});
      }
    }

    onClickDoneButton() {
      return this.trigger('done');
    }

    onClickNextLevelButton() {
      return this.trigger('next-level');
    }

    onClickStartChallengeButton() {
      return this.trigger('start-challenge');
    }

    onClickPublishButton() {
      return this.trigger('publish');
    }

    onClickMapButton() {
      return this.trigger('to-map');
    }

    onClickLadderButton() {
      return this.trigger('ladder');
    }

    onClickShareLevelButton() {
      let category, name;
      if (_.string.startsWith(this.course.get('slug'), 'game-dev')) {
        name = 'Student Game Dev - Copy URL';
        category = 'GameDev';
      } else {
        name = 'Student Web Dev - Copy URL';
        category = 'WebDev';
      }
      const eventProperties = {
        levelID: this.level.id,
        levelSlug: this.level.get('slug'),
        classroomID: this.classroom.id,
        courseID: this.course.id,
        category
      };
      if (window.tracker != null) {
        window.tracker.trackEvent(name, eventProperties);
      }
      this.$('#share-level-input').val(this.shareURL).select();
      return this.tryCopy();
    }
  };
  ProgressView.initClass();
  return ProgressView;
})());
