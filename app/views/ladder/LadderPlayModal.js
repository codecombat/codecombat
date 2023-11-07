// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LadderPlayModal;
require('app/styles/play/ladder/play_modal.sass');
const ModalView = require('views/core/ModalView');
const template = require('app/templates/play/ladder/play_modal');
const ThangType = require('models/ThangType');
const {me} = require('core/auth');
const LeaderboardCollection = require('collections/LeaderboardCollection');
const {teamDataFromLevel} = require('./utils');
const {isCodeCombat} = require('core/utils');

module.exports = (LadderPlayModal = (function() {
  LadderPlayModal = class LadderPlayModal extends ModalView {
    static initClass() {
      this.prototype.id = 'ladder-play-modal';
      this.prototype.template = template;
      this.prototype.closeButton = true;
      this.shownTutorialButton = false;
      this.prototype.tutorialLevelExists = null;

      this.prototype.events = {
        'click #skip-tutorial-button': 'hideTutorialButtons',
        'change #tome-language': 'updateLanguage'
      };

      this.prototype.defaultAceConfig = {
        language: 'javascript',
        keyBindings: 'default',
        invisibles: false,
        indentGuides: false,
        behaviors: false,
        liveCompletion: true
      };
    }

    initialize(options, level, session, team) {
      let left, left1;
      this.level = level;
      this.session = session;
      this.team = team;
      this.otherTeam = this.team === 'ogres' ? 'humans' : 'ogres';
      if (isCodeCombat) {
        if (this.level.isType('ladder')) { this.otherTeam = 'humans'; }
      }
      this.wizardType = ThangType.loadUniversalWizard();
      this.startLoadingChallengersMaybe();
      this.levelID = this.level.get('slug') || this.level.id;
      this.language = (left = (left1 = (this.session != null ? this.session.get('codeLanguage') : undefined)) != null ? left1 : __guard__(me.get('aceConfig'), x => x.language)) != null ? left : 'python';
      this.languages = [
        {id: 'python', name: 'Python'},
        {id: 'javascript', name: 'JavaScript'},
        {id: 'coffeescript', name: 'CoffeeScript'},
        {id: 'lua', name: 'Lua'},
        {id: 'cpp', name: 'C++'},
        {id: 'java', name: 'Java (Experimental)'}
      ];
      this.myName = me.get('name') || 'Newcomer';

      const teams = [];
      for (var t of Array.from(teamDataFromLevel(this.level))) { teams[t.id] = t; }
      this.teamColor = teams[this.team].primaryColor;
      this.teamBackgroundColor = teams[this.team].bgColor;
      this.opponentTeamColor = teams[this.otherTeam].primaryColor;
      this.opponentTeamBackgroundColor = teams[this.otherTeam].bgColor;
    }

    updateLanguage() {
      let left;
      let aceConfig = _.cloneDeep((left = me.get('aceConfig')) != null ? left : {});
      aceConfig = _.defaults(aceConfig, this.defaultAceConfig);
      aceConfig.language = this.$el.find('#tome-language').val();
      me.set('aceConfig', aceConfig);
      me.patch();
      if (this.session) {
        this.session.set('codeLanguage', aceConfig.language);
        if (isCodeCombat) {
          return this.session.save({codeLanguage: aceConfig.language}, {patch: true, type: 'PUT'});
        } else {
          return this.session.patch();
        }
      }
    }

    // PART 1: Load challengers from the db unless some are in the matches
    startLoadingChallengersMaybe() {
      let matches;
      if (this.options.league) {
        matches = __guard__(_.find(this.session != null ? this.session.get('leagues') : undefined, {leagueID: this.options.league.id}), x => x.stats.matches);
      } else {
        matches = this.session != null ? this.session.get('matches') : undefined;
      }
      if ((matches != null ? matches.length : undefined)) { return this.loadNames(); } else { return this.loadChallengers(); }
    }

    loadChallengers() {
      this.challengersCollection = new ChallengersData(this.level, this.team, this.otherTeam, this.session, this.options.league);
      return this.listenTo(this.challengersCollection, 'sync', this.loadNames);
    }

    // PART 2: Loading the names of the other users

    loadNames() {
      let challenger;
      this.challengers = this.getChallengers();
      const ids = ((() => {
        const result = [];
        for (challenger of Array.from(_.values(this.challengers))) {           result.push(challenger.opponentID);
        }
        return result;
      })());

      for (challenger of Array.from(_.values(this.challengers))) {
        if (!challenger || !this.wizardType.loaded) { continue; }
        if ((!challenger.opponentImageSource) && (challenger.opponentWizard != null ? challenger.opponentWizard.colorConfig : undefined)) {
          challenger.opponentImageSource = this.wizardType.getPortraitSource(
            {colorConfig: challenger.opponentWizard.colorConfig});
        }
      }

      const success = nameMap => {
        // it seems to be fix that could go to both
        this.nameMap = nameMap;
        if (this.destroyed) { return; }
        for (challenger of Array.from(_.values(this.challengers))) {
          challenger.opponentName = (this.nameMap[challenger.opponentID] != null ? this.nameMap[challenger.opponentID].name : undefined) || 'Anonymous';
          challenger.opponentWizard = (this.nameMap[challenger.opponentID] != null ? this.nameMap[challenger.opponentID].wizard : undefined) || {};
        }
        return this.checkWizardLoaded();
      };

      const data =  { ids, wizard: true };
      if (this.options.league) {
        data.leagueId = this.options.league.id;
      }
      const userNamesRequest = this.supermodel.addRequestResource('user_names', {
        url: '/db/user/-/getFullNames',
        data,
        method: 'POST',
        success
      }, 0);
      return userNamesRequest.load();
    }

    // PART 3: Make sure wizard is loaded

    checkWizardLoaded() {
      if (this.wizardType.loaded) { return this.finishRendering(); } else { return this.listenToOnce(this.wizardType, 'sync', this.finishRendering); }
    }

    // PART 4: Render

    finishRendering() {
      if (this.destroyed) { return; }
      this.checkTutorialLevelExists(exists => {
        if (this.destroyed) { return; }
        this.tutorialLevelExists = exists;
        this.render();
        return this.maybeShowTutorialButtons();
      });
      this.genericPortrait = this.wizardType.getPortraitSource();
      const myColorConfig = __guard__(me.get('wizard'), x => x.colorConfig);
      return this.myPortrait = myColorConfig ? this.wizardType.getPortraitSource({colorConfig: myColorConfig}) : this.genericPortrait;
    }

    maybeShowTutorialButtons() {
      if (this.session || LadderPlayModal.shownTutorialButton || !this.tutorialLevelExists) { return; }
      this.$el.find('#normal-view').addClass('secret');
      this.$el.find('.modal-header').addClass('secret');
      this.$el.find('#noob-view').removeClass('secret');
      return LadderPlayModal.shownTutorialButton = true;
    }

    hideTutorialButtons() {
      this.$el.find('#normal-view').removeClass('secret');
      this.$el.find('.modal-header').removeClass('secret');
      return this.$el.find('#noob-view').addClass('secret');
    }

    checkTutorialLevelExists(cb) {
      if (isCodeCombat) {
        return;  // We don't have any tutorials, currently. TODO: should remove this or update to create more tutorials.
      }
      const levelID = this.level.get('slug') || this.level.id;
      const tutorialLevelID = `${levelID}-tutorial`;
      const success = () => cb(true);
      const failure = () => cb(false);
      return $.ajax({
        type: 'GET',
        url: `/db/level/${tutorialLevelID}/exists`,
        success,
        error: failure
      });
    }

    // Choosing challengers

    getChallengers() {
      // make an object of challengers to everything needed to link to them
      let easyInfo, hardInfo, mediumInfo;
      let m;
      const challengers = {};
      if (this.challengersCollection) {
        easyInfo = this.challengeInfoFromSession(this.challengersCollection.easyPlayer.models[0]);
        mediumInfo = this.challengeInfoFromSession(this.challengersCollection.mediumPlayer.models[0]);
        hardInfo = this.challengeInfoFromSession(this.challengersCollection.hardPlayer.models[0]);
      } else {
        let matches;
        if (this.options.league) {
          matches = __guard__(_.find(this.session != null ? this.session.get('leagues') : undefined, {leagueID: this.options.league.id}), x => x.stats.matches);
        } else {
          matches = this.session != null ? this.session.get('matches') : undefined;
        }
        const won = ((() => {
          const result = [];
          for (m of Array.from(matches)) {             if (m.metrics.rank < m.opponents[0].metrics.rank) {
              result.push(m);
            }
          }
          return result;
        })());
        const lost = ((() => {
          const result1 = [];
          for (m of Array.from(matches)) {             if (m.metrics.rank > m.opponents[0].metrics.rank) {
              result1.push(m);
            }
          }
          return result1;
        })());
        const tied = ((() => {
          const result2 = [];
          for (m of Array.from(matches)) {             if (m.metrics.rank === m.opponents[0].metrics.rank) {
              result2.push(m);
            }
          }
          return result2;
        })());
        easyInfo = this.challengeInfoFromMatches(won);
        mediumInfo = this.challengeInfoFromMatches(tied);
        hardInfo = this.challengeInfoFromMatches(lost);
      }
      this.addChallenger(easyInfo, challengers, 'easy');
      this.addChallenger(mediumInfo, challengers, 'medium');
      this.addChallenger(hardInfo, challengers, 'hard');
      return challengers;
    }

    addChallenger(info, challengers, title) {
      // check for duplicates first
      if (!info) { return; }
      for (var key in challengers) {
        var value = challengers[key];
        if (value.sessionID === info.sessionID) { return; }
      }
      return challengers[title] = info;
    }

    challengeInfoFromSession(session) {
      // given a model from the db, return info needed for a link to the match
      if (!session) { return; }
      return {
        sessionID: session.id,
        opponentID: session.get('creator'),
        codeLanguage: session.get('submittedCodeLanguage')
      };
    }

    challengeInfoFromMatches(matches) {
      if (!(matches != null ? matches.length : undefined)) { return; }
      const match = _.sample(matches);
      const opponent = match.opponents[0];
      return {
        sessionID: opponent.sessionID,
        opponentID: opponent.userID,
        codeLanguage: opponent.codeLanguage
      };
    }
  };
  LadderPlayModal.initClass();
  return LadderPlayModal;
})());

class ChallengersData {
  constructor(level, team, otherTeam, session, league) {
    let score;
    this.level = level;
    this.team = team;
    this.otherTeam = otherTeam;
    this.session = session;
    this.league = league;
    _.extend(this, Backbone.Events);
    if (this.league) {
      score = __guard__(__guard__(_.find(this.session != null ? this.session.get('leagues') : undefined, {leagueID: this.league.id}), x1 => x1.stats), x => x.totalScore) || 10;
    } else {
      score = (this.session != null ? this.session.get('totalScore') : undefined) || 10;
    }
    for (var player of [
      {type: 'easyPlayer', order: 1, scoreOffset: score - 5},
      {type: 'mediumPlayer', order: 1, scoreOffset: score},
      {type: 'hardPlayer', order: -1, scoreOffset: score + 5}
    ]) {
      var playerResource = (this[player.type] = new LeaderboardCollection(this.level, this.collectionParameters({order: player.order, scoreOffset: player.scoreOffset})));
      playerResource.fetch({cache: false});
      this.listenToOnce(playerResource, 'sync', this.challengerLoaded);
    }
  }

  collectionParameters(parameters) {
    parameters.team = this.otherTeam;
    parameters.limit = 1;
    if (this.league) { parameters['leagues.leagueID'] = this.league.id; }
    return parameters;
  }

  challengerLoaded() {
    if (this.allLoaded()) {
      this.loaded = true;
      return this.trigger('sync');
    }
  }

  playerIDs() {
    const collections = [this.easyPlayer, this.mediumPlayer, this.hardPlayer];
    return (Array.from(collections).filter((c) => (c != null ? c.models[0] : undefined)).map((c) => c.models[0].get('creator')));
  }

  allLoaded() {
    return _.all([this.easyPlayer.loaded, this.mediumPlayer.loaded, this.hardPlayer.loaded]);
  }
}

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}