/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
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

const LadderTabView = require('./LadderTabView');
const MyMatchesTabView = require('./MyMatchesTabView');
const SimulateTabView = require('./SimulateTabView');
const LadderPlayModal = require('./LadderPlayModal');
const CocoClass = require('core/CocoClass');

const Clan = require('models/Clan');
const CourseInstance = require('models/CourseInstance');
const Course = require('models/Course');

const HIGHEST_SCORE = 1000000;

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
      this.checkForTournamentEnd = this.checkForTournamentEnd.bind(this);
      this.refreshViews = this.refreshViews.bind(this);
      super(...args);
    }

    static initClass() {
      this.prototype.id = 'ladder-view';
      this.prototype.template = require('app/templates/play/ladder/ladder');
      this.prototype.usesSocialMedia = true;
  
      this.prototype.subscriptions =
        {'application:idle-changed': 'onIdleChanged'};
  
      this.prototype.events = {
        'click .play-button': 'onClickPlayButton',
        'click a:not([data-toggle])': 'onClickedLink',
        'click .spectate-button': 'onClickSpectateButton'
      };
  
      this.prototype.onCourseInstanceLoaded = co.wrap(function*(courseInstance) {
        this.courseInstance = courseInstance;
        if (this.destroyed) { return; }
        this.classroomID = this.courseInstance.get('classroomID');
        this.ownerID = this.courseInstance.get('ownerID');
        this.isSchoolAdmin = yield me.isSchoolAdminOf({ classroomId: this.classroomID });
        this.isTeacher = yield me.isTeacherOf({ classroomId: this.classroomID });
        const course = new Course({_id: this.courseInstance.get('courseID')});
        this.course = this.supermodel.loadModel(course).model;
        return this.listenToOnce(this.course, 'sync', this.render);
      });
    }

    initialize(options, levelID, leagueType, leagueID) {
      let tournamentEndDate, tournamentStartDate;
      this.levelID = levelID;
      this.leagueType = leagueType;
      this.leagueID = leagueID;
      super.initialize(options);

      if (features.china && (this.leagueType === 'course') && (this.leagueID === "5cb8403a60778e004634ee6e")) {   //just for china tarena hackthon 2019 classroom RestPoolLeaf
        this.leagueID = (this.leagueType = null);
      }

      if (features.china && (this.levelID === 'magic-rush')) {
        this.checkForTournamentEnd();
      }

      this.level = this.supermodel.loadModel(new Level({_id: this.levelID})).model;
      this.level.once('sync', level => {
        return this.setMeta({ title: $.i18n.t('ladder.arena_title', { arena: level.get('name') }) });
      });

      const onLoaded = () => {
        if (this.destroyed) { return; }
        if (this.level.get('description')) { this.levelDescription = marked(utils.i18n(this.level.attributes, 'description')); }
        return this.teams = teamDataFromLevel(this.level);
      };

      if (this.level.loaded) { onLoaded(); } else { this.level.once('sync', onLoaded); }
      this.sessions = this.supermodel.loadCollection(new LevelSessionsCollection(this.levelID), 'your_sessions', {cache: false}).model;
      this.winners = require('./tournament_results')[this.levelID];

      if (tournamentEndDate = {greed: 1402444800000, 'criss-cross': 1410912000000, 'zero-sum': 1428364800000, 'ace-of-coders': 1444867200000}[this.levelID]) {
        this.tournamentTimeLeft = moment(new Date(tournamentEndDate)).fromNow();
      }
      if (tournamentStartDate = {'zero-sum': 1427472000000, 'ace-of-coders': 1442417400000}[this.levelID]) {
        this.tournamentTimeElapsed = moment(new Date(tournamentStartDate)).fromNow();
      }

      this.displayTabContent = 'display: block';

      this.loadLeague();
      return this.urls = require('core/urls');
    }

    checkForTournamentEnd() {
      if (this.destroyed) { return; }
      if (me.isAdmin()) { return false; }
      return $.get('/db/mandate', data => {
        if (this.destroyed) { return; }
        if (__guard__(data != null ? data[0] : undefined, x => x.currentTournament) !== 'magic-rush') {
          this.tournamentEnd = true;
          return this.displayTabContent = 'display: none';
        } else {
          return setTimeout(this.checkForTournamentEnd, 60 * 1000);
        }
      });
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

    afterRender() {
      let hash;
      super.afterRender();
      if (!this.supermodel.finished()) { return; }
      this.insertSubView(this.ladderTab = new LadderTabView({league: this.league}, this.level, this.sessions));
      this.insertSubView(this.myMatchesTab = new MyMatchesTabView({league: this.league}, this.level, this.sessions));
      this.insertSubView(this.simulateTab = new SimulateTabView({league: this.league, level: this.level, leagueID: this.leagueID}));
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
      if (hash && !(['my-matches', 'simulate', 'ladder', 'prizes', 'rules', 'winners'].includes(hash))) {
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
      this.ladderTab.refreshLadder();
      this.myMatchesTab.refreshMatches(this.refreshDelay);
      return this.simulateTab.refresh();
    }

    onIdleChanged(e) {
      if (!e.idle) { return this.fetchSessionsAndRefreshViews(); }
    }

    onClickPlayButton(e) {
      return this.showPlayModal($(e.target).closest('.play-button').data('team'));
    }

    onClickSpectateButton(e) {
      const humanSession = this.ladderTab.spectateTargets != null ? this.ladderTab.spectateTargets.humans : undefined;
      const ogreSession = this.ladderTab.spectateTargets != null ? this.ladderTab.spectateTargets.ogres : undefined;
      if (!humanSession || !ogreSession) { return; }
      e.preventDefault();
      e.stopImmediatePropagation();
      let url = `/play/spectate/${this.level.get('slug')}?session-one=${humanSession}&session-two=${ogreSession}`;
      if (this.league) { url += '&league=' + this.league.id; }
      if (key.command) { url += '&autoplay=false'; }
      return window.open(url, key.command ? '_blank' : 'spectate');  // New tab for spectating specific matches
    }
      //Backbone.Mediator.publish 'router:navigate', route: url

    showPlayModal(teamID) {
      const session = ((() => {
        const result = [];
        for (var s of Array.from(this.sessions.models)) {           if (s.get('team') === teamID) {
            result.push(s);
          }
        }
        return result;
      })())[0];
      const modal = new LadderPlayModal({league: this.league}, this.level, session, teamID);
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

    destroy() {
      clearInterval(this.refreshInterval);
      return super.destroy();
    }
  };
  LadderView.initClass();
  return LadderView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}