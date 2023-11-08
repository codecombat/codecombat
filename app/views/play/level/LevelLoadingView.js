/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LevelLoadingView;
require('app/styles/play/level/level-loading-view.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/play/level/level-loading-view');
const ace = require('lib/aceContainer');
const utils = require('core/utils');
const aceUtils = require('core/aceUtils');
const aetherUtils = require('lib/aether_utils');
const SubscribeModal = require('views/core/SubscribeModal');
const LevelGoals = require('./LevelGoals').default;
const store = require('core/store');

module.exports = (LevelLoadingView = (function() {
  LevelLoadingView = class LevelLoadingView extends CocoView {
    static initClass() {
      this.prototype.id = 'level-loading-view';
      this.prototype.template = template;

      this.prototype.events = {
        'mousedown .start-level-button': 'startUnveiling',  // Split into two for animation smoothness.
        'click .start-level-button': 'onClickStartLevel',
        'click .start-subscription-button': 'onClickStartSubscription'
      };

      this.prototype.subscriptions = {
        'level:loaded': 'onLevelLoaded',  // If Level loads after level loading view.
        'level:session-loaded': 'onSessionLoaded',
        'level:subscription-required': 'onSubscriptionRequired',  // If they'd need a subscription.
        'level:course-membership-required': 'onCourseMembershipRequired',  // If they need to be added to a course.
        'level:license-required': 'onLicenseRequired', // If they need a license.
        'subscribe-modal:subscribed': 'onSubscribed'
      };

      this.prototype.shortcuts =
        {'enter': 'onEnterPressed'};
    }

    constructor (options) {
      if (!options) { options = {} }
      super(options)
      this.utils = utils;
      this.loadingWingClass = _.sample(['alejandro', 'anya', 'chess', 'naria', 'okar']);
      this.finishShowingReady = this.finishShowingReady.bind(this);
      this.onClickStartLevel = this.onClickStartLevel.bind(this);
      this.unveilIntro = this.unveilIntro.bind(this);
      this.onUnveilEnded = this.onUnveilEnded.bind(this);
      this.onWindowResize = this.onWindowResize.bind(this);
    }

    afterRender() {
      super.afterRender();
      if (utils.isOzaria) { return; }
      if (!(this.level != null ? this.level.get('loadingTip') : undefined)) {
        if (_.random(1, 10) < 9) { this.$el.find('.tip.rare').remove(); }
        const tips = this.$el.find('.tip').addClass('to-remove');
        const tip = _.sample(tips);
        $(tip).removeClass('to-remove').addClass('secret');
        this.$el.find('.to-remove').remove();
      }
      if (this.options.level != null ? this.options.level.get('goals') : undefined) { this.onLevelLoaded({level: this.options.level}); }  // If Level was already loaded.
      return this.configureACEEditors();
    }

    configureACEEditors() {
      const codeLanguage = (this.session != null ? this.session.get('codeLanguage') : undefined) || __guard__(me.get('aceConfig'), x => x.language) || 'python';
      for (var oldEditor of Array.from(this.aceEditors != null ? this.aceEditors : [])) { oldEditor.destroy(); }
      this.aceEditors = [];
      const {
        aceEditors
      } = this;
      return this.$el.find('pre:has(code[class*="lang-"])').each(function() {
        const aceEditor = aceUtils.initializeACE(this, codeLanguage);
        return aceEditors.push(aceEditor);
      });
    }

    afterInsert() {
      return super.afterInsert();
    }

    onLevelLoaded(e) {
      if (this.level) { return; }
      this.level = e.level;
      if (utils.isCodeCombat) {
        this.prepareGoals(e);
        this.prepareTip();
        return this.prepareIntro();
      }
    }

    onSessionLoaded(e) {
      if (this.session) { return; }
      if (e.session.get('creator') === me.id) { return this.session = e.session; }
    }

    prepareGoals() {
      this.levelGoalsComponent = new LevelGoals({
        el: this.$('.list-unstyled')[0],
        store,
        propsData: { showStatus: false }
      });
      this.levelGoalsComponent.goals = this.level.get('goals');
      const goalContainer = this.$el.find('.level-loading-goals');
      this.buttonTranslationKey = 'play_level.loading_start';
      if (this.level.get('assessment') === 'cumulative') {
        this.buttonTranslationKey = 'play_level.loading_start_combo';
      } else if (this.level.get('assessment')) {
        this.buttonTranslationKey = 'play_level.loading_start_concept';
      }
      this.$('.start-level-button').text($.i18n.t(this.buttonTranslationKey));

      return Vue.nextTick(() => {
        // TODO: move goals to vuex where everyone can check together which goals are visible.
        // Use that instead of looking into the Vue result
        const numGoals = goalContainer.find('li').length;
        if (numGoals) {
          goalContainer.removeClass('secret');
          if (this.level.get('assessment') === 'cumulative') {
            if (numGoals > 1) {
              this.goalHeaderTranslationKey = 'play_level.combo_challenge_goals';
            } else {
              this.goalHeaderTranslationKey = 'play_level.combo_challenge_goal';
            }
          } else if (this.level.get('assessment')) {
            if (numGoals > 1) {
              this.goalHeaderTranslationKey = 'play_level.concept_challenge_goals';
            } else {
              this.goalHeaderTranslationKey = 'play_level.concept_challenge_goal';
            }
          } else {
            if (numGoals > 1) {
              this.goalHeaderTranslationKey = 'play_level.goals';
            } else {
              this.goalHeaderTranslationKey = 'play_level.goal';
            }
          }
          return goalContainer.find('.goals-title').text($.i18n.t(this.goalHeaderTranslationKey));
        }
      });
    }

    prepareTip() {
      const tip = this.$el.find('.tip');
      if (this.level.get('loadingTip')) {
        let loadingTip = utils.i18n(this.level.attributes, 'loadingTip');
        loadingTip = marked(loadingTip);
        tip.html(loadingTip).removeAttr('data-i18n');
      }
      return tip.removeClass('secret');
    }

    prepareIntro() {
      let left;
      this.docs = (left = this.level.get('documentation')) != null ? left : {};
      const specific = this.docs.specificArticles || [];
      this.intro = _.find(specific, {name: 'Intro'});
      if (window.serverConfig.picoCTF) {
        return this.intro != null ? this.intro : (this.intro = {body: ''});
      }
    }

    showReady() {
      if (this.shownReady) { return; }
      this.shownReady = true;
      if (utils.isCodeCombat) {
        _.delay(this.finishShowingReady, 100) // Let any blocking JS hog the main thread before we show that we're done.
      } else {
        this.unveilPreviewTime = new Date().getTime();
        _.delay(() => this.startUnveiling(), 100) // Let any blocking JS hog the main thread before we show that we're done.
      }
    }

    finishShowingReady() {
      let autoUnveil;
      if (this.destroyed) { return; }
      const showIntro = utils.getQueryVariable('intro');
      if (showIntro != null) {
        autoUnveil = !showIntro;
      } else {
        autoUnveil = this.options.autoUnveil || (this.session != null ? this.session.get('state').complete : undefined);
      }
      if (autoUnveil) {
        this.startUnveiling();
        return this.unveil(true);
      } else {
        this.playSound('level_loaded', 0.75);  // old: loading_ready
        this.$el.find('.progress').hide();
        this.$el.find('.start-level-button').show();
        return this.unveil(false);
      }
    }

    startUnveiling(e) {
      // todo: this file, coco and ozar do similar things with different steps, should be refactored
      if (utils.isCodeCombat) {
        this.playSound('menu-button-click');
        this.unveiling = true;
        Backbone.Mediator.publish('level:loading-view-unveiling', {});
        return _.delay(this.onClickStartLevel, 1000);  // If they never mouse-up for the click (or a modal shows up and interrupts the click), do it anyway.
      } else {
        console.log('level', this.level, 'unveiling')
        const levelSlug = (this.level ? this.level.get('slug') : undefined) || __guard__(this.options != null ? this.options.level : undefined, x => x.get('slug'));
        const timespent = (new Date().getTime() - this.unveilPreviewTime) / 1000;
        if (window.tracker) {
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
    }

    onClickStartLevel(e) {
      if (this.destroyed) { return; }
      return this.unveil(true);
    }

    onEnterPressed(e) {
      if (!this.shownReady || !!this.unveiled) { return; }
      this.startUnveiling();
      return this.onClickStartLevel();
    }

    unveil(full) {
      if (this.destroyed || this.unveiled) { return; }
      this.unveiled = full;
      this.$loadingDetails = this.$el.find('#loading-details');
      const duration = parseFloat(this.$loadingDetails.css('transition-duration')) * 1000;
      if (!this.$el.hasClass('unveiled')) {
        this.$el.addClass('unveiled');
        this.unveilWings(duration);
      }
      if (full) {
        this.unveilLoadingFull();
        return _.delay(this.onUnveilEnded, duration);
      } else {
        return this.unveilLoadingPreview(duration);
      }
    }

    unveilLoadingFull() {
      // Get rid of the loading details screen entirely--the level is totally ready.
      if (!this.unveiling) {
        Backbone.Mediator.publish('level:loading-view-unveiling', {});
        this.unveiling = true;
      }
      if (this.$el.hasClass('preview-screen')) {
        this.$loadingDetails.css('right', -this.$loadingDetails.outerWidth(true));
      } else {
        this.$loadingDetails.css('top', -this.$loadingDetails.outerHeight(true));
      }
      this.$el.removeClass('preview-screen');
      $('#canvas-wrapper').removeClass('preview-overlay');
      if (this.unveilPreviewTime) {
        const levelSlug = (this.level != null ? this.level.get('slug') : undefined) || (this.options.level != null ? this.options.level.get('slug') : undefined);
        const timespent = (new Date().getTime() - this.unveilPreviewTime) / 1000;
        return (window.tracker != null ? window.tracker.trackEvent('Finish Viewing Intro', {
          category: 'Play Level',
          label: 'level loading',
          level: levelSlug,
          levelID: levelSlug,
          timespent
        }) : undefined);
      }
    }

    unveilLoadingPreview(duration) {
      // Move the loading details screen over the code editor to preview the level.
      if (this.$el.hasClass('preview-screen')) { return; }
      $('#canvas-wrapper').addClass('preview-overlay');
      this.$el.addClass('preview-screen');
      this.$loadingDetails.addClass('preview');
      this.resize();
      this.onWindowResize = _.debounce(this.onWindowResize, 700);  // Wait a bit for other views to resize before we resize
      $(window).on('resize', this.onWindowResize);
      if (this.intro) {
        this.$el.find('.progress-or-start-container').addClass('intro-footer');
        this.$el.find('#tip-wrapper').remove();
        _.delay(this.unveilIntro, duration);
      }
      return this.unveilPreviewTime = new Date().getTime();
    }

    resize() {
      const maxHeight = $('#page-container').outerHeight(true);
      let minHeight = $('#code-area').outerHeight(true);
      minHeight -= 20;
      this.$el.css({height: maxHeight});
      this.$loadingDetails.css({minHeight, maxHeight});
      if (this.intro) {
        const $intro = this.$el.find('.intro-doc');
        $intro.css({height: minHeight - $intro.offset().top - this.$el.find('.progress-or-start-container').outerHeight() - 30 - 20});
        return _.defer(() => $intro.find('.nano').nanoScroller({alwaysVisible: true}));
      }
    }

    unveilWings(duration) {
      this.playSound('loading-view-unveil', 0.5);
      this.$el.find('.left-wing').css({left: '-100%', backgroundPosition: 'right -400px top 0'});
      this.$el.find('.right-wing').css({right: '-100%', backgroundPosition: 'left -400px top 0'});
      if (!(this.level != null ? this.level.isType('web-dev') : undefined)) { return $('#level-footer-background').detach().appendTo('#page-container').slideDown(duration); }
    }

    unveilIntro() {
      let html, problem;
      if (this.destroyed || !this.intro || this.unveiled) { return; }
      if (window.serverConfig.picoCTF && (problem = this.level.picoCTFProblem)) {
        html = marked(`\
### ${problem.name}

${this.intro.body}

${problem.description}

${problem.category} - ${problem.score} points\
`, {sanitize: false});
      } else {
        const language = this.session != null ? this.session.get('codeLanguage') : undefined;
        html = marked(aetherUtils.filterMarkdownCodeLanguages(utils.i18n(this.intro, 'body'), language));
      }
      this.$el.find('.intro-doc').removeClass('hidden').find('.intro-doc-content').html(html);
      this.resize();
      return this.configureACEEditors();
    }

    onUnveilEnded() {
      if (this.destroyed) { return; }
      return Backbone.Mediator.publish('level:loading-view-unveiled', {view: this});
    }

    onWindowResize(e) {
      if (this.destroyed) { return; }
      this.$loadingDetails.css({transition: 'none'});
      return this.resize();
    }

    onSubscriptionRequired(e) {
      if (utils.isOzaria) { return; }
      this.$el.find('.level-loading-goals, .tip, .progress-or-start-container').hide();
      return this.$el.find('.subscription-required').show();
    }

    onCourseMembershipRequired(e) {
      this.$el.find('.level-loading-goals, .tip, .progress-or-start-container').hide();
      return this.$el.find('.course-membership-required').show();
    }

    onLicenseRequired(e) {
      this.$el.find('.level-loading-goals, .tip, .progress-or-start-container').hide();
      return this.$el.find('.license-required').show();
    }

    onLoadError(resource) {
      const startCase = str => str.charAt(0).toUpperCase() + str.slice(1);
      this.$el.find('.level-loading-goals, .tip, .progress-or-start-container').hide();
      if (resource.resource.jqxhr.status === 404) {
        this.$el.find('.resource-not-found>span').text($.i18n.t('loading_error.resource_not_found', {resource: startCase(resource.resource.name)}));
        return this.$el.find('.resource-not-found').show();
      } else {
        return this.$el.find('.could-not-load').show();
      }
    }

    onClickStartSubscription(e) {
      this.openModalView(new SubscribeModal());
      const levelSlug = (this.level != null ? this.level.get('slug') : undefined) || (this.options.level != null ? this.options.level.get('slug') : undefined);
      // TODO: Added levelID on 2/9/16. Remove level property and associated AnalyticsLogEvent 'properties.level' index later.
      return (window.tracker != null ? window.tracker.trackEvent('Show subscription modal', {category: 'Subscription', label: 'level loading', level: levelSlug, levelID: levelSlug}) : undefined);
    }

    onSubscribed() {
      return document.location.reload();
    }

    destroy() {
      $(window).off('resize', this.onWindowResize);
      const silentStore = { commit: _.noop, dispatch: _.noop };
      if (this.levelGoalsComponent != null) {
        this.levelGoalsComponent.$destroy();
      }
      if (this.levelGoalsComponent != null) {
        this.levelGoalsComponent.$store = silentStore;
      }
      return super.destroy();
    }
  };
  LevelLoadingView.initClass();
  return LevelLoadingView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}