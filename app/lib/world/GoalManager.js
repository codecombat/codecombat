// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let GoalManager;
const CocoClass = require('core/CocoClass');
const utils = require('core/utils');

module.exports = (GoalManager = (function() {
  GoalManager = class GoalManager extends CocoClass {
    static initClass() {
      // The Goal Manager is created both on the main thread and
      // each time the world is generated. The one in world generation
      // records which code and world related goals
      // are completed or failed, and then the results are sent back
      // and saved to the main thread instance.
      // The main instance handles goals based on UI notifications,
      // and keeps track of what the goals are at any given point.

      // Goals can only have only one goal property. Otherwise who knows what will happen.
      // If you want weird goals or hybrid goals, make a custom goal.

      this.prototype.nextGoalID = 0;
      this.prototype.nicks = ['GoalManager'];

      this.prototype.subscriptions = {
        'god:new-world-created': 'onNewWorldCreated',
        'god:new-html-goal-states': 'onNewHTMLGoalStates',
        'level:restarted': 'onLevelRestarted'
      };

      this.prototype.backgroundSubscriptions = {
        'world:thang-died': 'onThangDied',
        'world:thang-touched-goal': 'onThangTouchedGoal',
        'world:thang-left-map': 'onThangLeftMap',
        'world:thang-collected-item': 'onThangCollectedItem',
        'world:user-code-problem': 'onUserCodeProblem',
        'world:lines-of-code-counted': 'onLinesOfCodeCounted'
      };

      this.prototype.positiveGoalMap = {
        killThangs: 1,
        saveThangs: 0,
        getToLocations: 1,
        getAllToLocations: 1,
        keepFromLocations: 0,
        keepAllFromLocations: 0,
        leaveOffSides: 1,
        keepFromLeavingOffSides: 0,
        collectThangs: 1,
        keepFromCollectingThangs: 0,
        linesOfCode: 0,
        codeProblems: 0
      };
    }

    constructor(world, initialGoals, team, options) {
      super();
      this.world = world;
      this.initialGoals = initialGoals;
      this.team = team;
      this.options = options || {};
      this.init();
    }

    init() {
      let goal;
      this.goals = [];
      this.goalStates = {}; // goalID -> object (complete, frameCompleted)
      this.userCodeMap = {}; // @userCodeMap.thangID.methodName.aether.raw = codeString
      this.thangTeams = {};
      this.hasProgressed = false; // capstoneStage progression
      this.initThangTeams();
      if (this.initialGoals) { for (goal of Array.from(this.initialGoals)) { this.addGoal(goal); } }
      if (utils.isOzaria && (this.options != null ? this.options.session : undefined) && (this.options != null ? this.options.additionalGoals : undefined)) {
        const additionalGoals = _.cloneDeep(this.options.additionalGoals);
        const capstoneStage = this.options.capstoneStage || 1; // passed in from PlayLevelView
        const stages = _.filter(additionalGoals, ag => (ag.stage <= capstoneStage) && (ag.stage > 0));
        const goals = _.map(stages, stage => stage.goals.map(function(goal) {
          goal.stage = stage.stage;
          return goal;
        }));
        const unwrappedGoals = _.flatten(goals);
        return (() => {
          const result = [];
          for (goal of Array.from(unwrappedGoals)) {             result.push(this.addGoal(goal));
          }
          return result;
        })();
      }
    }

    initThangTeams() {
      if (!this.world) { return; }
      return (() => {
        const result = [];
        for (var thang of Array.from(this.world.thangs)) {
          if (thang.team && thang.isAttackable) {
            if (!thang.team) { continue; }
            if (!this.thangTeams[thang.team]) { this.thangTeams[thang.team] = []; }
            result.push(this.thangTeams[thang.team].push(thang.id));
          }
        }
        return result;
      })();
    }

    onLevelRestarted() {
      this.goals = [];
      this.goalStates = {};
      this.userCodeMap = {};
      this.notifyGoalChanges();
      if (this.initialGoals) { return Array.from(this.initialGoals).map((goal) => this.addGoal(goal)); }
    }

    // INTERFACE AND LIFETIME OVERVIEW

    // world generator gets current goals from the main instance
    getGoals() { return this.goals; }

    getRemainingGoals() { return _.filter(this.goalStates, state => state.status !== 'success'); }

    // background instance created by world generator,
    // gets these goals and code, and is told to be all ears during world gen
    setGoals(goals) {
      this.goals = goals;
    }
    setCode(userCodeMap) { this.userCodeMap = userCodeMap; return this.updateCodeGoalStates(); }
    worldGenerationWillBegin() {
      this.initGoalStates();
      return this.checkForInitialUserCodeProblems();
    }

    // World generator feeds world events to the goal manager to keep track
    submitWorldGenerationEvent(channel, event, frameNumber) {
      let func = this.backgroundSubscriptions[channel];
      func = utils.normalizeFunc(func, this);
      if (!func) { return; }
      return func.call(this, event, frameNumber);
    }

    // after world generation, generated goal states
    // are grabbed to send back to main instance
    worldGenerationEnded(finalFrame) { return this.wrapUpGoalStates(finalFrame); }
    getGoalStates() { return this.goalStates; }

    // main instance gets them and updates their existing goal states,
    // passes the word along
    onNewWorldCreated(e) {
      this.world = e.world;
      if (e.goalStates != null) { return this.updateGoalStates(e.goalStates); }
    }

    onNewHTMLGoalStates(e) {
      if (e.goalStates != null) { return this.updateGoalStates(e.goalStates); }
    }

    updateGoalStates(newGoalStates) {
      for (var goalID in newGoalStates) {
        var goalState = newGoalStates[goalID];
        if (this.goalStates[goalID] == null) { continue; }
        this.goalStates[goalID] = goalState;
      }
      return this.notifyGoalChanges();
    }

    static maxCapstoneStage(additionalGoals) {
      if (!additionalGoals) {
        return 0;
      }

      return _.max(additionalGoals, goals => goals.stage).stage; // assuming that additionalGoals will have the goals for the last stage.
    }

    // Progresses the capstone stage if more goals are available
    // Returns the current capstoneStage
    progressCapstoneStage(session, additionalGoals) {
      if (this.hasProgressed) { // Only ever progress a capstone stage once per GoalManager
        return;
      }

      // In daily speak, we think of initial goals as stage 1 and additional goals
      // as stage 2 and above. That is why we are starting from 1.
      const capstoneStage = (session.get('state') || {}).capstoneStage || 1;

      // The capstoneStage will eventually end up being 1 above the final additionalStage,
      // when every stage been completed. That means the whole level is complete.
      if (capstoneStage <= GoalManager.maxCapstoneStage(additionalGoals)) {
        this.hasProgressed = true;
        const state = session.get('state') || {};
        state.capstoneStage = capstoneStage + 1;
        session.set('state', state);
        return session.save(null, { success() {} }); // Save and move on, we don't have time to wait here
      }
    }

    // Checks if the overall goal status is 'success', then progresses
    // capstone goals to the next stage if there are more goals
    finishLevel() {
      const stageFinished = this.checkOverallStatus() === 'success';
      if (this.options.additionalGoals && stageFinished) {
        if (utils.isOzaria) {
          this.progressCapstoneStage(this.options.session, this.options.additionalGoals);
        } else {
          this.addAdditionalGoals(this.options.session, this.options.additionalGoals);
        }
      }

      return stageFinished;
    }

    // IMPLEMENTATION DETAILS

    addGoal(goal) {
      goal = $.extend(true, {}, goal);
      if (!goal.id) { goal.id = this.nextGoalID++; }
      // The initial goals also need a capstone stage if this is indeed goals for a capstone stage:
      if (utils.isOzaria && !goal.stage && (this.options != null ? this.options.additionalGoals : undefined)) {
        goal.stage = 1;
      }
      if (this.goalStates[goal.id] != null) { return; }
      this.goals.push(goal);
      goal.isPositive = this.goalIsPositive(goal.id);
      this.goalStates[goal.id] = {status: 'incomplete', keyFrame: 0, team: goal.team};
      this.notifyGoalChanges();
      if (!goal.notificationGoal) { return; }
      const f = channel => event => this.onNote(channel, event);
      const {
        channel
      } = goal.notificationGoal;
      return this.addNewSubscription(channel, f(channel));
    }

    notifyGoalChanges() {
      let noTimeOutStatuses;
      if (this.options.headless) { return; }
      const overallStatus = this.checkOverallStatus();
      if (utils.isOzaria) {
        noTimeOutStatuses = ['success', 'failure', null];
      } else {
        noTimeOutStatuses = ['success', 'failure'];
      }
      const event = {
        goalStates: this.goalStates,
        goals: this.goals,
        overallStatus,
        timedOut: (this.world != null) && ((this.world.totalFrames === this.world.maxTotalFrames) && !Array.from(noTimeOutStatuses).includes(overallStatus)),
        capstoneStage: (this.options != null ? this.options.capstoneStage : undefined)
      };
      return Backbone.Mediator.publish('goal-manager:new-goal-states', event);
    }

    checkOverallStatus(ignoreIncomplete) {
      let g;
      if (ignoreIncomplete == null) { ignoreIncomplete = false; }
      let overallStatus = null;
      let goals = this.goalStates ? _.values(this.goalStates) : [];
      goals = ((() => {
        const result = [];
        for (g of Array.from(goals)) {           if (!g.optional) {
            result.push(g);
          }
        }
        return result;
      })());
      if (this.team) { goals = ((() => {
        const result1 = [];
        for (g of Array.from(goals)) {           if ([undefined, this.team].includes(g.team)) {
            result1.push(g);
          }
        }
        return result1;
      })()); }
      const statuses = (Array.from(goals).map((goal) => goal.status));
      const isSuccess = s => (s === 'success') || (ignoreIncomplete && (s === null));
      if (_.any(goals.map(g => (g.concepts != null ? g.concepts.length : undefined)))) {
        const conceptStatuses = goals.filter(g => (g.concepts != null ? g.concepts.length : undefined)).map(g => g.status);
        const levelStatuses = goals.filter(g => !(g.concepts != null ? g.concepts.length : undefined)).map(g => g.status);
        overallStatus = _.all(levelStatuses, isSuccess) && _.any(conceptStatuses, isSuccess) ? 'success' : 'failure';
      } else {
        if ((statuses.length > 0) && _.every(statuses, isSuccess)) { overallStatus = 'success'; }
        if ((statuses.length > 0) && Array.from(statuses).includes('failure')) { overallStatus = 'failure'; }
      }
      return overallStatus;
    }

    // WORLD GOAL TRACKING

    initGoalStates() {
      this.goalStates = {};
      if (!this.goals) { return; }
      return (() => {
        const result = [];
        for (var goal of Array.from(this.goals)) {
          var state = {
            status: null, // should eventually be either 'success', 'failure', or 'incomplete'
            keyFrame: 0, // when it became a 'success' or 'failure'
            team: goal.team,
            optional: goal.optional,
            hiddenGoal: goal.hiddenGoal,
            concepts: goal.concepts
          };
          this.initGoalState(state, [goal.killThangs, goal.saveThangs], 'killed');
          for (var getTo of Array.from(goal.getAllToLocations != null ? goal.getAllToLocations : [])) {
            this.initGoalState(state, [(getTo.getToLocation != null ? getTo.getToLocation.who : undefined), []], 'arrived');
          }
          for (var keepFrom of Array.from(goal.keepAllFromLocations != null ? goal.keepAllFromLocations : [])) {
            this.initGoalState(state, [[], (keepFrom.keepFromLocation != null ? keepFrom.keepFromLocation.who : undefined)], 'arrived');
          }
          this.initGoalState(state, [(goal.getToLocations != null ? goal.getToLocations.who : undefined), (goal.keepFromLocations != null ? goal.keepFromLocations.who : undefined)], 'arrived');
          this.initGoalState(state, [(goal.leaveOffSides != null ? goal.leaveOffSides.who : undefined), (goal.keepFromLeavingOffSides != null ? goal.keepFromLeavingOffSides.who : undefined)], 'left');
          this.initGoalState(state, [(goal.collectThangs != null ? goal.collectThangs.targets : undefined), (goal.keepFromCollectingThangs != null ? goal.keepFromCollectingThangs.targets : undefined)], 'collected');
          this.initGoalState(state, [goal.codeProblems], 'problems');
          this.initGoalState(state, [_.keys(goal.linesOfCode != null ? goal.linesOfCode : {})], 'lines');
          result.push(this.goalStates[goal.id] = state);
        }
        return result;
      })();
    }

    checkForInitialUserCodeProblems() {
      // There might have been some user code problems reported before the goal manager started listening.
      if (!this.world) { return; }
      return Array.from(this.world.thangs).filter((thang) => thang.isProgrammable).map((thang) =>
        (() => {
          const result = [];
          for (var message in thang.publishedUserCodeProblems) {
            var problem = thang.publishedUserCodeProblems[message];
            result.push(this.onUserCodeProblem({thang, problem}, 0));
          }
          return result;
        })());
    }

    onThangDied(e, frameNumber) {
      return (() => {
        const result = [];
        for (var goal of Array.from(this.goals != null ? this.goals : [])) {
          if (goal.killThangs != null) { this.checkKillThangs(goal.id, goal.killThangs, e.thang, frameNumber); }
          if (goal.saveThangs != null) { result.push(this.checkKillThangs(goal.id, goal.saveThangs, e.thang, frameNumber)); } else {
            result.push(undefined);
          }
        }
        return result;
      })();
    }

    checkKillThangs(goalID, targets, thang, frameNumber) {
      if (!Array.from(targets).includes(thang.id) && !Array.from(targets).includes(thang.team)) { return; }
      return this.updateGoalState(goalID, thang.id, 'killed', frameNumber);
    }

    onThangTouchedGoal(e, frameNumber) {
      return (() => {
        const result = [];
        for (var goal of Array.from(this.goals != null ? this.goals : [])) {
          if (goal.getToLocations != null) { this.checkArrived(goal.id, goal.getToLocations.who, goal.getToLocations.targets, e.actor, e.touched.id, frameNumber); }
          if (goal.getAllToLocations != null) {
            for (var getTo of Array.from(goal.getAllToLocations)) {
              this.checkArrived(goal.id, getTo.getToLocation.who, getTo.getToLocation.targets, e.actor, e.touched.id, frameNumber);
            }
          }
          if (goal.keepFromLocations != null) { this.checkArrived(goal.id, goal.keepFromLocations.who, goal.keepFromLocations.targets, e.actor, e.touched.id, frameNumber); }
          if (goal.keepAllFromLocations != null) {
            result.push(Array.from(goal.keepAllFromLocations).map((keepFrom) =>
              this.checkArrived(goal.id, keepFrom.keepFromLocation.who , keepFrom.keepFromLocation.targets, e.actor, e.touched.id, frameNumber )));
          } else {
            result.push(undefined);
          }
        }
        return result;
      })();
    }

    checkArrived(goalID, who, targets, thang, touchedID, frameNumber) {
      if (!Array.from(targets).includes(touchedID)) { return; }
      if (!Array.from(who).includes(thang.id) && !Array.from(who).includes(thang.team)) { return; }
      return this.updateGoalState(goalID, thang.id, 'arrived', frameNumber);
    }

    onThangLeftMap(e, frameNumber) {
      return (() => {
        const result = [];
        for (var goal of Array.from(this.goals != null ? this.goals : [])) {
          if (goal.leaveOffSides != null) { this.checkLeft(goal.id, goal.leaveOffSides.who, goal.leaveOffSides.sides, e.thang, e.side, frameNumber); }
          if (goal.keepFromLeavingOffSides != null) { result.push(this.checkLeft(goal.id, goal.keepFromLeavingOffSides.who, goal.keepFromLeavingOffSides.sides, e.thang, e.side, frameNumber)); } else {
            result.push(undefined);
          }
        }
        return result;
      })();
    }

    checkLeft(goalID, who, sides, thang, side, frameNumber) {
      if (sides && side && !(Array.from(sides).includes(side))) { return; }
      if (!Array.from(who).includes(thang.id) && !Array.from(who).includes(thang.team)) { return; }
      return this.updateGoalState(goalID, thang.id, 'left', frameNumber);
    }

    onThangCollectedItem(e, frameNumber) {
      return (() => {
        const result = [];
        for (var goal of Array.from(this.goals != null ? this.goals : [])) {
          if (goal.collectThangs != null) { this.checkCollected(goal.id, goal.collectThangs.who, goal.collectThangs.targets, e.actor, e.item.id, frameNumber); }
          if (goal.keepFromCollectingThangs != null) { result.push(this.checkCollected(goal.id, goal.keepFromCollectingThangs.who, goal.keepFromCollectingThangs.targets, e.actor, e.item.id, frameNumber)); } else {
            result.push(undefined);
          }
        }
        return result;
      })();
    }

    checkCollected(goalID, who, targets, thang, itemID, frameNumber) {
      if (!Array.from(targets).includes(itemID)) { return; }
      if (!Array.from(who).includes(thang.id) && !Array.from(who).includes(thang.team)) { return; }
      return this.updateGoalState(goalID, itemID, 'collected', frameNumber);
    }

    onUserCodeProblem(e, frameNumber) {
      return Array.from(this.goals != null ? this.goals : []).filter((goal) => goal.codeProblems).map((goal) =>
        this.checkCodeProblem(goal.id, goal.codeProblems, e.thang, frameNumber));
    }

    checkCodeProblem(goalID, who, thang, frameNumber) {
      if (!Array.from(who).includes(thang.id) && !Array.from(who).includes(thang.team)) { return; }
      return this.updateGoalState(goalID, thang.id, 'problems', frameNumber);
    }

    onLinesOfCodeCounted(e, frameNumber) {
      return Array.from(this.goals != null ? this.goals : []).filter((goal) => goal.linesOfCode).map((goal) =>
        this.checkLinesOfCode(goal.id, goal.linesOfCode, e.thang, e.linesUsed, frameNumber));
    }

    checkLinesOfCode(goalID, who, thang, linesUsed, frameNumber) {
      let linesAllowed;
      if (!(linesAllowed = who[thang.id] != null ? who[thang.id] : who[thang.team])) { return; }
      if (linesUsed > linesAllowed) { return this.updateGoalState(goalID, thang.id, 'lines', frameNumber); }
    }

    wrapUpGoalStates(finalFrame) {
      return (() => {
        const result = [];
        for (var goalID in this.goalStates) {
          var state = this.goalStates[goalID];
          if (state.status === null) {
            if (this.goalIsPositive(goalID)) {
              result.push(state.status = 'incomplete');
            } else {
              state.status = 'success';
              result.push(state.keyFrame = 'end'); // special case for objective UI to handle
            }
          } else {
            result.push(undefined);
          }
        }
        return result;
      })();
    }

    // UI EVENT GOAL TRACKING

    onNote(channel, e) {}
      // TODO for UI event related goals

    // HELPER FUNCTIONS

    // It's a pretty similar pattern for each of the above goals.
    // Once you determine a thang has done the thing, you mark it done in the progress object.
    initGoalState(state, whos, progressObjectName) {
      // 'whos' is an array of goal 'who' values.
      // This inits the progress object for the goal tracking.

      const arrays = (Array.from(whos).filter((prop) => (prop != null ? prop.length : undefined)));
      if (!arrays.length) { return; }
      if (state[progressObjectName] == null) { state[progressObjectName] = {}; }
      return Array.from(arrays).map((array) =>
        Array.from(array).map((thang) =>
          (this.thangTeams[thang] != null) ?
            Array.from(this.thangTeams[thang]).map((t) =>
              (state[progressObjectName][t] = false))
          :
            (state[progressObjectName][thang] = false)));
    }

    getGoalState(goalID) {
      return this.goalStates[goalID].status;
    }

    setGoalState(goalID, status) {
      let overallStatus;
      var goalID;
      const state = this.goalStates[goalID];
      if (!state) {
        console.log('Could not set state for goalID ', goalID);
        return;
      }

      state.status = status;
      if (overallStatus = this.checkOverallStatus(true)) {
        const matchedGoals = ((() => {
          const result = [];
          for (goalID in this.goalStates) {
            var goalState = this.goalStates[goalID];
            if (goalState.status === overallStatus) {
              result.push(_.find(this.goals, {id: goalID}));
            }
          }
          return result;
        })());
        const mostEagerGoal = _.min(matchedGoals, 'worldEndsAfter');
        const victory = overallStatus === 'success';
        const tentative = overallStatus === 'success';
        if (mostEagerGoal !== Infinity) { return (this.world != null ? this.world.endWorld(victory, mostEagerGoal.worldEndsAfter, tentative) : undefined); }
      }
    }

    updateGoalState(goalID, thangID, progressObjectName, frameNumber) {
      // A thang has done something related to the goal!
      // Mark it down and update the goal state.
      let numNeeded, overallStatus;
      var goalID;
      const goal = _.find(this.goals, {id: goalID});
      const state = this.goalStates[goalID];
      const stateThangs = state[progressObjectName];
      stateThangs[thangID] = true;
      const success = this.goalIsPositive(goalID);
      if (success) {
        numNeeded = goal.howMany != null ? goal.howMany : Math.max(1, _.size(stateThangs));
      } else {
        // saveThangs: by default we would want to save all the Thangs, which means that we would want none of them to be 'done'
        numNeeded = (_.size(stateThangs) - Math.max((goal.howMany != null ? goal.howMany : 1), _.size(stateThangs))) + 1;
      }
      const numDone = _.filter(stateThangs).length;
      //console.log 'needed', numNeeded, 'done', numDone, 'of total', _.size(stateThangs), 'with how many', goal.howMany, 'and stateThangs', stateThangs, 'for', goalID, thangID, 'on frame', frameNumber, 'all Thangs', _.keys(stateThangs), _.values(stateThangs)
      if (!(numDone >= numNeeded)) { return; }
      if (state.status && !success) { return; }  // already failed it; don't wipe keyframe
      state.status = success ? 'success' : 'failure';
      state.keyFrame = frameNumber;
      //console.log goalID, 'became', success, 'on frame', frameNumber, 'with overallStatus', @checkOverallStatus true
      if (overallStatus = this.checkOverallStatus(true)) {
        const matchedGoals = ((() => {
          const result = [];
          for (goalID in this.goalStates) {
            var goalState = this.goalStates[goalID];
            if (goalState.status === overallStatus) {
              result.push(_.find(this.goals, {id: goalID}));
            }
          }
          return result;
        })());
        const mostEagerGoal = _.min(matchedGoals, 'worldEndsAfter');
        const victory = overallStatus === 'success';
        const tentative = overallStatus === 'success';
        if (mostEagerGoal !== Infinity) { return (this.world != null ? this.world.endWorld(victory, mostEagerGoal.worldEndsAfter, tentative) : undefined); }
      }
    }

    goalIsPositive(goalID) {
      // Positive goals are completed when all conditions are true (kill all these thangs)
      // Negative goals fail when any are true (keep all these thangs from being killed)
      let left;
      const goal = (left = _.find(this.goals, {id: goalID})) != null ? left : {};
      for (var prop in goal) { if (this.positiveGoalMap[prop] === 0) { return false; } }
      return true;
    }

    updateCodeGoalStates() {}
      // TODO

    // teardown

    destroy() {
      return super.destroy();
    }
  };
  GoalManager.initClass();
  return GoalManager;
})());
