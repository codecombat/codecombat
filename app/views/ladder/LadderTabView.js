// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LadderTabView, LeaderboardData;
require('app/styles/play/ladder/ladder-tab-view.sass');
const CocoView = require('views/core/CocoView');
const CocoClass = require('core/CocoClass');
const Level = require('models/Level');
const LevelSession = require('models/LevelSession');
const CocoCollection = require('collections/CocoCollection');
const User = require('models/User');
const TournamentSubmission = require('models/TournamentSubmission');
const LeaderboardCollection  = require('collections/LeaderboardCollection');
const {teamDataFromLevel, scoreForDisplay} = require('./utils');
const ModelModal = require('views/modal/ModelModal');
require('d3/d3.js');
const CreateAccountModal = require('views/core/CreateAccountModal');
const utils = require('core/utils');

const HIGHEST_SCORE = 1000000;

class TournamentLeaderboardCollection extends CocoCollection {
  static initClass() {
    this.prototype.url = '';
    this.prototype.model = TournamentSubmission;
  }

  constructor(tournamentId, options) {
    super();
    this.url = `/db/tournament/${tournamentId}/rankings?${$.param(options)}`;
  }
}
TournamentLeaderboardCollection.initClass();

module.exports = (LadderTabView = (function() {
  LadderTabView = class LadderTabView extends CocoView {
    constructor(...args) {
      super(...args);
      this.onFacebookFriendsLoaded = this.onFacebookFriendsLoaded.bind(this);
      this.onFacebookFriendSessionsLoaded = this.onFacebookFriendSessionsLoaded.bind(this);
      this.gplusFriendsLoaded = this.gplusFriendsLoaded.bind(this);
      this.onGPlusFriendSessionsLoaded = this.onGPlusFriendSessionsLoaded.bind(this);
    }

    static initClass() {
      this.prototype.id = 'ladder-tab-view';
      this.prototype.template = require('app/templates/play/ladder/ladder-tab-view');
      this.prototype.scoreForDisplay = scoreForDisplay;

      this.prototype.events = {
        'click .connect-facebook': 'onConnectFacebook',
        'click .connect-google-plus': 'onConnectGPlus',
        'click .name-col-cell': 'onClickPlayerName',
        'click .spectate-cell': 'onClickSpectateCell',
        'click .load-more-ladder-entries': 'onLoadMoreLadderEntries',
        'click [data-toggle="coco-modal"][data-target="core/CreateAccountModal"]': 'openCreateAccountModal'
      };
    }

      // Refactored, to-reimplement
  //  subscriptions:
  //    'auth:facebook-api-loaded': 'checkFriends'
  //    'auth:gplus-api-loaded': 'checkFriends'
  //    'auth:logged-in-with-facebook': 'onConnectedWithFacebook'
  //    'auth:logged-in-with-gplus': 'onConnectedWithGPlus'

    initialize(options, level, sessions, tournamentId) {
      this.level = level;
      this.sessions = sessions;
      this.tournamentId = tournamentId;
      this.teams = teamDataFromLevel(this.level);
      this.leaderboards = [];
      this.refreshLadder();

      this.capitalize = _.string.capitalize;
      return this.selectedTeam = 'humans';
    }

      // Trying not loading the FP/G+ stuff for now to see if anyone complains they were using it so we can have just two columns.
      //@socialNetworkRes = @supermodel.addSomethingResource('social_network_apis', 0)
      //@checkFriends()

    openCreateAccountModal(e) {
      e.stopPropagation();
      return this.openModalView(new CreateAccountModal());
    }

    checkFriends() {
      return;  // Skipping for now
      if (this.checked || (!window.FB) || (!window.gapi)) { return; }
      this.checked = true;

      // @addSomethingToLoad('facebook_status')

      this.fbStatusRes = this.supermodel.addSomethingResource('facebook_status', 0);
      this.fbStatusRes.load();

      FB.getLoginStatus(response => {
        if (this.destroyed) { return; }
        this.facebookStatus = response.status;
        this.onFacebook = view.facebookStatus === 'connected';
        if (this.onFacebook) { this.loadFacebookFriends(); }
        return this.fbStatusRes.markLoaded();
      });

      if (application.gplusHandler.loggedIn === undefined) {
        this.listenToOnce(application.gplusHandler, 'checked-state', this.gplusSessionStateLoaded);
      } else {
        this.gplusSessionStateLoaded();
      }

      return this.socialNetworkRes.markLoaded();
    }

    // FACEBOOK

    onConnectFacebook() {
      this.connecting = true;
      return FB.login();
    }

    onConnectedWithFacebook() { if (this.connecting) { return location.reload(); } }

    loadFacebookFriends() {
      // @addSomethingToLoad('facebook_friends')

      this.fbFriendRes = this.supermodel.addSomethingResource('facebook_friends', 0);
      this.fbFriendRes.load();

      return FB.api('/me/friends', this.onFacebookFriendsLoaded);
    }

    onFacebookFriendsLoaded(response) {
      this.facebookData = response.data;
      this.loadFacebookFriendSessions();
      return this.fbFriendRes.markLoaded();
    }

    loadFacebookFriendSessions() {
      const levelFrag = `${this.level.get('original')}.${this.level.get('version').major}`;
      const url = `/db/level/${levelFrag}/leaderboard_facebook_friends`;

      this.fbFriendSessionRes = this.supermodel.addRequestResource('facebook_friend_sessions', {
        url,
        data: { friendIDs: (Array.from(this.facebookData).map((f) => f.id)) },
        method: 'POST',
        success: this.onFacebookFriendSessionsLoaded
      });
      return this.fbFriendSessionRes.load();
    }

    onFacebookFriendSessionsLoaded(result) {
      let friend;
      const friendsMap = {};
      for (friend of Array.from(this.facebookData)) { friendsMap[friend.id] = friend.name; }
      for (friend of Array.from(result)) {
        friend.name = friendsMap[friend.facebookID];
        friend.otherTeam = friend.team === 'humans' ? 'ogres' : 'humans';
        friend.imageSource = `http://graph.facebook.com/${friend.facebookID}/picture`;
      }
      this.facebookFriendSessions = result;
      this.friends = this.consolidateFriends();
      return this.render(); // because the ladder tab renders before waiting for fb to finish
    }

    // GOOGLE PLUS

    onConnectGPlus() {
      this.connecting = true;
      this.listenToOnce(application.gplusHandler, 'logged-in', this.onConnectedWithGPlus);
      return application.gplusHandler.reauthorize();
    }

    onConnectedWithGPlus() { if (this.connecting) { return location.reload(); } }

    gplusSessionStateLoaded() {
      if (application.gplusHandler.loggedIn) {
        this.onGPlus = true;
        //@addSomethingToLoad('gplus_friends')
        this.gpFriendRes = this.supermodel.addSomethingResource('gplus_friends', 0);
        this.gpFriendRes.load();
        return application.gplusHandler.loadFriends(this.gplusFriendsLoaded);
      }
    }

    gplusFriendsLoaded(friends) {
      this.gplusData = friends.items;
      this.loadGPlusFriendSessions();
      return this.gpFriendRes.markLoaded();
    }

    loadGPlusFriendSessions() {
      const levelFrag = `${this.level.get('original')}.${this.level.get('version').major}`;
      const url = `/db/level/${levelFrag}/leaderboard_gplus_friends`;

      this.gpFriendSessionRes = this.supermodel.addRequestResource('gplus_friend_sessions', {
        url,
        data: { friendIDs: (Array.from(this.gplusData).map((f) => f.id)) },
        method: 'POST',
        success: this.onGPlusFriendSessionsLoaded
      });
      return this.gpFriendSessionRes.load();
    }

    onGPlusFriendSessionsLoaded(result) {
      let friend;
      const friendsMap = {};
      for (friend of Array.from(this.gplusData)) { friendsMap[friend.id] = friend; }
      for (friend of Array.from(result)) {
        friend.name = friendsMap[friend.gplusID].displayName;
        friend.otherTeam = friend.team === 'humans' ? 'ogres' : 'humans';
        friend.imageSource = friendsMap[friend.gplusID].image.url;
      }
      this.gplusFriendSessions = result;
      this.friends = this.consolidateFriends();
      return this.render(); // because the ladder tab renders before waiting for gplus to finish
    }

    // LADDER LOADING

    refreshLadder() {
      // Only do this so often if not in a league; servers cache a lot of this data for a few minutes anyway.
      if (!this.options.league && ((new Date() - (2 * 60 * 1000)) < this.lastRefreshTime)) { return; }
      this.lastRefreshTime = new Date();
      this.supermodel.resetProgress();
      if (this.ladderLimit == null) { this.ladderLimit = parseInt(utils.getQueryVariable('top_players', this.options.league ? 100 : 20)); }
      return (() => {
        const result = [];
        for (var team of Array.from(this.teams)) {
          var oldLeaderboard;
          if (oldLeaderboard = this.leaderboards[team.id]) {
            this.supermodel.removeModelResource(oldLeaderboard);
            oldLeaderboard.destroy();
          }
          var teamSession = _.find(this.sessions.models, session => session.get('team') === team.id);
          this.leaderboards[team.id] = new LeaderboardData(this.level, team.id, teamSession, this.ladderLimit, this.options.league, this.tournamentId);
          team.leaderboard = this.leaderboards[team.id];
          this.leaderboardRes = this.supermodel.addModelResource(this.leaderboards[team.id], 'leaderboard', {cache: false}, 3);
          result.push(this.leaderboardRes.load());
        }
        return result;
      })();
    }

    render() {
      super.render();

      return this.$el.find('.histogram-display').each((i, el) => {
        let url;
        const histogramWrapper = $(el);
        const team = _.find(this.teams, {name: histogramWrapper.data('team-name')});
        let histogramData = null;
        return $.when(
          (url = `/db/level/${this.level.get('original')}/rankings-histogram?team=${team.name.toLowerCase()}&levelSlug=${this.level.get('slug')}`),
          this.options.league ? (url += '&leagues.leagueID=' + this.options.league.id) : undefined,
          $.get(url, data => histogramData = data)
        ).then(() => {
          if (!this.destroyed) { return this.generateHistogram(histogramWrapper, histogramData, team.name.toLowerCase()); }
        });
      });
    }

    generateHistogram(histogramElement, histogramData, teamName) {
      //renders twice, hack fix
      let session;
      if ($('#' + histogramElement.attr('id')).has('svg').length) { return; }
      if (!histogramData.length) { return histogramElement.hide(); }
      histogramData = histogramData.map(d => scoreForDisplay(d));

      const margin = {
        top: 20,
        right: 20,
        bottom: 30,
        left: 15
      };

      const width = 470 - margin.left - margin.right;
      const height = 125 - margin.top - margin.bottom;

      const formatCount = d3.format(',.0');

      const axisFactor = 1000;
      const minX = Math.floor(Math.min(...Array.from(histogramData || [])) / axisFactor) * axisFactor;
      const maxX = Math.ceil(Math.max(...Array.from(histogramData || [])) / axisFactor) * axisFactor;
      const x = d3.scale.linear().domain([minX, maxX]).range([0, width]);
      const data = d3.layout.histogram().bins(x.ticks(20))(histogramData);
      const y = d3.scale.linear().domain([0, d3.max(data, d => d.y)]).range([height, 10]);

      //create the x axis
      const xAxis = d3.svg.axis().scale(x).orient('bottom').ticks(5).outerTickSize(0);

      const svg = d3.select('#' + histogramElement.attr('id')).append('svg')
        .attr('width', width + margin.left + margin.right)
        .attr('height', height + margin.top + margin.bottom)
      .append('g')
        .attr('transform', `translate(${margin.left}, ${margin.top})`);
      let barClass = 'bar';
      if (teamName.toLowerCase() === 'ogres') { barClass = 'ogres-bar'; }
      if (teamName.toLowerCase() === 'humans') { barClass = 'humans-bar'; }

      const bar = svg.selectAll('.bar')
        .data(data)
      .enter().append('g')
        .attr('class', barClass)
        .attr('transform', d => `translate(${x(d.x)}, ${y(d.y)})`);

      bar.append('rect')
        .attr('x', 1)
        .attr('width', width/20)
        .attr('height', d => height - y(d.y));
      if (session = this.leaderboards[teamName].session) {
        let playerScore;
        if (this.options.league) {
          playerScore = (__guard__(_.find(session.get('leagues'), {leagueID: this.options.league.id}), x1 => x1.stats.totalScore) || 10);
        } else {
          playerScore = session.get('totalScore');
        }
        playerScore = scoreForDisplay(playerScore);
        const scorebar = svg.selectAll('.specialbar')
          .data([playerScore])
          .enter().append('g')
          .attr('class', 'specialbar')
          .attr('transform', `translate(${x(playerScore)}, 0)`);

        scorebar.append('rect')
          .attr('x', 1)
          .attr('width', 3)
          .attr('height', height);
      }
      let rankClass = 'rank-text';
      if (teamName.toLowerCase() === 'ogres') { rankClass = 'rank-text ogres-rank-text'; }
      if (teamName.toLowerCase() === 'humans') { rankClass = 'rank-text humans-rank-text'; }

      let message = `${histogramData.length} players`;
      if (this.leaderboards[teamName].session != null) {
        // TODO: i18n for these messages
        if (this.options.league) {
          // TODO: fix server handler to properly fetch myRank with a leagueID
          message = `${histogramData.length} players in league`;
        } else if (this.leaderboards[teamName].myRank <= histogramData.length) {
          message = `#${this.leaderboards[teamName].myRank} of ${histogramData.length}`;
          if (histogramData.length >= 100000) { message += "+"; }
        } else if (this.leaderboards[teamName].myRank === 'unknown') {
          message = `${histogramData.length >= 100000 ? '100,000+' : histogramData.length} players`;
        } else {
          message = 'Rank your session!';
        }
      }
      svg.append('g')
        .append('text')
        .attr('class', rankClass)
        .attr('y', 0)
        .attr('text-anchor', 'end')
        .attr('x', width)
        .text(message);

      //Translate the x-axis up
      svg.append('g')
        .attr('class', 'x axis')
        .attr('transform', 'translate(0, ' + height + ')')
        .call(xAxis);

      return histogramElement.show();
    }

    consolidateFriends() {
      const allFriendSessions = (this.facebookFriendSessions || []).concat(this.gplusFriendSessions || []);
      let sessions = _.uniq(allFriendSessions, false, session => session._id);
      if (this.options.league) {
        sessions = _.sortBy(sessions, function(session) { let left;
        return (left = __guard__(_.find(session.leagues, {leagueID: this.options.league.id}), x => x.stats.totalScore)) != null ? left : (session.totalScore / 2); });
      } else {
        sessions = _.sortBy(sessions, 'totalScore');
      }
      sessions.reverse();
      return sessions;
    }

    // Admin view of players' code
    onClickPlayerName(e) {
      if (me.isAdmin()) {
        const row = $(e.target).parent();
        const session = new LevelSession({_id: row.data('session-id')});
        this.supermodel.loadModel(session);
        return this.listenToOnce(session, 'sync', _session => {
          let models;
          if (__guard__(_session.get('source'), x => x.name)) {
            models = [_session];
          } else {
            const player = new User({_id: row.data('player-id')});
            models = [_session, player];
          }
          return this.openModalView(new ModelModal({models}));
        });
      } else if (me.isTeacher()) {}
        // TODO
      else {}
    }
        // TODO

    onClickSpectateCell(e) {
      let sessionID, teamID;
      let cell = $(e.target).closest('.spectate-cell');
      const row = cell.parent();
      const table = row.closest('table');
      const wasSelected = cell.hasClass('selected');
      if (this.teams.length === 2) {
        table.find('.spectate-cell.selected').removeClass('selected');
        cell = $(e.target).closest('.spectate-cell').toggleClass('selected', !wasSelected);
        sessionID = row.data('session-id');
        teamID = table.data('team');
        if (this.spectateTargets == null) { this.spectateTargets = {}; }
        this.spectateTargets[teamID] = wasSelected ? null : sessionID;
        return console.log(this.spectateTargets, cell, row, table);
      } else {
        let removeClass;
        if (wasSelected) {
          removeClass = cell.hasClass('selected-humans') ? 'selected-humans' : 'selected-ogres';
          cell = $(e.target).closest('.spectate-cell').removeClass(('selected '+removeClass));
          teamID = (this.selectedTeam = removeClass === 'selected-humans' ? 'humans' : 'ogres');
        } else {
          table.find('.spectate-cell.selected.selected-' + this.selectedTeam).removeClass(('selected selected-'+this.selectedTeam));
          cell = $(e.target).closest('.spectate-cell').addClass('selected selected-'+this.selectedTeam);
          teamID = this.selectedTeam;
          this.selectedTeam = this.selectedTeam === 'humans' ? 'ogres' : 'humans';
        }
        sessionID = row.data('session-id');
        if (this.spectateTargets == null) { this.spectateTargets = {}; }
        this.spectateTargets[teamID] = wasSelected ? null : sessionID;
        return console.log(this.spectateTargets, cell, row, table);
      }
    }

    onLoadMoreLadderEntries(e) {
      if (this.ladderLimit == null) { this.ladderLimit = 100; }
      this.ladderLimit += 100;
      this.lastRefreshTime = null;
      return this.refreshLadder();
    }
  };
  LadderTabView.initClass();
  return LadderTabView;
})());

module.exports.LeaderboardData = (LeaderboardData = (LeaderboardData = class LeaderboardData extends CocoClass {
  /*
  Consolidates what you need to load for a leaderboard into a single Backbone Model-like object.
  */

  constructor(level, team, session, limit, league, tournamentId, ageBracket, myTournamentSubmission) {
    super();
    this.onLoad = this.onLoad.bind(this);
    this.onFail = this.onFail.bind(this);
    this.level = level;
    this.team = team;
    this.session = session;
    this.limit = limit;
    this.league = league;
    this.tournamentId = tournamentId;
    this.ageBracket = ageBracket;
    this.myTournamentSubmission = myTournamentSubmission;
    if (this.myTournamentSubmission) {
      this.myWins = this.myTournamentSubmission.get('wins');
      this.myLosses = this.myTournamentSubmission.get('losses');
      this.myTotalScore = this.myTournamentSubmission.get('totalScore');
      this.myWinRate = (this.myWins || 0) / Math.max((this.myWins || 0) + (this.myLosses || 0), 1);
    }
  }

  collectionParameters(parameters) {
    parameters.team = this.team;
    if (this.league) { parameters['leagues.leagueID'] = this.league.id; }
    return parameters;
  }

  fetch() {
    if (this.topPlayers) { console.warn('Already have top players on', this); }

    const params = this.collectionParameters({order: -1, scoreOffset: HIGHEST_SCORE, limit: this.limit});
    if (this.ageBracket != null) {
      params.age = this.ageBracket;
    }
    if (this.tournamentId != null) {
      this.topPlayers = new TournamentLeaderboardCollection(this.tournamentId, params);
    } else {
      this.topPlayers = new LeaderboardCollection(this.level, params);
    }
    const promises = [];
    promises.push(this.topPlayers.fetch({cache: false}));

    if (this.session) {
      let score;
      if (this.myTotalScore) {
        score = this.myTotalScore;
      } else if (this.league) {
        score = __guard__(_.find(this.session.get('leagues'), {leagueID: this.league.id}), x => x.stats.totalScore);
      } else {
        score = this.session.get('totalScore');
      }
      if (score) {
        if (this.tournamentId != null) {
          this.playersAbove = new TournamentLeaderboardCollection(this.tournamentId, this.collectionParameters({order: 1, scoreOffset: score, limit: 4, winRate: this.myWinRate}));
          promises.push(this.playersAbove.fetch({cache: false}));
          this.playersBelow = new TournamentLeaderboardCollection(this.tournamentId, this.collectionParameters({order: -1, scoreOffset: score, limit: 4, winRate: this.myWinRate}));
          promises.push(this.playersBelow.fetch({cache: false}));
        } else {
          this.playersAbove = new LeaderboardCollection(this.level, this.collectionParameters({order: 1, scoreOffset: score, limit: 4}));
          promises.push(this.playersAbove.fetch({cache: false}));
          this.playersBelow = new LeaderboardCollection(this.level, this.collectionParameters({order: -1, scoreOffset: score, limit: 4}));
          promises.push(this.playersBelow.fetch({cache: false}));
        }
        let success = myRank => {
          this.myRank = myRank;
        };
        let loadURL = `/db/level/${this.level.get('original')}/rankings/${this.session.id}?scoreOffset=${score}&team=${this.team}&levelSlug=${this.level.get('slug')}`;
        if (this.league) { loadURL += '&leagues.leagueID=' + this.league.id; }
        if (this.tournamentId != null) {
          success = ({rank, wins, losses, totalScore}) => {
            this.myRank = rank;
            this.myWins = wins;
            this.myLosses = losses;
            this.myTotalScore = totalScore;
            return this.myWinRate = (this.myWins || 0) / Math.max((this.myWins || 0) + (this.myLosses || 0), 1);
          };
          loadURL = `/db/tournament/${this.tournamentId}/rankings/${this.session.id}?scoreOffset=${score}&team=${this.team}`;
        }
        const loadPromise = $.ajax(loadURL, {cache: false, success});
        const deferred = $.Deferred();
        loadPromise.done(data => deferred.resolve(data));
        loadPromise.fail(jqxhr => {
          if (jqxhr.status === 404) {
            return deferred.resolve('ignored');
          } else {
            return deferred.reject(jqxhr);
          }
        });
        promises.push(deferred.promise());
      }
    }
    this.promise = $.when(...Array.from(promises || []));
    this.promise.then(this.onLoad);
    this.promise.fail(this.onFail);
    return this.promise;
  }

  onLoad() {
    if (this.destroyed || !this.topPlayers.loaded) { return; }
    this.loaded = true;
    this.loading = false;
    return this.trigger('sync', this);
  }
    // TODO: cache user ids -> names mapping, and load them here as needed,
    //   and apply them to sessions. Fetching each and every time is too costly.

  onFail(resource, jqxhr) {
    if (this.destroyed) { return; }
    return this.trigger('error', this, jqxhr);
  }

  inTopSessions() {
    let needle;
    return (needle = me.id, Array.from((Array.from(this.topPlayers.models).map((session) => session.attributes.creator))).includes(needle));
  }

  nearbySessions() {
    let score, session;
    if (this.myTotalScore) {
      score = this.myTotalScore;
    } else if (this.league) {
      score = __guard__(_.find(this.session != null ? this.session.get('leagues') : undefined, {leagueID: this.league.id}), x => x.stats.totalScore);
    } else {
      score = this.session != null ? this.session.get('totalScore') : undefined;
    }
    if (!score) { return []; }
    let l = [];
    const above = this.playersAbove.models;
    l = l.concat(above);
    l.reverse();
    if ((this.session != null ? this.session.get('creatorAge') : undefined) && !(this.session != null ? this.session.ageBracket : undefined)) {
      // add ageBracket for @session
      this.session.ageBracket = utils.ageToBracket(this.session.get('creatorAge'));
    }
    l.push(this.session);
    if (this.myWins) {
      this.session.myWins = this.myWins;
      this.session.myLosses = this.myLosses;
      this.session.myTotalScore = this.myTotalScore;
    }
    l = l.concat(this.playersBelow.models);
    if (this.myRank === 'unknown') {
      for (session of Array.from(l)) { if (session.rank == null) { session.rank = ''; } }
    } else if (this.myRank) {
      const startRank = this.myRank - 4;
      for (let i = 0; i < l.length; i++) { session = l[i]; session.rank = startRank + i; }
    }
    return l;
  }

  allResources() {
    const resources = [this.topPlayers, this.playersAbove, this.playersBelow];
    return (Array.from(resources).filter((r) => r));
  }
}));

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}