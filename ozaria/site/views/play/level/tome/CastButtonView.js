/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CastButtonView;
require('ozaria/site/styles/play/level/tome/cast_button.sass');
const CocoView = require('views/core/CocoView');
const template = require('ozaria/site/templates/play/level/tome/cast-button-view');
const {me} = require('core/auth');
const LadderSubmissionView = require('views/play/common/LadderSubmissionView');
const LevelSession = require('models/LevelSession');
const async = require('vendor/scripts/async.js');
const GoalManager = require('lib/world/GoalManager');
const store = require('core/store');

module.exports = (CastButtonView = (function() {
  CastButtonView = class CastButtonView extends CocoView {
    static initClass() {
      this.prototype.id = 'cast-button-view';
      this.prototype.template = template;

      this.prototype.events = {
        'click #run': 'onRunButtonClick',
        'click #update-game': 'onUpdateButtonClick',
        'click #next': 'onNextButtonClick',
        'click #fill-solution': 'onFillSolution'
      };

      this.prototype.subscriptions = {
        'tome:spell-changed': 'onSpellChanged',
        'tome:cast-spells': 'onCastSpells',
        'tome:manual-cast-denied': 'onManualCastDenied',
        'god:new-world-created': 'onNewWorld',
        'goal-manager:new-goal-states': 'onNewGoalStates',
        'god:goals-calculated': 'onGoalsCalculated',
        'playback:ended-changed': 'onPlaybackEndedChanged',
        'playback:playback-ended': 'onPlaybackEnded'
      };
    }

    constructor(options) {
      super(options)
      let needle;
      this.updateReplayability = this.updateReplayability.bind(this);
      this.spells = options.spells;
      this.castShortcut = '⇧↵';
      this.updateReplayabilityInterval = setInterval(this.updateReplayability, 1000);
      this.observing = options.session.get('creator') !== me.id;
      // WARNING: CourseVictoryModal does not handle mirror sessions when submitting to ladder; adjust logic if a
      // mirror level is added to
      // Keep server/middleware/levels.coffee mirror list in sync with this one
      if (this.options.level.get('mirrorMatch') || (needle = this.options.level.get('slug'), ['ace-of-coders', 'elemental-wars', 'the-battle-of-sky-span', 'tesla-tesoro', 'escort-duty', 'treasure-games', 'king-of-the-hill'].includes(needle))) { this.loadMirrorSession(); }  // TODO: remove slug list once these levels are configured as mirror matches
      this.mirror = (this.mirrorSession != null);
      this.autoSubmitsToLadder = this.options.level.isType('course-ladder');
    }

    destroy() {
      clearInterval(this.updateReplayabilityInterval);
      return super.destroy();
    }

    afterRender() {
      let needle;
      super.afterRender();
      this.castButton = $('.cast-button', this.$el);
      for (var spellKey in this.spells) { var spell = this.spells[spellKey]; if (spell.view != null) {
        spell.view.createOnCodeChangeHandlers();
      } }
      if (this.options.level.get('hidesSubmitUntilRun') || this.options.level.get('hidesRealTimePlayback') || this.options.level.isType('web-dev')) {
        this.$el.find('.submit-button').hide();  // Hide Submit for the first few until they run it once.
      }
      if (__guard__(this.options.session.get('state'), x => x.complete) && (this.options.level.get('hidesRealTimePlayback') || this.options.level.isType('web-dev'))) {
        this.$el.find('.done-button').show();
      }
      if ((needle = this.options.level.get('slug'), ['course-thornbush-farm', 'thornbush-farm'].includes(needle))) {
        this.$el.find('.submit-button').hide();  // Hide submit until first win so that script can explain it.
      }
      this.updateReplayability();
      return this.updateLadderSubmissionViews();
    }

    attachTo(spellView) {
      return this.$el.detach().prependTo(spellView.toolbarView.$el).show();
    }

    castShortcutVerbose() {
      const shift = $.i18n.t('keyboard_shortcuts.shift');
      const enter = $.i18n.t('keyboard_shortcuts.enter');
      return `${shift}+${enter}`;
    }

    castVerbose() {
      return this.castShortcutVerbose() + ': ' + $.i18n.t('keyboard_shortcuts.run_code');
    }

    castRealTimeVerbose() {
      const castRealTimeShortcutVerbose = (this.isMac() ? 'Cmd' : 'Ctrl') + '+' + this.castShortcutVerbose();
      return castRealTimeShortcutVerbose + ': ' + $.i18n.t('keyboard_shortcuts.run_real_time');
    }

    onRunButtonClick(e) {
      return Backbone.Mediator.publish('tome:manual-cast', { realTime: false });
    }

    onUpdateButtonClick(e) {
      Backbone.Mediator.publish('tome:update-aether-running', {});
      return Backbone.Mediator.publish('tome:update-aether', {});
    }

    onNextButtonClick(e) {
      if (this.winnable) {
        this.options.session.recordScores(this.world != null ? this.world.scores : undefined, this.options.level);
        const args = {
          showModal: true,
          manual: true
        };
        if (this.options.level.get('ozariaType') === 'capstone') {
          // Passed in from PlayLevelView->TomeView, it is the Capstone Stage that has been just completed,
          // or updated in softReloadCapstoneStage
          const {
            capstoneStage
          } = this.options;
          const finalStage = GoalManager.maxCapstoneStage(this.options.level.get('additionalGoals'));
          args['capstoneInProgress'] = capstoneStage < finalStage;
          args['isCapstone'] = true;
        }
        return Backbone.Mediator.publish('level:show-victory', args);
      }
    }

    onFillSolution() {
      if (!me.canAutoFillCode()) { return; }
      const codeLanguage = __guard__(_.values(this.spells)[0], x => x.language) || utils.getQueryVariable('codeLanguage') || 'python';
      return store.dispatch('game/autoFillSolution', codeLanguage);
    }

    onSpellChanged(e) {
      return this.updateCastButton();
    }

    onCastSpells(e) {
      if (e.preload) { return; }
      this.casting = true;

      // TODO: replace with Ozaria sound
      // if @hasStartedCastingOnce  # Don't play this sound the first time
      //   @playSound 'cast', 0.5 unless @options.level.isType('game-dev')

      this.hasStartedCastingOnce = true;
      return this.updateCastButton();
    }

    onManualCastDenied(e) {
      const wait = moment().add(e.timeUntilResubmit, 'ms').fromNow();
      //@playSound 'manual-cast-denied', 1.0   # find some sound for this?
      return noty({text: `You can try again ${wait}.`, layout: 'center', type: 'warning', killer: false, timeout: 6000});
    }

    onNewWorld(e) {
      this.casting = false;
      if (this.hasCastOnce) {  // Don't play this sound the first time

        // TODO: replace with Ozaria sound
        // @playSound 'cast-end', 0.5 unless @options.level.isType('game-dev')

        // Worked great for live beginner tournaments, but probably annoying for asynchronous tournament mode.
        const myHeroID = me.team === 'ogres' ? 'Hero Placeholder 1' : 'Hero Placeholder';
        if (this.autoSubmitsToLadder && !(e.world.thangMap[myHeroID] != null ? e.world.thangMap[myHeroID].errorsOut : undefined) && !me.get('anonymous')) {
          if (this.ladderSubmissionView) { _.delay((() => (this.ladderSubmissionView != null ? this.ladderSubmissionView.rankSession() : undefined)), 1000); }
        }
      }
      this.hasCastOnce = true;
      this.updateCastButton();
      return this.world = e.world;
    }

    onPlaybackEnded(e) {
      if (this.winnable && (this.options.level.get('ozariaType') !== 'capstone')) {
        return Backbone.Mediator.publish('level:show-victory', { showModal: true, manual: true });
      }
    }

    onNewGoalStates(e) {
      this.winnable = e.overallStatus === 'success';
      const maxStage = Math.max(...Array.from((this.options.level.get('additionalGoals') || []).map(g => g.stage) || []));
      if ((this.options.level.get('ozariaType') === 'capstone') && ((this.options != null ? this.options.capstoneStage : undefined) === maxStage) && (this.options.level.get('creativeMode') === true)) {
        // In final stage of creativeMode capstone we ignore all goals to allow unconstrained freedom.
        // If there is a win-goal state set to that one single state.
        if (typeof __guard__(e.goalStates != null ? e.goalStates['win-game'] : undefined, x => x.status) === 'string') {
          this.winnable = __guard__(e.goalStates != null ? e.goalStates['win-game'] : undefined, x1 => x1.status) === 'success';
        } else {
          this.winnable = true;
        }
      }

      if (this.winnable) {
        return this.$el.find('#next').removeClass('inactive');
      } else {
        return this.$el.find('#next').addClass('inactive');
      }
    }

    onGoalsCalculated(e) {
      // When preloading, with real-time playback enabled, we highlight the submit button when we think they'll win.
      let needle;
      if (e.god !== this.god) { return; }
      if (!e.preload) { return; }
      if (this.options.level.get('hidesRealTimePlayback')) { return; }
      if ((needle = this.options.level.get('slug'), ['course-thornbush-farm', 'thornbush-farm'].includes(needle))) { return; }  // Don't show it until they actually win for this first one.
      return this.onNewGoalStates(e);
    }

    onPlaybackEndedChanged(e) {
      if (!e.ended || !this.winnable) { return; }
      return this.$el.toggleClass('has-seen-winning-replay', true);
    }

    updateCastButton() {
      if (_.some(this.spells, spell => !spell.loaded)) { return; }

      // TODO: performance: Get rid of async since this is basically the ONLY place we use it
      return async.some(_.values(this.spells), (spell, callback) => {
        return spell.hasChangedSignificantly(spell.getSource(), null, callback);
      }
      , castable => {
        let castText;
        Backbone.Mediator.publish('tome:spell-has-changed-significantly-calculation', {hasChangedSignificantly: castable});
        this.castButton.toggleClass('castable', castable).toggleClass('casting', this.casting);
        if (this.casting) {
          castText = $.i18n.t('play_level.tome_cast_button_running');
        } else if (castable || true) {
          castText = $.i18n.t('play_level.tome_cast_button_run');
          if (!this.options.level.get('hidesRunShortcut')) {  // Hide for first few.
            castText += ' ' + this.castShortcut;
          }
        } else {
          castText = $.i18n.t('play_level.tome_cast_button_ran');
        }
        this.castButton.text(castText);
        //@castButton.prop 'disabled', not castable
        return (this.ladderSubmissionView != null ? this.ladderSubmissionView.updateButton() : undefined);
      });
    }

    updateReplayability() {
      if (this.destroyed) { return; }
      if (!this.options.level.get('replayable')) { return; }
      const timeUntilResubmit = this.options.session.timeUntilResubmit();
      const disabled = timeUntilResubmit > 0;
      const submitButton = this.$el.find('.submit-button').toggleClass('disabled', disabled);
      const submitAgainLabel = submitButton.find('.submit-again-time').toggleClass('secret', !disabled);
      if (disabled) {
        const waitTime = moment().add(timeUntilResubmit, 'ms').fromNow();
        return submitAgainLabel.text(waitTime);
      }
    }

    loadMirrorSession() {
      // Future work would be to only load this the first time we are going to submit (or auto submit), so that if we write some code but don't submit it, the other session can still initialize itself with it.
      let url = `/db/level/${this.options.level.get('slug') || this.options.level.id}/session`;
      url += `?team=${me.team === 'humans' ? 'ogres' : 'humans'}`;
      const mirrorSession = new LevelSession().setURL(url);
      this.mirrorSession = this.supermodel.loadModel(mirrorSession, {cache: false}).model;
      return this.listenToOnce(this.mirrorSession, 'sync', function() {
        return (this.ladderSubmissionView != null ? this.ladderSubmissionView.mirrorSession = this.mirrorSession : undefined);
      });
    }

    updateLadderSubmissionViews() {
      for (var key in this.subviews) { var subview = this.subviews[key]; if (subview instanceof LadderSubmissionView) { this.removeSubView(subview); } }
      const placeholder = this.$el.find('.ladder-submission-view');
      if (!placeholder.length) { return; }
      this.ladderSubmissionView = new LadderSubmissionView({session: this.options.session, level: this.options.level, mirrorSession: this.mirrorSession});
      return this.insertSubView(this.ladderSubmissionView, placeholder);
    }

    softReloadCapstoneStage(newCapstoneStage) {
      return this.options.capstoneStage = newCapstoneStage;
    }
  };
  CastButtonView.initClass();
  return CastButtonView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}