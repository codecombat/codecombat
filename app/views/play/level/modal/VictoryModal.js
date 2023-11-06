/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let VictoryModal;
require('app/styles/play/level/modal/victory.sass');
const ModalView = require('views/core/ModalView');
const CreateAccountModal = require('views/core/CreateAccountModal');
const template = require('app/templates/play/level/modal/victory');
const {me} = require('core/auth');
const LadderSubmissionView = require('views/play/common/LadderSubmissionView');
const LevelFeedback = require('models/LevelFeedback');
const utils = require('core/utils');

module.exports = (VictoryModal = (function() {
  VictoryModal = class VictoryModal extends ModalView {
    static initClass() {
      this.prototype.id = 'level-victory-modal';
      this.prototype.template = template;

      this.prototype.subscriptions =
        {'ladder:game-submitted': 'onGameSubmitted'};

      this.prototype.events = {
        'click .sign-up-button': 'onClickSignupButton',

        // review events
        'mouseover .rating i'(e) { return this.showStars(this.starNum($(e.target))); },
        'mouseout .rating i'() { return this.showStars(); },
        'click .rating i'(e) {
          this.setStars(this.starNum($(e.target)));
          return this.$el.find('.review').show();
        },
        'keypress .review textarea'() { return this.saveReviewEventually(); }
      };
    }

    constructor(options) {
      super(options);
      application.router.initializeSocialMediaServices();
      const victory = options.level.get('victory', true);
      const body = utils.i18n(victory, 'body') || 'Sorry, this level has no victory message yet.';
      this.body = marked(body);
      this.level = options.level;
      this.session = options.session;
      this.saveReviewEventually = _.debounce(this.saveReviewEventually, 2000);
      this.loadExistingFeedback();
    }

    loadExistingFeedback() {
      const url = `/db/level/${this.level.id}/feedback`;
      this.feedback = new LevelFeedback();
      this.feedback.setURL(url);
      this.feedback.fetch({cache: false});
      this.listenToOnce(this.feedback, 'sync', function() { return this.onFeedbackLoaded(); });
      return this.listenToOnce(this.feedback, 'error', function() { return this.onFeedbackNotFound(); });
    }

    onFeedbackLoaded() {
      this.feedback.url = function() { return '/db/level.feedback/' + this.id; };
      this.$el.find('.review textarea').val(this.feedback.get('review'));
      this.$el.find('.review').show();
      return this.showStars();
    }

    onFeedbackNotFound() {
      this.feedback = new LevelFeedback();
      this.feedback.set('levelID', this.level.get('slug') || this.level.id);
      this.feedback.set('levelName', this.level.get('name') || '');
      this.feedback.set('level', {majorVersion: this.level.get('version').major, original: this.level.get('original')});
      return this.showStars();
    }

    onClickSignupButton(e) {
      e.preventDefault();
      if (window.tracker != null) {
        window.tracker.trackEvent('Started Signup', {category: 'Play Level', label: 'Victory Modal', level: this.level.get('slug')});
      }
      return this.openModalView(new CreateAccountModal());
    }

    onGameSubmitted(e) {
      const ladderURL = `/play/ladder/${this.level.get('slug')}#my-matches`;
      return Backbone.Mediator.publish('router:navigate', {route: ladderURL});
    }

    getRenderData() {
      const c = super.getRenderData();
      c.body = this.body;
      c.me = me;
      c.levelName = utils.i18n(this.level.attributes, 'name');
      c.level = this.level;
      if (c.level.isType('ladder')) {
        c.readyToRank = this.session.readyToRank();
      }
      return c;
    }

    afterRender() {
      super.afterRender();
      this.ladderSubmissionView = new LadderSubmissionView({session: this.session, level: this.level});
      return this.insertSubView(this.ladderSubmissionView, this.$el.find('.ladder-submission-view'));
    }

    afterInsert() {
      super.afterInsert();
      this.playSound('victory');
      __guardMethod__(typeof gapi !== 'undefined' && gapi !== null ? gapi.plusone : undefined, 'go', o => o.go(this.$el[0]));
      __guardMethod__(typeof FB !== 'undefined' && FB !== null ? FB.XFBML : undefined, 'parse', o1 => o1.parse(this.$el[0]));
      return __guardMethod__(typeof twttr !== 'undefined' && twttr !== null ? twttr.widgets : undefined, 'load', o2 => o2.load());
    }

    destroy() {
      if (this.$el.find('.review textarea').val()) { this.saveReview(); }
      this.feedback.off();
      return super.destroy();
    }

    // rating, review

    starNum(starEl) { return starEl.prevAll('i').length + 1; }

    showStars(num) {
      this.$el.find('.rating').show();
      if (num == null) { num = (this.feedback != null ? this.feedback.get('rating') : undefined) || 0; }
      const stars = this.$el.find('.rating i');
      stars.removeClass('icon-star').addClass('icon-star-empty');
      return stars.slice(0, num).removeClass('icon-star-empty').addClass('icon-star');
    }

    setStars(num) {
      this.feedback.set('rating', num);
      return this.feedback.save();
    }

    saveReviewEventually() {
      return this.saveReview();
    }

    saveReview() {
      this.feedback.set('review', this.$el.find('.review textarea').val());
      return this.feedback.save();
    }
  };
  VictoryModal.initClass();
  return VictoryModal;
})());

function __guardMethod__(obj, methodName, transform) {
  if (typeof obj !== 'undefined' && obj !== null && typeof obj[methodName] === 'function') {
    return transform(obj, methodName);
  } else {
    return undefined;
  }
}