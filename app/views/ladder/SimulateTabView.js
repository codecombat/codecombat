// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SimulateTabView;
const CocoView = require('views/core/CocoView');
const CocoClass = require('core/CocoClass');
const SimulatorsLeaderboardCollection = require('collections/SimulatorsLeaderboardCollection');
const Simulator = require('lib/simulator/Simulator');
const {me} = require('core/auth');
const utils = require('core/utils');
const loadAetherLanguage = require("lib/loadAetherLanguage");

module.exports = (SimulateTabView = (function() {
  SimulateTabView = class SimulateTabView extends CocoView {
    static initClass() {
      this.prototype.id = 'simulate-tab-view';
      this.prototype.template = require('app/templates/play/ladder/simulate_tab')

      this.prototype.events =
        {'click #simulate-button': 'onSimulateButtonClick'};
    }

    constructor (options) {
      if (!options) {
        options = {}
      }
      super(options)
      this.options = options
      this.refreshAndContinueSimulating = this.refreshAndContinueSimulating.bind(this)
      this.simulatedByYouCount = me.get('simulatedBy') || 0
      this.simulatorsLeaderboardData = new SimulatorsLeaderboardData(me, this.options.level)
      this.simulatorsLeaderboardDataRes = this.supermodel.addModelResource(this.simulatorsLeaderboardData, 'top_simulators', { cache: false })
      this.simulatorsLeaderboardDataRes.load()
      Promise.all(
        ["javascript", "python", "coffeescript", "lua", "cpp", "java"].map(
          loadAetherLanguage
        )
      );
    }

    onLoaded() {
      let needle;
      super.onLoaded();
      this.autoSimulates = (utils.getQueryVariable('simulate') !== false) && (needle = this.options.level.get('slug'), !['ace-of-coders', 'zero-sum'].includes(needle));
      if (!this.simulator && ((document.location.hash === '#simulate') || this.autoSimulates)) {
        return this.startSimulating();
      }
    }

    afterRender() {
      return super.afterRender();
    }

    // Simulations

    onSimulateButtonClick(e) {
      if (application.tracker != null) {
        application.tracker.trackEvent('Simulate Button Click');
      }
      document.location.hash = '#simulate';
      return this.startSimulating();
    }

    startSimulating() {
      this.simulationPageRefreshTimeout = _.delay(this.refreshAndContinueSimulating, 10 * 60 * 1000);
      this.simulateNextGame();
      $('#simulate-button').prop('disabled', true);
      return $('#simulate-button').text('Simulating...');
    }

    refreshAndContinueSimulating() {
      // We refresh the page every now and again to make sure simulations haven't gotten derailed by bogus games, and that simulators don't hang on to old, stale code or data.
      if (!this.autoSimulates) { document.location.hash = '#simulate'; }
      return document.location.reload();
    }

    simulateNextGame() {
      if (!this.simulator) {
        this.simulator = new Simulator({levelID: this.options.level.get('slug'), leagueID: this.options.leagueID, singleLadder: this.options.level.isType('ladder'), levelOriginal: this.options.level.get('original')});
        this.listenTo(this.simulator, 'statusUpdate', this.updateSimulationStatus);
        // Work around simulator getting super slow on Chrome
        const fetchAndSimulateTaskOriginal = this.simulator.fetchAndSimulateTask;
        this.simulator.fetchAndSimulateTask = () => {
          if (this.destroyed) { return; }
          if (this.simulator.simulatedByYou >= 100) {
            console.log('------------------- Destroying  Simulator and making a new one -----------------');
            this.simulator.destroy();
            this.simulator = null;
            return this.simulateNextGame();
          } else {
            return fetchAndSimulateTaskOriginal.apply(this.simulator);
          }
        };
      }
      return this.simulator.fetchAndSimulateTask();
    }

    refresh() {
      if (!(this.simulatorsLeaderboardData.numberOfGamesInQueue > 0)) { return; }  // Queue-based scoring is currently not active anyway, so don't keep checking this until we fix it.
      const success = numberOfGamesInQueue => {
        if (this.destroyed) { return; }
        this.simulatorsLeaderboardData.numberOfGamesInQueue = numberOfGamesInQueue;
        return $('#games-in-queue').text(numberOfGamesInQueue);
      };
      return $.ajax('/db/level/-/ladder-match-queue-count', {cache: false, success});
    }

    updateSimulationStatus(simulationStatus, sessions) {
      if (simulationStatus === 'Fetching simulation data!') {
        this.simulationMatchDescription = '';
        this.simulationSpectateLink = '';
      }
      this.simulationStatus = _.string.escapeHTML(simulationStatus);
      try {
        if (sessions != null) {
          this.simulationMatchDescription = '';
          this.simulationSpectateLink = `/play/spectate/${this.simulator.level.get('slug')}?`;
          for (let index = 0; index < sessions.length; index++) {
            // TODO: Fetch names from Redis, the creatorName is denormalized
            var session = sessions[index];
            this.simulationMatchDescription += `${index ? ' vs ' : ''}${session.creatorName || 'Anonymous'} (${sessions[index].team})`;
            this.simulationSpectateLink += `session-${index ? 'two' : 'one'}=${session.sessionID}`;
          }
          this.simulationMatchDescription += ` on ${this.simulator.level.get('name')}`;
        }
      } catch (e) {
        console.log(`There was a problem with the named simulation status: ${e}`);
      }
      const link = this.simulationSpectateLink ? `<a href=${this.simulationSpectateLink}>${_.string.escapeHTML(this.simulationMatchDescription)}</a>` : '';
      $('#simulation-status-text').html(`<strong>${this.simulationStatus}</strong>${link}`);
      if (simulationStatus === 'Results were successfully sent back to server!') {
        const gamesInQueue = Math.max(0, --this.simulatorsLeaderboardData.numberOfGamesInQueue);
        $('#games-in-queue').text(gamesInQueue.toLocaleString());
        return $('#simulated-by-you').text((++this.simulatedByYouCount).toLocaleString());
      }
    }


    destroy() {
      clearTimeout(this.simulationPageRefreshTimeout);
      if (this.simulator != null) {
        this.simulator.destroy();
      }
      return super.destroy();
    }
  };
  SimulateTabView.initClass();
  return SimulateTabView;
})());

class SimulatorsLeaderboardData extends CocoClass {
  /*
  Consolidates what you need to load for a leaderboard into a single Backbone Model-like object.
  */

  constructor(me1, level) {
    super();
    this.onLoad = this.onLoad.bind(this);
    this.onFail = this.onFail.bind(this);
    this.me = me1;
    this.level = level;
  }

  fetch() {
    const promises = [];
    if (!this.me.get('anonymous')) {
      const queueSuccess = numberOfGamesInQueue => {
        this.numberOfGamesInQueue = numberOfGamesInQueue;
      };
      promises.push($.ajax('/db/level/-/ladder-match-queue-count', {success: queueSuccess, cache: false}));
    }
    if (!this.level.isType('ladder')) {
      this.topSimulators = new SimulatorsLeaderboardCollection({order: -1, scoreOffset: -1, limit: 20});
      promises.push(this.topSimulators.fetch());
      const score = this.me.get('simulatedBy') || 0;
      this.playersAbove = new SimulatorsLeaderboardCollection({order: 1, scoreOffset: score, limit: 4});
      promises.push(this.playersAbove.fetch());
      if (score) {
        this.playersBelow = new SimulatorsLeaderboardCollection({order: -1, scoreOffset: score, limit: 4});
        promises.push(this.playersBelow.fetch());
      }
      const success = myRank => {
        this.myRank = myRank;
      };
      promises.push($.ajax(`/db/user/me/simulator_leaderboard_rank?scoreOffset=${score}`, {cache: false, success}));
    }

    this.promise = $.when(...Array.from(promises || []));
    this.promise.then(this.onLoad);
    this.promise.fail(this.onFail);
    return this.promise;
  }

  onLoad() {
    if (this.destroyed) { return; }
    this.loaded = true;
    return this.trigger('sync', this);
  }

  onFail(resource, jqxhr) {
    if (this.destroyed) { return; }
    return this.trigger('error', this, jqxhr);
  }

  inTopSimulators() {
    let needle;
    return (needle = me.id, Array.from((Array.from(this.topSimulators.models).map((user) => user.id))).includes(needle));
  }

  nearbySimulators() {
    if (!(this.playersAbove != null ? this.playersAbove.models : undefined)) { return []; }
    let l = [];
    const above = this.playersAbove.models;
    l = l.concat(above);
    l.reverse();
    l.push(this.me);
    if (this.playersBelow) { l = l.concat(this.playersBelow.models); }
    if (this.myRank) {
      const startRank = this.myRank - 4;
      for (let i = 0; i < l.length; i++) { var user = l[i]; user.rank = startRank + i; }
    }
    return l;
  }

  allResources() {
    const resources = [this.topSimulators, this.playersAbove, this.playersBelow];
    return (Array.from(resources).filter((r) => r));
  }
}
