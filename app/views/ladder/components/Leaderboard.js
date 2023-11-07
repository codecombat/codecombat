// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
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
let LeaderboardView;
const LeaderboardComponent = require('./Leaderboard.vue').default;
require('app/styles/play/ladder/new-leaderboard-view.sass');
const CocoView = require('views/core/CocoView');
const Tournament = require('models/Tournament');
const ModelModal = require('views/modal/ModelModal');
const User = require('models/User');
const LevelSession = require('models/LevelSession');
const TournamentSubmission = require('models/TournamentSubmission');
const store = require('core/store');
const silentStore = { commit: _.noop, dispatch: _.noop };
const CocoCollection = require('collections/CocoCollection');
const { LeaderboardData } = require('../LadderTabView');
const utils = require('core/utils');

const HIGHEST_SCORE = 1000000;


module.exports = (LeaderboardView = (function() {
  LeaderboardView = class LeaderboardView extends CocoView {
    static initClass() {
      this.prototype.id = 'new-leaderboard-view';
      this.prototype.template = require('templates/play/ladder/leaderboard-view');
      this.prototype.VueComponent = LeaderboardComponent;
    }

    constructor (options, level, sessions, anonymousPlayerName) {
      super(options)
      this.level = level;
      this.sessions = sessions;
      this.anonymousPlayerName = anonymousPlayerName;
      ({ league: this.league, tournament: this.tournament, leagueType: this.leagueType, course: this.course } = options);
      // params = @collectionParameters(order: -1, scoreOffset: HIGHEST_SCORE, limit: @limit)
      this.tableTitles = [
        {slug: 'creator', col: 0, title: ''},
        {slug: 'language', col: 1, title: ''},
        {slug: 'rank', col: 1, title: $.i18n.t('general.rank')},
        {slug: 'name', col: 3, title: $.i18n.t('general.name')},
        {slug: 'wins', col: 1, title: $.i18n.t('ladder.win_num')},
        {slug: 'losses', col: 1, title: $.i18n.t('ladder.loss_num')},
        {slug: 'win-rate', col: 1, title: $.i18n.t('ladder.win_rate')},
        {slug: 'clan', col: 2, title: $.i18n.t('league.team')},
        {slug: 'age', col: 1, title: $.i18n.t('ladder.age_bracket')},
        {slug: 'country', col:1, title: '🏴‍☠️'}
      ];
      this.propsData = { tableTitles: this.tableTitles, league: this.league, level: this.level, leagueType: this.leagueType, course: this.course, scoreType: 'tournament' };
      if (!this.tournament) {
        this.propsData.tableTitles = [
          {slug: 'creator', col: 0, title: ''},
          {slug: 'language', col: 1, title: ''},
          {slug: 'rank', col: 1, title: ''},
          {slug: 'name', col: 2, title: $.i18n.t('general.name')},
          {slug: 'score', col: 2, title: $.i18n.t('general.score')},
          {slug: 'clan', col: 2, title: $.i18n.t('league.team')},
          {slug: 'age', col: 1, title: $.i18n.t('ladder.age')},
          {slug: 'when', col: 1, title: $.i18n.t('general.when')},
          {slug: 'fight', col: 1, title: ''}
        ];
        this.propsData.scoreType = 'arena';
      }
      this.rankings = [];
      this.myRank = -1;
      this.playerRankings = [];
      this.session = null;
      this.dataObj = { myRank: this.myRank, rankings: this.rankings, session: this.session, playerRankings: this.playerRankings, showContactUs: this.anonymousPlayerName && me.isTeacher() };

      this.refreshLadder();
    }

    render() {
      super.render();
      if (this.leaderboards) {
        this.session = this.leaderboards.session;
        this.myRank = +this.leaderboards.myRank;
        this.rankings = this.mapRankings(this.leaderboards.topPlayers.models);
        this.playerRankings = this.mapRankings(this.nearbySessions());
      }
      this.afterRender();
      return this;
    }

    onLoaded() { return this.render(); }

    afterRender() {
      if (this.vueComponent) {
        this.dataObj.rankings = this.rankings;
        this.dataObj.playerRankings = this.playerRankings;
        this.dataObj.session = this.session;
        this.dataObj.myRank = this.myRank;
        this.$el.find('#new-leaderboard-view').replaceWith(this.vueComponent.$el);
      } else {
        if (this.vuexModule) {
          if (!_.isFunction(this.vuexModule)) {
            throw new Error('@vuexModule should be a function');
          }
          store.registerModule('page', this.vuexModule());
        }

        const dataFunction = () => this.dataObj;
        this.vueComponent = new this.VueComponent({
          el: this.$el.find('new-leaderboard-view')[0],
          propsData: this.propsData,
          data: dataFunction,
          store
        });
        this.vueComponent.$mount();
        this.vueComponent.$on('spectate', data => {
          return this.handleClickSpectateCell(data);
        });
        this.vueComponent.$on('click-player-name', (data, nearby) => {
          return this.handleClickPlayerName(data, nearby);
        });
        this.vueComponent.$on('filter-age', data => {
          return this.handleClickAgeFilter(data);
        });
        this.vueComponent.$on('load-more', data => {
          return this.onClickLoadMore();
        });
        this.vueComponent.$on('temp-unlock', () => {
          this.anonymousPlayerName = false;
          return this.render();
        });
      }

      return super.afterRender(...arguments);
    }

    destroy() {
      if (this.vuexModule) {
        store.unregisterModule('page');
      }
      this.vueComponent.$destroy();
      return this.vueComponent.$store = silentStore;
    }
      // ignore all further changes to the store, since the module has been unregistered.
      // may later want to just ignore mutations and actions to the page module.

    nearbySessions() {
      const nearby = this.leaderboards.nearbySessions();
      if (!nearby.length) { return []; }
      if (nearby[0].rank > (this.rankings.length + 1)) {
        return [{type: 'BLANK_ROW'}].concat(nearby);
      } else {
        const delta = (this.rankings.length - nearby[0].rank) + 1;
        return nearby.slice(delta);
      }
    }

    mapFullName(fullName) {
      fullName = fullName != null ? fullName.replace(/^Anonymous/, $.i18n.t('general.player')) : undefined;
      fullName = fullName != null ? fullName.replace(/^AIAlgorithm_(.+)_$/, '$1') : undefined;
      fullName = fullName != null ? fullName.replace(/^AIYouth_(.+)_$/, '$1') : undefined;
      return fullName;
    }

    mapRankings(data ) {
      return _.map(data, (model, index) => {
        if ((model != null ? model.type : undefined) === 'BLANK_ROW') {
          return model;
        }
        if (this.tournament) {
          let left, left1;
          const isMyLevelSession = (model.get('creator') === me.id) && (model.constructor.name === 'LevelSession');
          const wins = (left = model.get('wins')) != null ? left : (isMyLevelSession ? model.myWins : 0);
          const losses = (left1 = model.get('losses')) != null ? left1 : (isMyLevelSession ? model.myLosses : 0);
          return [
            model.get('creator'),
            model.get('submittedCodeLanguage'),
            model.rank != null ? model.rank : index+1,
            this.mapFullName(model.get('fullName') || model.get('creatorName') || $.i18n.t("play.anonymous")),
            wins,
            losses,
            (((wins || 0) / (((wins || 0) + (losses || 0)) || 1)) * 100).toFixed(2) + '%',
            this.getClanName(model),
            this.getAgeBracket(model),
            model.get('creatorCountryCode')
          ];
        } else {
          return [
            model.get('creator'),
            model.get('submittedCodeLanguage'),
            model.rank || (index+1),
            this.mapFullName((model.get('fullName')) || model.get('creatorName') || $.i18n.t("play.anonymous")),
            this.correctScore(model),
            this.getClanName(model),
            this.getAgeBracket(model),
            moment(model.get('submitDate')).fromNow().replace('a few ', ''),
            model.get('_id')
          ];
        }
    });
    }

    refreshLadder(force) {
      let oldLeaderboard;
      if (!force && !this.league && ((new Date() - (2*60*1000)) < this.lastRefreshTime)) { return; }
      this.lastRefreshTime = new Date();

      this.supermodel.resetProgress();
      if (this.ladderLimit == null) { this.ladderLimit = parseInt(utils.getQueryVariable('top_players', 100)); }
      if (this.ageBracket == null) { this.ageBracket = null; }
      if (oldLeaderboard = this.leaderboards) {
        this.supermodel.removeModelResource(oldLeaderboard);
        oldLeaderboard.destroy();
      }

      const teamSession = _.find(this.sessions.models, session => session.get('team') === 'humans');
      this.leaderboards = new LeaderboardData(this.level, 'humans', teamSession, this.ladderLimit, this.league, this.tournament, this.ageBracket, this.options.myTournamentSubmission);
      this.leaderboardRes = this.supermodel.addModelResource(this.leaderboards, 'leaderboard', {cache: false}, 3);
      return this.leaderboardRes.load();
    }

    onClickLoadMore() {
      if (this.ladderLimit == null) { this.ladderLimit = 100; }
      this.ladderLimit += 100;
      this.lastRefreshTime = null;
      return this.refreshLadder(true);
    }

    handleClickSpectateCell(data) {
      let lkey, rank;
      if (data.length !== 2) { return; }
      if (this.spectateTargets == null) { this.spectateTargets = {}; }
      const leaderboards= {top: this.leaderboards.topPlayers.models, nearby: this.nearbySessions()};
      if (this.tournament) {
        [rank, lkey] = Array.from(data[0].split('-'));
        this.spectateTargets.humans = leaderboards[lkey][+rank].get('levelSession');
        [rank, lkey] = Array.from(data[1].split('-'));
        return this.spectateTargets.ogres = leaderboards[lkey][+rank].get('levelSession');
      } else {
        [rank, lkey] = Array.from(data[0].split('-'));
        this.spectateTargets.humans = leaderboards[lkey][+rank].get('_id');
        [rank, lkey] = Array.from(data[1].split('-'));
        return this.spectateTargets.ogres = leaderboards[lkey][+rank].get('_id');
      }
    }

    handleClickPlayerName(id, nearby) {
      if (me.isAdmin()) {
        const leaderboards = nearby ? this.nearbySessions() : this.leaderboards.topPlayers.models;
        const sessionId = this.tournament ? leaderboards[id].get('levelSession') : leaderboards[id].get('_id');
        const session = new LevelSession({_id: sessionId});
        this.supermodel.loadModel(session);
        return this.listenToOnce(session, 'sync', _session => {
          const models = [_session];
          if (!__guard__(_session.get('source'), x => x.name)) {
            const playerId = this.tournament ? leaderboards[id].get('owner') : leaderboards[id].get('creator');
            models.push(new User({_id: playerId}));
          }
          if (this.tournament) {
            models.push(new TournamentSubmission({_id: leaderboards[id].get('_id')}));
          }
          return this.openModalView(new ModelModal({models}));
        });
      } else if (me.isTeacher()) {
        // TODO
      } else {
        // TODO
      }
    }


    handleClickAgeFilter(ageBracket) {
      this.ageBracket = ageBracket;
      if (me.showChinaResourceInfo() && (ageBracket === '11-14')) {
        this.ageBracket = '11-18';
      }
      return this.refreshLadder(true);
    }

    getClanName(model) {
      let left, left1, left2;
      const firstClan = (left = ((left1 = model.get('creatorClans')) != null ? left1 : [])[0]) != null ? left : {};
      let name = (left2 = firstClan.displayName != null ? firstClan.displayName : firstClan.name) != null ? left2 : "";
      if (!/[a-z]/.test(name)) {
        name = utils.titleize(name);  // Convert any all-uppercase clan names to title-case
      }
      return name;
    }

    getAgeBracket(model) {
      return $.i18n.t(`ladder.bracket_${(model.get('ageBracket') || model.ageBracket || 'open').replace(/-/g, '_')}`);
    }

    correctScore(model) {
      const sessionStats = this.league ? __guard__(_.find(model.get('leagues'), {leagueID: this.league.id}), x => x.stats) : model.attributes;
      return (((sessionStats != null ? sessionStats.totalScore : undefined) || (model.get('totalScore')/2)) * 100) | 0;
    }
  };
  LeaderboardView.initClass();
  return LeaderboardView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}