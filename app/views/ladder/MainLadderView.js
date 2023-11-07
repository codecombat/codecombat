// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let MainLadderView;
require('app/styles/play/ladder_home.sass');
const RootView = require('views/core/RootView');
const template = require('app/templates/play/ladder_home');
const LevelSession = require('models/LevelSession');
const CocoCollection = require('collections/CocoCollection');

class LevelSessionsCollection extends CocoCollection {
  static initClass() {
    this.prototype.url = '';
    this.prototype.model = LevelSession;
  }

  constructor(model) {
    super();
    this.url = `/db/user/${me.id}/level.sessions?project=state.complete,levelID`;
  }
}
LevelSessionsCollection.initClass();

module.exports = (MainLadderView = (function() {
  MainLadderView = class MainLadderView extends RootView {
    static initClass() {
      this.prototype.id = 'main-ladder-view';
      this.prototype.template = template;
    }

    constructor () {
      super()

      this.levelStatusMap = [];
      this.levelPlayCountMap = [];
      this.campaigns = campaigns;

      this.sessions = this.supermodel.loadCollection(new LevelSessionsCollection(), 'your_sessions', {cache: false}, 0).model;
      this.listenToOnce(this.sessions, 'sync', this.onSessionsLoaded)
    }

      // TODO: Make sure this is also enabled server side.
      // Disabled due to high load on database.
      // @getLevelPlayCounts()

    getMeta() {
      return {title: $.i18n.t('ladder.title')};
    }

    onSessionsLoaded(e) {
      for (var session of Array.from(this.sessions.models)) {
        this.levelStatusMap[session.get('levelID')] = __guard__(session.get('state'), x => x.complete) ? 'complete' : 'started';
      }
      return this.render();
    }

    getLevelPlayCounts() {
      const success = levelPlayCounts => {
        if (this.destroyed) { return; }
        for (var level of Array.from(levelPlayCounts)) {
          this.levelPlayCountMap[level._id] = {playtime: level.playtime, sessions: level.sessions};
        }
        if (this.supermodel.finished()) { return this.render(); }
      };

      const levelIDs = [];
      for (var campaign of Array.from(campaigns)) {
        for (var level of Array.from(campaign.levels)) {
          levelIDs.push(level.id);
        }
      }
      const levelPlayCountsRequest = this.supermodel.addRequestResource('play_counts', {
        url: '/db/level/-/play_counts',
        data: {ids: levelIDs},
        method: 'POST',
        success
      }, 0);
      return levelPlayCountsRequest.load();
    }
  };
  MainLadderView.initClass();
  return MainLadderView;
})());

const heroArenas = [
  {
    name: 'Ace of Coders',
    difficulty: 3,
    id: 'ace-of-coders',
    image: '/file/db/level/55de80407a57948705777e89/Ace-of-Coders-banner.png',
    description: 'Battle for control over the icy treasure chests as your gigantic warrior marshals his armies against his mirror-match nemesis.'
  },
  {
    name: 'Zero Sum',
    difficulty: 3,
    id: 'zero-sum',
    image: '/file/db/level/550363b4ec31df9c691ab629/MAR26-Banner_Zero%20Sum.png',
    description: 'Unleash your coding creativity in both gold gathering and battle tactics in this alpine mirror match between red sorcerer and blue sorcerer.'
  },
  {
    name: 'Cavern Survival',
    difficulty: 1,
    id: 'cavern-survival',
    image: '/file/db/level/544437e0645c0c0000c3291d/OCT30-Cavern%20Survival.png',
    description: 'Stay alive longer than your multiplayer opponent amidst hordes of ogres!'
  },
  {
    name: 'Dueling Grounds',
    difficulty: 1,
    id: 'dueling-grounds',
    image: '/file/db/level/5442ba0e1e835500007eb1c7/OCT27-Dueling%20Grounds.png',
    description: 'Battle head-to-head against another hero in this basic beginner combat arena.'
  },
  {
    name: 'Multiplayer Treasure Grove',
    difficulty: 2,
    id: 'multiplayer-treasure-grove',
    image: '/file/db/level/5469643c37600b40e0e09c5b/OCT27-Multiplayer%20Treasure%20Grove.png',
    description: 'Mix collection, flags, and combat in this multiplayer coin-gathering arena.'
  },
  {
    name: 'Harrowland',
    difficulty: 2,
    id: 'harrowland',
    image: '/file/db/level/54b83c2629843994803c838e/OCT27-Harrowland.png',
    description: 'Go head-to-head against another player in this dueling arena--but watch out for their friends!'
  }
];

var campaigns = [
  {id: 'multiplayer', name: 'Multiplayer Arenas', description: '... in which you code head-to-head against other players.', levels: heroArenas}
];

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}