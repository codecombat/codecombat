/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let MainUserView;
require('app/styles/user/main-user-view.sass');
const UserView = require('views/common/UserView');
const CocoCollection = require('collections/CocoCollection');
const LevelSession = require('models/LevelSession');
const template = require('app/templates/user/main-user-view');
const {me} = require('core/auth');
const Clan = require('models/Clan');
const utils = require('core/utils');
const EarnedAchievementCollection = require('collections/EarnedAchievementCollection');

class LevelSessionsCollection extends CocoCollection {
  static initClass() {
    this.prototype.model = LevelSession;
  }

  constructor(userID) {
    super();
    this.url = `/db/user/${userID}/level.sessions?project=state.complete,levelID,levelName,changed,team,codeLanguage,submittedCodeLanguage,totalScore&order=-1`;
  }
}
LevelSessionsCollection.initClass();

module.exports = (MainUserView = (function() {
  MainUserView = class MainUserView extends UserView {
    static initClass() {
      this.prototype.id = 'user-home';
      this.prototype.template = template;

      this.prototype.events =
        {'click .more-button': 'onClickMoreButton'};
    }

    constructor(userID, options) {
      super(options);
      this.loadHeroPoseImage = this.loadHeroPoseImage.bind(this);
    }

    destroy() {
      if (typeof this.stopListening === 'function') {
        this.stopListening();
      }
      return super.destroy();
    }

    loadHeroPoseImage() {
      return this.user.getHeroPoseImage().then(result => {
        this.heroPoseImage = result;
        return this.render();
      });
    }

    onLoaded() {
      if (this.user.loaded) {
        this.setMeta({
          title: $.i18n.t('user.user_title', { name: this.user.broadName() })
        });

        if (!this.levelSessions) {
          this.levelSessions = new LevelSessionsCollection(this.user.getSlugOrID());
          this.listenTo(this.levelSessions, 'sync', () => {
            this.onSyncLevelSessions(this.levelSessions != null ? this.levelSessions.models : undefined);
            return this.render();
          });
          this.supermodel.loadCollection(this.levelSessions, 'levelSessions', {cache: false});
        }

        if (!this.earnedAchievements) {
          this.earnedAchievements = new EarnedAchievementCollection(this.user.getSlugOrID());
          this.listenTo(this.earnedAchievements, 'sync', () => {
            return this.render();
          });
          this.supermodel.loadCollection(this.earnedAchievements, 'earnedAchievements', {cache: false});
        }
      }

      const sortClanList = function(a, b) {
        if (a.get('members').length !== b.get('members').length) {
          if (a.get('members').length < b.get('members').length) { return 1; } else { return -1; }
        } else {
          return b.id.localeCompare(a.id);
        }
      };

      this.clans = new CocoCollection([], { url: `/db/user/${this.userID}/clans`, model: Clan, comparator: sortClanList });
      this.listenTo(this.clans, 'sync', () => {
        this.onSyncClans(this.clans != null ? this.clans.models : undefined);
        return (typeof this.render === 'function' ? this.render() : undefined);
      });
      this.supermodel.loadCollection(this.clans, 'clans', {cache: false});
      if (utils.isCodeCombat) {
        this.loadHeroPoseImage();
      }
      return super.onLoaded();
    }

    onSyncClans(clans) {
      if (clans == null) { return; }
      this.idNameMap = [];
      this.clanModels = clans;
      const options = {
        url: '/db/user/-/names',
        method: 'POST',
        data: {ids: _.map(clans, clan => clan.get('ownerID'))},
        success: (models, response, options) => {
          for (var userID in models) { this.idNameMap[userID] = models[userID].name; }
          return (typeof this.render === 'function' ? this.render() : undefined);
        }
      };
      return this.supermodel.addRequestResource('user_names', options, 0).load();
    }

    onSyncLevelSessions(levelSessions) {
      let language;
      if (levelSessions == null) { return; }
      this.multiPlayerSessions = [];
      this.singlePlayerSessions = [];
      const languageCounts = [];
      let mostUsedCount = 0;
      for (var levelSession of Array.from(levelSessions)) {
        if (levelSession.isMultiplayer()) {
          this.multiPlayerSessions.push(levelSession);
        } else {
          this.singlePlayerSessions.push(levelSession);
        }
        language = levelSession.get('codeLanguage') || levelSession.get('submittedCodeLanguage');
        if (language) {
          languageCounts[language] = (languageCounts[language] || 0) + 1;
        }
      }
      return (() => {
        const result = [];
        for (language in languageCounts) {
          var count = languageCounts[language];
          if (count > mostUsedCount) {
            mostUsedCount = count;
            result.push(this.favoriteLanguage = language);
          } else {
            result.push(undefined);
          }
        }
        return result;
      })();
    }

    onClickMoreButton(e) {
      const panel = $(e.target).closest('.panel');
      panel.find('tr.hide').removeClass('hide');
      return panel.find('.panel-footer').remove();
    }
  };
  MainUserView.initClass();
  return MainUserView;
})());
