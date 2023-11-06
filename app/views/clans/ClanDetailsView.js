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
let ClanDetailsView;
require('app/styles/clans/clan-details.sass');
const RootView = require('views/core/RootView');
const template = require('app/templates/clans/clan-details');
const CreateAccountModal = require('views/core/CreateAccountModal');
const CocoCollection = require('collections/CocoCollection');
const Campaign = require('models/Campaign');
const Clan = require('models/Clan');
const EarnedAchievement = require('models/EarnedAchievement');
const Tournament = require('models/Tournament');
const Level = require('models/Level');
const LevelSession = require('models/LevelSession');
const SubscribeModal = require('views/core/SubscribeModal');
const ThangType = require('models/ThangType');
const User = require('models/User');
const utils = require('core/utils');

// TODO: Add message for clan not found
// TODO: Progress visual for premium levels?
// TODO: Add expanded level names toggle
// TODO: Only need campaign data if clan is private

module.exports = (ClanDetailsView = (function() {
  ClanDetailsView = class ClanDetailsView extends RootView {
    static initClass() {
      this.prototype.id = 'clan-details-view';
      this.prototype.template = template;

      this.prototype.events = {
        'change .expand-progress-checkbox': 'onExpandedProgressCheckbox',
        'click .delete-clan-btn': 'onDeleteClan',
        'click .edit-description-save-btn': 'onEditDescriptionSave',
        'click .edit-name-save-btn': 'onEditNameSave',
        'click .join-clan-btn': 'onJoinClan',
        'click .leave-clan-btn': 'onLeaveClan',
        'click .member-header': 'onClickMemberHeader',
        'click .progress-header': 'onClickProgressHeader',
        'click .progress-level-cell': 'onClickLevel',
        'click .remove-member-btn': 'onRemoveMember',
        'mouseenter .progress-level-cell': 'onMouseEnterPoint',
        'mouseleave .progress-level-cell': 'onMouseLeavePoint'
      };
    }

    getMeta() {
      return {
        title: $.i18n.t('clans.title'),
        meta: [
          { vmid: 'meta-description', name: 'description', content: $.i18n.t('clans.meta_description') }
        ]
      };
    }

    constructor(options, clanID) {
      super(options);
      this.clanID = clanID;
      this.initData();
    }

    destroy() {
      if (typeof this.stopListening === 'function') {
        this.stopListening();
      }
      return super.destroy();
    }

    initData() {
      this.showExpandedProgress = false;
      this.memberSort = 'nameAsc';
      this.stats = {};
      this.ladderLevels = [];
      this.ladderImageMap = {};

      this.clan = new Clan({_id: this.clanID});
      if (/^[a-f0-9]{24}$/.test(this.clanID)) {
        // We have the clan's actual ID
        this.listenTo(this.clan, 'sync', this.onClanSync);
        this.loadPostClanData();
      } else {
        // We have slug, need to get the actual ID before we load the rest
        this.listenTo(this.clan, 'sync', () => {
          this.clanID = this.clan.id;
          this.loadPostClanData();
          return this.onClanSync();
        });
      }
      return this.supermodel.loadModel(this.clan, {cache: false});
    }

    loadPostClanData() {
      this.campaigns = new CocoCollection([], { url: "/db/campaign", model: Campaign, comparator:'_id' });
      this.members = new CocoCollection([], { url: `/db/clan/${this.clanID}/members`, model: User, comparator: 'nameLower' });
      this.memberAchievements = new CocoCollection([], { url: `/db/clan/${this.clanID}/member_achievements`, model: EarnedAchievement, comparator:'_id' });
      this.memberSessions = new CocoCollection([], { url: `/db/clan/${this.clanID}/member_sessions`, model: LevelSession, comparator:'_id' });
      this.tournaments = new CocoCollection([], {url: `/db/tournaments?clanId=${this.clanID}`, model: Tournament});
      this.ladders = new LadderCollection([]);

      this.listenTo(me, 'sync', () => (typeof this.render === 'function' ? this.render() : undefined));
      this.listenTo(this.campaigns, 'sync', this.onCampaignSync);
      this.listenTo(this.members, 'sync', this.onMembersSync);
      this.listenTo(this.memberAchievements, 'sync', this.onMemberAchievementsSync);
      this.listenTo(this.memberSessions, 'sync', this.onMemberSessionsSync);
      this.listenTo(this.tournaments, 'sync', this.onTournamentsSync);
      this.listenTo(this.ladders, 'sync', this.onLaddersSync);

      this.supermodel.loadModel(this.campaigns);
      this.supermodel.loadCollection(this.members, 'members', {cache: false});
      this.supermodel.loadCollection(this.memberAchievements, 'member_achievements', {cache: false});
      this.supermodel.loadCollection(this.tournaments, 'tournaments', {cache: false});
      return this.supermodel.loadCollection(this.ladders, 'ladders');
    }

    getRenderData() {
      let left, needle;
      const context = super.getRenderData();
      context.campaignLevelProgressions = this.campaignLevelProgressions != null ? this.campaignLevelProgressions : [];
      context.clan = this.clan;
      context.conceptsProgression = this.conceptsProgression != null ? this.conceptsProgression : [];
      if (application.isProduction()) {
        context.joinClanLink = `https://codecombat.com/clans/${this.clanID}`;
      } else {
        context.joinClanLink = `http://localhost:3000/clans/${this.clanID}`;
      }
      context.owner = this.owner;
      context.memberAchievementsMap = this.memberAchievementsMap;
      context.memberLanguageMap = this.memberLanguageMap;
      context.memberLevelStateMap = this.memberLevelMap != null ? this.memberLevelMap : {};
      context.memberMaxLevelCount = this.memberMaxLevelCount;
      context.memberSort = this.memberSort;
      context.isOwner = this.clan.get('ownerID') === me.id;
      context.isMember = (needle = this.clanID, Array.from(((left = me.get('clans')) != null ? left : [])).includes(needle));
      context.stats = this.stats;

      // Find last campaign level for each user
      // TODO: why do we do this for every render?
      const highestUserLevelCountMap = {};
      const lastUserCampaignLevelMap = {};
      let maxLastUserCampaignLevel = 0;
      const userConceptsMap = {};
      if (this.campaigns != null ? this.campaigns.loaded : undefined) {
        let levelCount = 0;
        for (var campaign of Array.from(this.campaigns.models)) {
          if (campaign.get('type') === 'hero') {
            var campaignID = campaign.id;
            var lastLevelIndex = 0;
            var object = campaign.get('levels');
            for (var levelID in object) {
              var level = object[levelID];
              var levelSlug = level.slug;
              for (var member of Array.from((this.members != null ? this.members.models : undefined) != null ? (this.members != null ? this.members.models : undefined) : [])) {
                if (context.memberLevelStateMap[member.id] != null ? context.memberLevelStateMap[member.id][levelSlug] : undefined) {
                  if (lastUserCampaignLevelMap[member.id] == null) { lastUserCampaignLevelMap[member.id] = {}; }
                  if (lastUserCampaignLevelMap[member.id][campaignID] == null) { lastUserCampaignLevelMap[member.id][campaignID] = {}; }
                  lastUserCampaignLevelMap[member.id][campaignID] = {
                    levelSlug,
                    index: lastLevelIndex
                  };
                  if (lastLevelIndex > maxLastUserCampaignLevel) { maxLastUserCampaignLevel = lastLevelIndex; }
                  if (level.concepts != null) {
                    if (userConceptsMap[member.id] == null) { userConceptsMap[member.id] = {}; }
                    for (var concept of Array.from(level.concepts)) {
                      if (userConceptsMap[member.id][concept] === 'complete') { continue; }
                      userConceptsMap[member.id][concept] = context.memberLevelStateMap[member.id][levelSlug].state;
                    }
                  }
                  highestUserLevelCountMap[member.id] = levelCount;
                }
              }
              lastLevelIndex++;
              levelCount++;
            }
          }
        }
      }

      this.sortMembers(highestUserLevelCountMap, userConceptsMap);// if @clan.get('dashboardType') is 'premium'
      context.members = (this.members != null ? this.members.models : undefined) != null ? (this.members != null ? this.members.models : undefined) : [];
      context.lastUserCampaignLevelMap = lastUserCampaignLevelMap;
      context.showExpandedProgress = (maxLastUserCampaignLevel <= 30) || this.showExpandedProgress;
      context.userConceptsMap = userConceptsMap;
      context.arenas = this.arenas;
      context.i18n = utils.i18n;
      return context;
    }

    afterRender() {
      super.afterRender();
      return this.updateHeroIcons();
    }

    refreshData() {
      me.fetch({cache: false});
      this.members.fetch({cache: false});
      this.memberAchievements.fetch({cache: false});
      return this.memberSessions.fetch({cache: false});
    }

    sortMembers(highestUserLevelCountMap, userConceptsMap) {
      // Progress sort precedence: most completed concepts, most started concepts, most levels, name sort
      if ((this.members == null) || (this.memberSort == null)) { return; }
      switch (this.memberSort) {
        case "nameDesc":
          this.members.comparator = (a, b) => (b.get('name') || 'Anonymous').localeCompare(a.get('name') || 'Anonymous');
          break;
        case "progressAsc":
          this.members.comparator = function(a, b) {
            let concept, state;
            const aComplete = ((() => {
              const result = [];
              for (concept in userConceptsMap[a.id]) {
                state = userConceptsMap[a.id][concept];
                if (state === 'complete') {
                  result.push(concept);
                }
              }
              return result;
            })());
            const bComplete = ((() => {
              const result1 = [];
              for (concept in userConceptsMap[b.id]) {
                state = userConceptsMap[b.id][concept];
                if (state === 'complete') {
                  result1.push(concept);
                }
              }
              return result1;
            })());
            const aStarted = ((() => {
              const result2 = [];
              for (concept in userConceptsMap[a.id]) {
                state = userConceptsMap[a.id][concept];
                if (state === 'started') {
                  result2.push(concept);
                }
              }
              return result2;
            })());
            const bStarted = ((() => {
              const result3 = [];
              for (concept in userConceptsMap[b.id]) {
                state = userConceptsMap[b.id][concept];
                if (state === 'started') {
                  result3.push(concept);
                }
              }
              return result3;
            })());
            if (aComplete < bComplete) { return -1;
            } else if (aComplete > bComplete) { return 1;
            } else if (aStarted < bStarted) { return -1;
            } else if (aStarted > bStarted) { return 1; }
            if (highestUserLevelCountMap[a.id] < highestUserLevelCountMap[b.id]) { return -1;
            } else if (highestUserLevelCountMap[a.id] > highestUserLevelCountMap[b.id]) { return 1; }
            return (a.get('name') || 'Anonymous').localeCompare(b.get('name') || 'Anonymous');
          };
          break;
        case "progressDesc":
          this.members.comparator = function(a, b) {
            let concept, state;
            const aComplete = ((() => {
              const result = [];
              for (concept in userConceptsMap[a.id]) {
                state = userConceptsMap[a.id][concept];
                if (state === 'complete') {
                  result.push(concept);
                }
              }
              return result;
            })());
            const bComplete = ((() => {
              const result1 = [];
              for (concept in userConceptsMap[b.id]) {
                state = userConceptsMap[b.id][concept];
                if (state === 'complete') {
                  result1.push(concept);
                }
              }
              return result1;
            })());
            const aStarted = ((() => {
              const result2 = [];
              for (concept in userConceptsMap[a.id]) {
                state = userConceptsMap[a.id][concept];
                if (state === 'started') {
                  result2.push(concept);
                }
              }
              return result2;
            })());
            const bStarted = ((() => {
              const result3 = [];
              for (concept in userConceptsMap[b.id]) {
                state = userConceptsMap[b.id][concept];
                if (state === 'started') {
                  result3.push(concept);
                }
              }
              return result3;
            })());
            if (aComplete > bComplete) { return -1;
            } else if (aComplete < bComplete) { return 1;
            } else if (aStarted > bStarted) { return -1;
            } else if (aStarted < bStarted) { return 1; }
            if (highestUserLevelCountMap[a.id] > highestUserLevelCountMap[b.id]) { return -1;
            } else if (highestUserLevelCountMap[a.id] < highestUserLevelCountMap[b.id]) { return 1; }
            return (b.get('name') || 'Anonymous').localeCompare(a.get('name') || 'Anonymous');
          };
          break;
        default:
          this.members.comparator = (a, b) => (a.get('name') || 'Anonymous').localeCompare(b.get('name') || 'Anonymous');
      }
      return this.members.sort();
    }

    updateHeroIcons() {
      if ((this.members != null ? this.members.models : undefined) == null) { return; }
      return (() => {
        const result = [];
        for (var member of Array.from(this.members.models)) {
          var hero;
          if (!(hero = __guard__(member.get('heroConfig'), x => x.thangType))) { continue; }
          result.push((() => {
            const result1 = [];
            for (var slug in ThangType.heroes) {
              var original = ThangType.heroes[slug];
              if (original === hero) {
                result1.push(this.$el.find(`.player-hero-icon[data-memberID=${member.id}]`).removeClass('.player-hero-icon').addClass('player-hero-icon ' + slug));
              }
            }
            return result1;
          })());
        }
        return result;
      })();
    }

    onCampaignSync() {
      if (!this.campaigns.loaded) { return; }
      this.campaignLevelProgressions = [];
      this.conceptsProgression = [];
      this.arenas = [];
      for (var campaign of Array.from(this.campaigns.models)) {
        if (campaign.get('type') === 'hero') {
          var campaignLevelProgression = {
            ID: campaign.id,
            slug: campaign.get('slug'),
            name: utils.i18n(campaign.attributes, 'fullName') || utils.i18n(campaign.attributes, 'name'),
            levels: []
          };
          var object = campaign.get('levels');
          for (var levelID in object) {
            var level = object[levelID];
            campaignLevelProgression.levels.push({
              ID: levelID,
              slug: level.slug,
              name: utils.i18n(level, 'name')
            });
            if (level.concepts != null) {
              for (var concept of Array.from(level.concepts)) {
                if (!Array.from(this.conceptsProgression).includes(concept)) { this.conceptsProgression.push(concept); }
              }
            }
            if (['hero-ladder', 'ladder'].includes(level.type) && !['capture-their-flag'].includes(level.slug)) {  // Would use isType, but it's not a Level model
              this.arenas.push(level);
            }
          }
          this.campaignLevelProgressions.push(campaignLevelProgression);
        }
      }
      return (typeof this.render === 'function' ? this.render() : undefined);
    }

    onClanSync() {
      this.setMeta({
        title: $.i18n.t('clans.clan_title', { clan: this.clan.get('name') })
      });

      if (this.clan.get('ownerID') && (this.owner == null)) {
        this.owner = new User({_id: this.clan.get('ownerID')});
        this.listenTo(this.owner, 'sync', () => (typeof this.render === 'function' ? this.render() : undefined));
        this.supermodel.loadModel(this.owner, {cache: false});
      }
      if (this.clan.get("dashboardType") === "premium") {
        this.supermodel.loadCollection(this.memberSessions, 'member_sessions', {cache: false});
      }
      return (typeof this.render === 'function' ? this.render() : undefined);
    }

    onMembersSync() {
      this.stats.averageLevel = Math.round(this.members.reduce(((sum, member) => sum + member.level()), 0) / this.members.length);
      return (typeof this.render === 'function' ? this.render() : undefined);
    }

    onMemberAchievementsSync() {
      let user;
      this.memberAchievementsMap = {};
      for (var achievement of Array.from(this.memberAchievements.models)) {
        user = achievement.get('user');
        if (this.memberAchievementsMap[user] == null) { this.memberAchievementsMap[user] = []; }
        this.memberAchievementsMap[user].push(achievement);
      }
      for (user in this.memberAchievementsMap) {
        this.memberAchievementsMap[user].sort((a, b) => b.id.localeCompare(a.id));
      }
      this.stats.averageAchievements = Math.round(this.memberAchievements.models.length / Object.keys(this.memberAchievementsMap).length);
      return (typeof this.render === 'function' ? this.render() : undefined);
    }

    onMemberSessionsSync() {
      let levelSession, user;
      this.memberLevelMap = {};
      const memberSessions = {};
      for (levelSession of Array.from(this.memberSessions.models)) {
        if (levelSession.isMultiplayer()) { continue; }
        user = levelSession.get('creator');
        var levelSlug = levelSession.get('levelID');
        if (this.memberLevelMap[user] == null) { this.memberLevelMap[user] = {}; }
        if (this.memberLevelMap[user][levelSlug] == null) { this.memberLevelMap[user][levelSlug] = {}; }
        var levelInfo = {
          level: levelSession.get('levelName'),
          levelID: levelSession.get('levelID'),
          changed: new Date(levelSession.get('changed')).toLocaleString(),
          playtime: levelSession.get('playtime'),
          sessionID: levelSession.id
        };
        this.memberLevelMap[user][levelSlug].levelInfo = levelInfo;
        if (__guard__(levelSession.get('state'), x => x.complete) === true) {
          this.memberLevelMap[user][levelSlug].state = 'complete';
          if (memberSessions[user] == null) { memberSessions[user] = []; }
          memberSessions[user].push(levelSession);
        } else {
          this.memberLevelMap[user][levelSlug].state = 'started';
        }
      }
      this.memberMaxLevelCount = 0;
      this.memberLanguageMap = {};
      for (user in memberSessions) {
        var language;
        var languageCounts = {};
        for (levelSession of Array.from(memberSessions[user])) {
          language = levelSession.get('codeLanguage') || levelSession.get('submittedCodeLanguage');
          if (language) { languageCounts[language] = (languageCounts[language] || 0) + 1; }
        }
        if (this.memberMaxLevelCount < memberSessions[user].length) { this.memberMaxLevelCount = memberSessions[user].length; }
        var mostUsedCount = 0;
        for (language in languageCounts) {
          var count = languageCounts[language];
          if (count > mostUsedCount) {
            mostUsedCount = count;
            this.memberLanguageMap[user] = language;
          }
        }
      }
      return (typeof this.render === 'function' ? this.render() : undefined);
    }

    onTournamentsSync(e) {
      this.tournamentModels = Object.values((Array.from(this.tournaments.models).map((t) => t.toJSON()))[0])[0];
      return (typeof this.render === 'function' ? this.render() : undefined);
    }

    onLaddersSync(e) {
      const levels = [];
      for (var ladder of Array.from(this.ladders.models)) {
        levels.push({
          name: ladder.get('name'),
          id: ladder.get('slug'),
          image: ladder.get('image'),
          original: ladder.get('original')
        });
        this.ladderImageMap[ladder.get('original')] = ladder.get('image');
      }
      this.ladderLevels = levels;
      return (typeof this.render === 'function' ? this.render() : undefined);
    }

    onMouseEnterPoint(e) {
      const container = $(e.target).find('.level-popup-container').show();
      const margin = 20;
      const offset = $(e.target).offset();
      const scrollTop = $(e.target).offsetParent().scrollTop();
      const height = container.outerHeight();
      container.css('left', offset.left + e.offsetX);
      container.css('top', (offset.top + scrollTop) - height - margin);
      if (this.lastPopup) {
        this.lastPopup.hide();
      }
      return this.lastPopup = container;
    }

    onMouseLeavePoint(e) {
      $(e.target).find('.level-popup-container').hide();
      if (this.lastPopup) {
        this.lastPopup.hide();
        return this.lastPopup = null;
      }
    }

    onClickLevel(e) {
      if (this.clan.get('ownerID') !== me.id) { return; }
      const levelInfo = $(e.target).data('level-info');
      if (((levelInfo != null ? levelInfo.levelID : undefined) == null) || ((levelInfo != null ? levelInfo.sessionID : undefined) == null)) { return; }
      const url = `/play/level/${levelInfo.levelID}?session=${levelInfo.sessionID}&observing=true`;
      return window.open(url, '_blank');
    }

    onDeleteClan(e) {
      if (me.isAnonymous()) { return this.openModalView(new CreateAccountModal()); }
      if (!window.confirm("Delete Clan?")) { return; }
      const options = {
        url: `/db/clan/${this.clanID}`,
        method: 'DELETE',
        error: (model, response, options) => {
          return console.error('Error joining clan', response);
        },
        success: (model, response, options) => {
          application.router.navigate("/clans");
          return window.location.reload();
        }
      };
      return this.supermodel.addRequestResource( 'delete_clan', options).load();
    }

    onEditDescriptionSave(e) {
      const description = $('.edit-description-input').val();
      this.clan.set('description', description);
      this.clan.patch();
      return $('#editDescriptionModal').modal('hide');
    }

    onEditNameSave(e) {
      let name;
      if (name = $('.edit-name-input').val()) {
        this.clan.set('name', name);
        this.clan.patch();
      }
      return $('#editNameModal').modal('hide');
    }

    onExpandedProgressCheckbox(e) {
      this.showExpandedProgress = $('.expand-progress-checkbox').prop('checked');
      // TODO: why does render reset the checkbox to be unchecked?
      if (typeof this.render === 'function') {
        this.render();
      }
      return $('.expand-progress-checkbox').attr('checked', this.showExpandedProgress);
    }

    onJoinClan(e) {
      if (me.isAnonymous()) { return this.openModalView(new CreateAccountModal()); }
      if (!this.clan.loaded) { return; }
      if ((this.clan.get('type') === 'private') && !me.isPremium()) {
        this.openModalView(new SubscribeModal());
        if (window.tracker != null) {
          window.tracker.trackEvent('Show subscription modal', {category: 'Subscription', label: 'join clan'});
        }
        return;
      }
      const options = {
        url: `/db/clan/${this.clanID}/join`,
        method: 'PUT',
        error: (model, response, options) => {
          return console.error('Error joining clan', response);
        },
        success: (model, response, options) => this.refreshData()
      };
      return this.supermodel.addRequestResource( 'join_clan', options).load();
    }

    onLeaveClan(e) {
      const options = {
        url: `/db/clan/${this.clanID}/leave`,
        method: 'PUT',
        error: (model, response, options) => {
          return console.error('Error leaving clan', response);
        },
        success: (model, response, options) => this.refreshData()
      };
      return this.supermodel.addRequestResource( 'leave_clan', options).load();
    }

    onClickMemberHeader(e) {
      this.memberSort = this.memberSort === 'nameAsc' ? 'nameDesc' : 'nameAsc';
      return (typeof this.render === 'function' ? this.render() : undefined);
    }

    onClickProgressHeader(e) {
      this.memberSort = this.memberSort === 'progressAsc' ? 'progressDesc' : 'progressAsc';
      return (typeof this.render === 'function' ? this.render() : undefined);
    }

    onRemoveMember(e) {
      let memberID;
      if (!window.confirm("Remove Hero?")) { return; }
      if (memberID = $(e.target).data('id')) {
        const options = {
          url: `/db/clan/${this.clanID}/remove/${memberID}`,
          method: 'PUT',
          error: (model, response, options) => {
            return console.error('Error removing clan member', response);
          },
          success: (model, response, options) => this.refreshData()
        };
        return this.supermodel.addRequestResource( 'remove_member', options).load();
      } else {
        return console.error("No member ID attached to remove button.");
      }
    }
  };
  ClanDetailsView.initClass();
  return ClanDetailsView;
})());

class LadderCollection extends CocoCollection {
  static initClass() {
    this.prototype.url = '';
    this.prototype.model = Level;
  }

  constructor(model) {
    super();
    this.url = "/db/level/-/arenas";
  }
}
LadderCollection.initClass();

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}