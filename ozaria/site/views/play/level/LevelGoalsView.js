/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LevelGoalsView;
require('ozaria/site/styles/play/level/goals.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/play/level/goals');
const {me} = require('core/auth');
const utils = require('core/utils');
const LevelSession = require('models/LevelSession');
const Level = require('models/Level');
const LevelGoals = require('./LevelGoals').default;
const store = require('core/store');


module.exports = (LevelGoalsView = (function() {
  LevelGoalsView = class LevelGoalsView extends CocoView {
    static initClass() {
      this.prototype.id = 'goals-view';
      this.prototype.template = template;
      this.prototype.className = 'secret expanded';
  
      this.prototype.subscriptions = {
        'goal-manager:new-goal-states': 'onNewGoalStates',
        'tome:cast-spells': 'onTomeCast'
      };
    }

    constructor(options) {
      super(options);
      this.level = options.level;
    }

    afterRender() {
      return this.levelGoalsComponent = new LevelGoals({
        el: this.$('.goals-component')[0],
        store,
        propsData: { showStatus: true }
      });
    }

    onNewGoalStates(e) {
      _.assign(this.levelGoalsComponent, _.pick(e, 'overallStatus', 'timedOut', 'goals', 'goalStates', 'capstoneStage'));
      this.levelGoalsComponent.casting = false;

      if (this.previousGoalStatus == null) { this.previousGoalStatus = {}; }
      this.succeeded = e.overallStatus === 'success';
      for (var goal of Array.from(e.goals)) {
        var state = e.goalStates[goal.id] || { status: 'incomplete' };
        this.previousGoalStatus[goal.id] = state.status;
      }
      if ((e.goals.length > 0) && this.$el.hasClass('secret')) {
        return this.$el.removeClass('secret');
      }
    }

    onTomeCast(e) {
      if (e.preload) { return; }
      return this.levelGoalsComponent.casting = true;
    }

    destroy() {
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
  LevelGoalsView.initClass();
  return LevelGoalsView;
})());
