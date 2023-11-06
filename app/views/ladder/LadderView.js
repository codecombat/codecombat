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
let LadderView;
require('app/styles/play/ladder/ladder.sass');
const RootView = require('views/core/RootView');
const Level = require('models/Level');
const LevelSession = require('models/LevelSession');
const CocoCollection = require('collections/CocoCollection');
const {teamDataFromLevel} = require('./utils');
const {me} = require('core/auth');
// application = require 'core/application'
const co = require('co');
const utils = require('core/utils');
const {joinClan} = require('core/api/clans');
const {publishTournament} = require('core/api/tournaments');

const LadderTabView = require('./LadderTabView');
const MyMatchesTabView = require('./MyMatchesTabView');
const SimulateTabView = require('./SimulateTabView');
const LadderPlayModal = require('./LadderPlayModal');
const CocoClass = require('core/CocoClass');
const TournamentLeaderboard = require('./components/Leaderboard');

const Clan = require('models/Clan');
const CourseInstance = require('models/CourseInstance');
const Course = require('models/Course');
const Mandate = require('models/Mandate');
const Tournament = require('models/Tournament');
const TournamentSubmission = require('models/TournamentSubmission');
const userClassroomHelper = require('../../lib/user-classroom-helper');

const HIGHEST_SCORE = 1000000;

const STOP_CHECK_TOURNAMENT_CLOSE = 0;  // tournament ended
const KEEP_CHECK_TOURNAMENT_CLOSE = 1;  // tournament not begin
const STOP_CHECK_TOURNAMENT_OPEN = 2;  // none tournament only level
const KEEP_CHECK_TOURNAMENT_OPEN = 3;  // tournament running

const TOURNAMENT_OPEN = [2, 3];
const STOP_CHECK_TOURNAMENT = [0, 2];

class LevelSessionsCollection extends CocoCollection {
  static initClass() {
    this.prototype.url = '';
    this.prototype.model = LevelSession;
  }

  constructor(levelID) {
    super();
    this.url = `/db/level/${levelID}/my_sessions`;
  }
}
LevelSessionsCollection.initClass();

module.exports = (LadderView = (function() {
  LadderView = class LadderView extends RootView {
    constructor(...args) {
      super(...args);
      this.refreshViews = this.refreshViews.bind(this);

      let tournamentEndDate, tournamentStartDate;
      this.level = this.supermodel.loadModel(new Level({_id: this.levelID})).model;
      this.level.once('sync', level => {
        return this.setMeta({ title: $.i18n.t('ladder.arena_title', { arena: level.get('name') }) });
      });

      const onLoaded = () => {
        if (this.destroyed) { return; }
        if (this.level.get('description')) { this.levelDescription = marked(utils.i18n(this.level.attributes, 'description')).replace(/<img.*?>/, ''); }
        this.levelBanner = this.level.get('banner');
        return this.teams = teamDataFromLevel(this.level);
      };

      if (this.level.loaded) { onLoaded(); } else { this.level.once('sync', onLoaded); }
      this.sessions = this.supermodel.loadCollection(new LevelSessionsCollection(this.levelID), 'your_sessions', {cache: false}).model;
      this.listenToOnce(this.sessions, 'sync', this.onSessionsLoaded);
      this.winners = require('./tournament_results')[this.levelID];

      if (tournamentEndDate = {greed: 1402444800000, 'criss-cross': 1410912000000, 'zero-sum': 1428364800000, 'ace-of-coders': 1444867200000, 'battle-of-red-cliffs': 1598918400000}[this.levelID]) {
        this.tournamentTimeLeftString = moment(new Date(tournamentEndDate)).fromNow();
      }
      if (tournamentStartDate = {'zero-sum': 1427472000000, 'ace-of-coders': 1442417400000, 'battle-of-red-cliffs': 1596295800000}[this.levelID]) {
        this.tournamentTimeElapsedString = moment(new Date(tournamentStartDate)).fromNow();
      }

      this.calcTimeOffset();
      this.mandate = this.supermodel.loadModel(new Mandate()).model;

      this.tournamentId = utils.getQueryVariable('tournament');
      if (this.tournamentId) {
        const url = `/db/tournament/${this.tournamentId}/submission`;
        this.myTournamentSubmission = new TournamentSubmission().setURL(url);
        this.supermodel.loadModel(this.myTournamentSubmission);
      }

      // TODO: query for matching tournaments for the level and show tournaments list to click into results
      this.loadLeague();
      this.urls = require('core/urls');

      if (this.leagueType === 'clan') {
        utils.getAnonymizationStatus(this.leagueID, this.supermodel).then(anonymous => {
          return this.anonymousPlayerName = anonymous;
        });
      }

      if (this.tournamentId) {
        this.checkTournamentCloseInterval = setInterval(this.checkTournamentClose.bind(this), 3000);
        return this.checkTournamentClose();
      }
    }

    static initClass() {
      this.prototype.id = 'ladder-view';
      this.prototype.template = require('app/templates/play/ladder/ladder');
      this.prototype.usesSocialMedia = true;
      this.prototype.showBackground = false;

      this.prototype.subscriptions =
        {'application:idle-changed': 'onIdleChanged'};

      this.prototype.events = {
        'click .play-button': 'onClickPlayButton',
        'click a:not([data-toggle])': 'onClickedLink',
        'click .publish-button': 'onClickPublishButton',
        'click .spectate-button': 'onClickSpectateButton',
        'click .simulate-all-button': 'onClickSimulateAllButton',
        'click .early-results-button': 'onClickEarlyResultsButton',
        'click .join-clan-button': 'onClickJoinClanButton'
      };

      this.prototype.onCourseInstanceLoaded = co.wrap(function*(courseInstance) {
        this.courseInstance = courseInstance;
        if (this.destroyed) { return; }
        this.classroomID = this.courseInstance.get('classroomID');
        this.ownerID = this.courseInstance.get('ownerID');
        this.isSchoolAdmin = yield userClassroomHelper.isSchoolAdminOf({ user: me, classroomId: this.classroomID });
        this.isTeacher = yield userClassroomHelper.isTeacherOf({ user: me, classroomId: this.classroomID });
        const course = new Course({_id: this.courseInstance.get('courseID')});
        this.course = this.supermodel.loadModel(course).model;
        return this.listenToOnce(this.course, 'sync', this.render);
      });

      this.prototype.teamOffers = [
        {slug: 'hyperx', clanId: '60a4378875b540004c78f121', name: 'Team HyperX', clanSlug: 'hyperx'},
        {slug: 'derbezt', clanId: '601351bb4b79b4013e198fbe', name: 'Team DerBezt', clanSlug: 'team-derbezt'}
      ];
    }

    initialize(options, levelID, leagueType, leagueID) {
      this.levelID = levelID;
      this.leagueType = leagueType;
      this.leagueID = leagueID;
      super.initialize(options);
    }

    calcTimeOffset() {
      return $.ajax({
        type: 'HEAD',
        success: (result, status, xhr) => {
          return this.timeOffset = new Date(xhr.getResponseHeader("Date")).getTime() - Date.now();
        }
      });
    }

    onSessionsLoaded(e) {
      return (() => {
        const result = [];
        for (var session of Array.from(this.sessions.models)) {
          if (_.isEmpty(session.get('code'))) {
            result.push(session.set('code', session.get('submittedCode')));
          } else {
            result.push(undefined);
          }
        }
        return result;
      })();
    }

    getTournamentState(mandate, courseInstanceID, levelSlug, timeOffset) {
      const tournament = _.find(mandate.currentTournament || [], t => (t.courseInstanceID === courseInstanceID) && (t.level === levelSlug));
      if (tournament) {
        let delta;
        const currentTime = (Date.now() + timeOffset) / 1000;
        console.log("Current time:", new Date(currentTime * 1000));
        if (currentTime < tournament.startAt) {
          delta = tournament.startAt - currentTime;
          console.log(`Tournament will start at: ${new Date(tournament.startAt * 1000)}, Time left: ${parseInt(delta / 60 / 60) }:${parseInt(delta / 60) % 60}:${parseInt(delta) % 60}`);
          return KEEP_CHECK_TOURNAMENT_CLOSE;
        } else if (currentTime > tournament.endAt) {
          console.log(`Tournament ended at: ${new Date(tournament.endAt * 1000)}`);
          return STOP_CHECK_TOURNAMENT_CLOSE;
        }
        delta = tournament.endAt - currentTime;
        console.log(`Tournament will end at: ${new Date(tournament.endAt * 1000)}, Time left: ${parseInt(delta / 60 / 60) }:${parseInt(delta / 60) % 60}:${parseInt(delta) % 60}`);
        return KEEP_CHECK_TOURNAMENT_OPEN;
      } else {
        if (Array.from(mandate.tournamentOnlyLevels || []).includes(levelSlug)) { return STOP_CHECK_TOURNAMENT_CLOSE; } else { return STOP_CHECK_TOURNAMENT_OPEN; }
      }
    }

    getMeta() {
      return {
        title: $.i18n.t('ladder.title'),
        link: [
          { vmid: 'rel-canonical', rel: 'canonical', content: '/play' }
        ]
      };
    }

    loadLeague() {
      if (!['clan', 'course'].includes(this.leagueType)) { this.leagueID = (this.leagueType = null); }
      if (!this.leagueID) { return; }

      const modelClass = this.leagueType === 'clan' ? Clan : CourseInstance;
      this.league = this.supermodel.loadModel(new modelClass({_id: this.leagueID})).model;
      if (this.leagueType === 'course') {
        if (this.league.loaded) {
          return this.onCourseInstanceLoaded(this.league);
        } else {
          return this.listenToOnce(this.league, 'sync', this.onCourseInstanceLoaded);
        }
      }
    }

    checkTournamentClose() {
      if (this.tournamentId == null) { return; }
      return $.ajax({
        url: `/db/tournament/${this.tournamentId}/state`,
        success: res => {
          let newInterval;
          this.tournament = new Tournament(res);
          if (me.isAdmin() && (document.location.hash === '#results')) {
            // Show the results early, before publish date
            this.tournament.set('resultsDate', this.tournament.get('endDate'));
            this.tournament.set('state', 'ended');
          }
          if (this.tournament.get('endDate')) {
            if (this.tournamentTimeRefreshInterval) { clearInterval(this.tournamentTimeRefreshInterval); }
            this.tournamentTimeRefreshInterval = setInterval(this.refreshTournamentTime.bind(this), 1000);
            this.refreshTournamentTime();
          }

          if (this.tournament.get('state') === 'initializing') {
            this.tournamentEnd = true;
            newInterval = this.tournamentTimeElapsed < (-10 * 1000) ? Math.min(10 * 60 * 1000, -this.tournamentTimeElapsed / 2) : 1000;
          } else if (this.tournament.get('state') === 'starting') {
            this.tournamentEnd = false;
            newInterval = this.tournamentTimeLeft > (10 * 1000) ? Math.min(10 * 60 * 1000, this.tournamentTimeLeft / 2) : 1000;
          } else if (['ranking', 'waiting'].includes(this.tournament.get('state'))) {
            this.tournamentEnd = true;
            newInterval = this.tournamentResultsTimeLeft > (10 * 1000) ? Math.min(10 * 60 * 1000, this.tournamentResultsTimeLeft / 2) : 1000;
          } else if (this.tournament.get('state') === 'ended') {
            this.tournamentEnd = true;
          }

          if (this.tournamentState !== this.tournament.get('state')) {
            this.tournamentState = this.tournament.get('state');
            this.render();
          }

          if (this.checkTournamentCloseInterval) { clearInterval(this.checkTournamentCloseInterval); }
          if (newInterval) { return this.checkTournamentCloseInterval = setInterval(this.checkTournamentClose.bind(this), newInterval); }
        }
      });
    }

    refreshTournamentTime() {
      if (!(this.tournament != null ? this.tournament.get('endDate') : undefined)) { return; }
      const resultsDate = this.tournament.get('resultsDate') || this.tournament.get('endDate');
      const currentTime = Date.now() + (this.timeOffset != null ? this.timeOffset : 0);
      this.tournamentTimeElapsed = currentTime - new Date(this.tournament.get('startDate'));
      this.tournamentTimeLeft = new Date(this.tournament.get('endDate')) - currentTime;
      this.tournamentResultsTimeLeft = new Date(resultsDate) - currentTime;
      const tournamentStartDate = new Date(currentTime - this.tournamentTimeElapsed);
      const tournamentEndDate = new Date(currentTime + this.tournamentTimeLeft);
      const tournamentResultsDate = new Date(currentTime + this.tournamentResultsTimeLeft);
      this.tournamentTimeElapsedString = moment(tournamentStartDate).fromNow();
      this.tournamentTimeLeftString = moment(tournamentEndDate).fromNow();
      this.tournamentResultsTimeLeftString = moment(tournamentResultsDate).fromNow();
      this.$('#tournament-time-elapsed').text(this.tournamentTimeElapsedString);
      this.$('#tournament-time-left').text(this.tournamentTimeLeftString);
      return this.$('#tournament-results-time-left').text(this.tournamentResultsTimeLeftString);
    }

    afterRender() {
      let hash;
      super.afterRender();
      if (!this.supermodel.finished()) { return; }
      this.$el.toggleClass('single-ladder', this.level.isType('ladder'));
      // tournamentState condition
      // starting - show leaderboard && mymatches
      // unset - leaderboard && mymatches
      // unset and non-ladder - old leadearbod && mymatches
      //
      // initializing, ranking, waiting - nothing
      // waiting for owner - only leaderboard
      // ended - only leaderboard
      if ((this.tournamentState === 'ended') || ((this.tournamentState === 'waiting') && (me.get('_id') === (this.league != null ? this.league.get('ownerID') : undefined)))) {
        this.insertSubView(this.ladderTab = new TournamentLeaderboard({league: this.league, tournament: this.tournamentId, leagueType: 'clan', myTournamentSubmission: this.myTournamentSubmission}, this.level, this.sessions )); // classroom ladder do not have tournament for now
      } else if (['initializing', 'ranking', 'waiting'].includes(this.tournamentState)) {
        null;
      } else { // starting, or unset
        if (this.level.isType('ladder')) {
          this.insertSubView(this.ladderTab = new TournamentLeaderboard({league: this.league, leagueType: this.leagueType, course: this.course, myTournamentSubmission: this.myTournamentSubmission}, this.level, this.sessions, this.anonymousPlayerName ));
        } else {
          this.insertSubView(this.ladderTab = new LadderTabView({league: this.league, tournament: this.tournamentId}, this.level, this.sessions));
        }
        this.insertSubView(this.myMatchesTab = new MyMatchesTabView({league: this.league, leagueType: this.leagueType, course: this.course}, this.level, this.sessions));
      }
      this.renderSelectors('#ladder-action-columns');
      if (!this.level.isType('ladder') || !me.isAnonymous()) {
        this.insertSubView(this.simulateTab = new SimulateTabView({league: this.league, level: this.level, leagueID: this.leagueID}));
      }
      const highLoad = true;
      this.refreshDelay = (() => { switch (false) {
        case !!application.isProduction(): return 10;  // Refresh very quickly in develompent.
        case !this.league: return 20;                         // Refresh quickly when looking at a league ladder.
        case !!highLoad: return 30;                    // Refresh slowly when in production.
        case !!me.isAnonymous(): return 60;            // Refresh even more slowly during HoC scaling.
        default: return 300;                                     // Refresh super slowly if anonymous during HoC scaling.
      } })();
      this.refreshInterval = setInterval(this.fetchSessionsAndRefreshViews.bind(this), this.refreshDelay * 1000);
      if (document.location.hash) { hash = document.location.hash.slice(1); }
      if ((['humans', 'ogres'].includes(hash)) && !window.currentModal) {
        if (this.sessions.loaded) { return this.showPlayModal(hash); }
      }
    }

    fetchSessionsAndRefreshViews() {
      if (this.destroyed || application.userIsIdle || ((new Date() - 2000) < this.lastRefreshTime) || !this.supermodel.finished()) { return; }
      return this.sessions.fetch({success: this.refreshViews, cache: false});
    }

    refreshViews() {
      if (this.destroyed || application.userIsIdle) { return; }
      this.lastRefreshTime = new Date();
      if (this.ladderTab != null) {
        this.ladderTab.refreshLadder();
      }
      if ((this.myMatchesTab != null ? this.myMatchesTab.refreshMatches : undefined) != null) {
        this.myMatchesTab.refreshMatches(this.refreshDelay);
      }
      return (this.simulateTab != null ? this.simulateTab.refresh() : undefined);
    }

    onIdleChanged(e) {
      if (!e.idle) { return this.fetchSessionsAndRefreshViews(); }
    }

    onClickPlayButton(e) {
      return this.showPlayModal($(e.target).closest('.play-button').data('team'));
    }

    onClickPublishButton(e) {
      if (!this.tournamentId || (this.tournamentState !== 'waiting') || (me.get('_id') !== (this.league != null ? this.league.get('ownerID') : undefined))) { return; }

      return publishTournament({id: this.tournamentId}).then(res => {
          return window.location.href = window.location.href;
      }).catch(err => {
        return alert('tournament results publish failed');
      });
    }

    onClickSpectateButton(e) {
      e.preventDefault();
      e.stopImmediatePropagation();
      const humanSession = this.ladderTab.spectateTargets != null ? this.ladderTab.spectateTargets.humans : undefined;
      const ogreSession = this.ladderTab.spectateTargets != null ? this.ladderTab.spectateTargets.ogres : undefined;
      let url = `/play/spectate/${this.level.get('slug')}?`;
      if (humanSession && ogreSession) { url += `session-one=${humanSession}&session-two=${ogreSession}`; }
      if (this.league) { url += '&league=' + this.league.id; }
      if (key.command) { url += '&autoplay=false'; }
      if (this.tournamentState === 'ended') { url += '&tournament=' + this.tournamentId; }
      return window.open(url, key.command ? '_blank' : 'spectate');  // New tab for spectating specific matches
    }
      //Backbone.Mediator.publish 'router:navigate', route: url

    onClickSimulateAllButton(e) {
      if (this.tournamentId) {
        let options;
        if (key.shift) {
          // TODO: make this configurable
          options = {
            sessionLimit: 50000,
            matchLimit: 2e6,
            matchmakingType: 'king-of-the-hill',
            minPlayerMatches: 40,
            topN: 10
          };
        } else {
          options = {};
        }
        return $.ajax({
          url: `/db/tournament/${this.tournamentId}/end`,
          data: options,
          type: 'POST',
          success(res) {
            return console.log(res);
          },
          error(err) {
            return alert('tournament end failed');
          }
        });
      } else {
        let left;
        return $.ajax({
          url: '/queue/scoring/loadTournamentSimulationTasks',
          data: {
            originalLevelID: this.level.get('original'),
            levelMajorVersion: 0,
            leagueID: this.leagueID,
            mirrorMatch: (left = this.level.get('mirrorMatch')) != null ? left : false,
            sessionLimit: 750
          },
          type: 'POST',
          parse: true,
          success(res){
            return console.log(res);
          },
          error(err) {
            return console.error(err);
          }
        });
      }
    }

    onClickEarlyResultsButton(e) {
      return this.checkTournamentClose();
    }

    showPlayModal(teamID) {
      const session = ((() => {
        const result = [];
        for (var s of Array.from(this.sessions.models)) {           if (s.get('team') === teamID) {
            result.push(s);
          }
        }
        return result;
      })())[0];
      const modal = new LadderPlayModal({league: this.league, leagueType: this.leagueType, tournament: this.tournamentId, course: this.course}, this.level, session, teamID);
      return this.openModalView(modal);
    }

    onClickedLink(e) {
      const link = $(e.target).closest('a').attr('href');
      if (link && /#rules$/.test(link)) {
        this.$el.find('a[href="#rules"]').tab('show');
      }
      if (link && /#prizes/.test(link)) {
        this.$el.find('a[href="#prizes"]').tab('show');
      }
      if (link && /#winners/.test(link)) {
        return this.$el.find('a[href="#winners"]').tab('show');
      }
    }

    onClickJoinClanButton(e) {
      if (me.isAnonymous()) { return; }  // Just follow the link
      e.preventDefault();
      e.stopImmediatePropagation();
      const clanId = $(e.target).closest('a').data('clan-id');
      const href = $(e.target).closest('a').attr('href');
      $(e.target).text($.i18n.t('common.loading'));
      return joinClan(clanId).then(() => document.location.href = href);
    }

    isAILeagueArena() { return _.find(utils.arenas, {slug: this.levelID}); }

    destroy() {
      clearInterval(this.refreshInterval);
      if (this.tournamentTimeRefreshInterval) {
        clearInterval(this.tournamentTimeRefreshInterval);
      }
      if (this.checkTournamentCloseInterval) {
        clearInterval(this.checkTournamentCloseInterval);
      }
      return super.destroy();
    }
  };
  LadderView.initClass();
  return LadderView;
})());
