/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LevelLoadingView;
require('app/styles/play/level/level-loading-view.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/play/level/level-loading-view');

module.exports = (LevelLoadingView = (function() {
  LevelLoadingView = class LevelLoadingView extends CocoView {
    constructor(...args) {
      this.onWindowResize = this.onWindowResize.bind(this);
      super(...args);
    }

    static initClass() {
      this.prototype.id = 'level-loading-view';
      this.prototype.template = template;
  
      this.prototype.subscriptions = {
        'level:loaded': 'onLevelLoaded',  // If Level loads after level loading view.
        'level:session-loaded': 'onSessionLoaded',
        'level:course-membership-required': 'onCourseMembershipRequired',  // If they need to be added to a course.
        'level:license-required': 'onLicenseRequired'
      };
       // If they need a license.
    }

    onLevelLoaded(e) {
      if (this.level) { return; }
      return this.level = e.level;
    }

    onSessionLoaded(e) {
      if (this.session) { return; }
      if (e.session.get('creator') === me.id) { return this.session = e.session; }
    }

    showReady() {
      if (this.shownReady) { return; }
      this.shownReady = true;
      this.unveilPreviewTime = new Date().getTime();
      return _.delay(this.startUnveiling, 100);  // Let any blocking JS hog the main thread before we show that we're done.
    }

    startUnveiling(e) {
      if (this.destroyed) { return; }
      Backbone.Mediator.publish('level:loading-view-unveiling', {});
      const levelSlug = (this.level != null ? this.level.get('slug') : undefined) || __guard__(this.options != null ? this.options.level : undefined, x => x.get('slug'));
      const timespent = (new Date().getTime() - this.unveilPreviewTime) / 1000;
      if (window.tracker != null) {
        window.tracker.trackEvent('Finish Viewing Intro', {
        category: 'Play Level',
        label: 'level loading',
        level: levelSlug,
        levelID: levelSlug,
        timespent // This is no longer a very useful metric as it now happens right away.
      });
      }
      const details = __guard__(this.$('#loading-details'), x1 => x1[0]);
      if (__guard__(details != null ? details.style : undefined, x2 => x2.display) !== 'none') {
        __guard__(details != null ? details.style : undefined, x3 => x3.display = "none");
      }
      return Backbone.Mediator.publish('level:loading-view-unveiled', {view: this});
    }

    resize() {
      const maxHeight = $('#page-container').outerHeight(true);
      let minHeight = $('#code-area').outerHeight(true);
      minHeight -= 20;
      this.$el.css({height: maxHeight});
      return this.$loadingDetails.css({minHeight, maxHeight});
    }

    onWindowResize(e) {
      if (this.destroyed) { return; }
      this.$loadingDetails.css({transition: 'none'});
      return this.resize();
    }

    onCourseMembershipRequired(e) {
      this.$el.find('.progress-or-start-container').hide();
      return this.$el.find('.course-membership-required').show();
    }

    onLicenseRequired(e) {
      this.$el.find('.progress-or-start-container').hide();
      return this.$el.find('.license-required').show();
    }

    onLoadError(resource) {
      const startCase = str => str.charAt(0).toUpperCase() + str.slice(1);
      this.$el.find('.progress-or-start-container').hide();
      if (resource.resource.jqxhr.status === 404) {
        this.$el.find('.resource-not-found>span').text($.i18n.t('loading_error.resource_not_found', {resource: startCase(resource.resource.name)}));
        return this.$el.find('.resource-not-found').show();
      } else {
        return this.$el.find('.could-not-load').show();
      }
    }

    destroy() {
      $(window).off('resize', this.onWindowResize);
      return super.destroy();
    }
  };
  LevelLoadingView.initClass();
  return LevelLoadingView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}