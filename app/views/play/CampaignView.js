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
let CampaignView;
require('app/styles/play/campaign-view.sass');
const RootView = require('views/core/RootView');
const template = require('templates/play/campaign-view');
const LevelSession = require('models/LevelSession');
const EarnedAchievement = require('models/EarnedAchievement');
const CocoCollection = require('collections/CocoCollection');
const Achievements = require('collections/Achievements');
const Campaign = require('models/Campaign');
const AudioPlayer = require('lib/AudioPlayer');
const LevelSetupManager = require('lib/LevelSetupManager');
const ThangType = require('models/ThangType');
const MusicPlayer = require('lib/surface/MusicPlayer');
const storage = require('core/storage');
const CreateAccountModal = require('views/core/CreateAccountModal');
const SubscribeModal = require('views/core/SubscribeModal');
const LeaderboardModal = require('views/play/modal/LeaderboardModal');
const Level = require('models/Level');
const utils = require('core/utils');
const ShareProgressModal = require('views/play/modal/ShareProgressModal');
const UserPollsRecord = require('models/UserPollsRecord');
const Poll = require('models/Poll');
const PollModal = require('views/play/modal/PollModal');
const AnnouncementModal = require('views/play/modal/AnnouncementModal');
const LiveClassroomModal = require('views/play/modal/LiveClassroomModal');
const Codequest2020Modal = require('views/play/modal/Codequest2020Modal');
const MineModal = require('views/core/MineModal'); // Roblox modal
const api = require('core/api');
const Classroom = require('models/Classroom');
const Course = require('models/Course');
const CourseInstance = require('models/CourseInstance');
const Levels = require('collections/Levels');
const payPal = require('core/services/paypal');
const createjs = require('lib/createjs-parts');
const PlayItemsModal = require('views/play/modal/PlayItemsModal');
const PlayHeroesModal = require('views/play/modal/PlayHeroesModal');
const PlayAchievementsModal = require('views/play/modal/PlayAchievementsModal');
const BuyGemsModal = require('views/play/modal/BuyGemsModal');
const ContactModal = require('views/core/ContactModal');
const AnonymousTeacherModal = require('views/core/AnonymousTeacherModal');
const AmazonHocModal = require('views/play/modal/AmazonHocModal');
const PromotionModal = require('views/play/modal/PromotionModal');
require('vendor/scripts/jquery-ui-1.11.1.custom');
require('vendor/styles/jquery-ui-1.11.1.custom.css');
const HoCModal = require('views/special_event/HoC2018InterstitialModal');
const CourseVideosModal = require('views/play/level/modal/CourseVideosModal');
const globalVar = require('core/globalVar');
const paymentUtils = require('app/lib/paymentUtils');
const userUtils = require('lib/user-utils');

require('lib/game-libraries');

class LevelSessionsCollection extends CocoCollection {
  static initClass() {
    this.prototype.url = '';
    this.prototype.model = LevelSession;
  }

  constructor(model) {
    super();
    this.url = `/db/user/${me.id}/level.sessions?project=state.complete,levelID,state.difficulty,playtime,state.topScores,codeLanguage,level`;
  }
}
LevelSessionsCollection.initClass();

class CampaignsCollection extends CocoCollection {
  static initClass() {
    // We don't send all of levels, just the parts needed in countLevels
    this.prototype.url = '/db/campaign/-/overworld?project=slug,adjacentCampaigns,name,fullName,description,i18n,color,levels';
    this.prototype.model = Campaign;
  }
}
CampaignsCollection.initClass();

module.exports = (CampaignView = (function() {
  CampaignView = class CampaignView extends RootView {
    static initClass() {
      this.prototype.id = 'campaign-view';
      this.prototype.template = template;

      this.prototype.subscriptions =
        {'subscribe-modal:subscribed': 'onSubscribed'};

      this.prototype.events = {
        'click #amazon-campaign-logo': 'onClickAmazonCampaign',
        'click #anon-classroom-signup-close': 'onClickAnonClassroomClose',
        'click #anon-classroom-join-btn': 'onClickAnonClassroomJoin',
        'click #anon-classroom-signup-btn': 'onClickAnonClassroomSignup',
        'click .roblox-level': 'onRobloxLevelClick',
        'click .hackstack-level': 'onHackStackLevelClick',
        'click .map-background': 'onClickMap',
        'click .level': 'onClickLevel',
        'dblclick .level': 'onDoubleClickLevel',
        'click .level-info-container .start-level': 'onClickStartLevel',
        'click .level-info-container .view-solutions': 'onClickViewSolutions',
        'click .level-info-container .course-version button': 'onClickCourseVersion',
        'click #volume-button': 'onToggleVolume',
        'click #back-button': 'onClickBack',
        'click #clear-storage-button': 'onClickClearStorage',
        'click .portal .campaign': 'onClickPortalCampaign',
        'click .portal .beta-campaign': 'onClickPortalCampaign',
        'click a .campaign-switch': 'onClickCampaignSwitch',
        'mouseenter .portals': 'onMouseEnterPortals',
        'mouseleave .portals': 'onMouseLeavePortals',
        'mousemove .portals': 'onMouseMovePortals',
        'click .poll': 'showPoll',
        'click #brain-pop-replay-btn': 'onClickBrainPopReplayButton',
        'click .premium-menu-icon': 'onClickPremiumButton',
        'click [data-toggle="coco-modal"][data-target="play/modal/PromotionModal"]': 'openPromotionModal',
        'click [data-toggle="coco-modal"][data-target="play/modal/PlayItemsModal"]': 'openPlayItemsModal',
        'click [data-toggle="coco-modal"][data-target="play/modal/PlayHeroesModal"]': 'openPlayHeroesModal',
        'click [data-toggle="coco-modal"][data-target="play/modal/PlayAchievementsModal"]': 'openPlayAchievementsModal',
        'click [data-toggle="coco-modal"][data-target="play/modal/BuyGemsModal"]': 'openBuyGemsModal',
        'click [data-toggle="coco-modal"][data-target="core/ContactModal"]': 'openContactModal',
        'click [data-toggle="coco-modal"][data-target="core/CreateAccountModal"]': 'openCreateAccountModal',
        'click [data-toggle="coco-modal"][data-target="core/AnonymousTeacherModal"]': 'openAnonymousTeacherModal',
        'click #videos-button': 'onClickVideosButton',
        'click #esports-arena': 'onClickEsportsButton',
        'click a.start-esports': 'onClickEsportsLink',
        'click .m7-off': 'onClickM7OffButton'
      };

      this.prototype.shortcuts =
        {'shift+s': 'onShiftS'};

      this.prototype.activeArenas = utils.activeArenas;
    }

    getMeta() {
      return {
        title: $.i18n.t('play.title'),
        meta: [
          { vmid: 'meta-description', name: 'description', content: $.i18n.t('play.meta_description') }
        ],
        link: [
          { vmid: 'rel-canonical', rel: 'canonical', content: '/play' }
        ]
      };
    }

    constructor(options, terrain) {
      super(options);
      this.onMouseMovePortals = this.onMouseMovePortals.bind(this);
      this.onWindowResize = this.onWindowResize.bind(this);
      this.terrain = terrain;
      if (/^classCode/.test(this.terrain)) {
        this.terrain = '';  // Stop /play?classCode= from making us try to play a classCode campaign
      }
      if (window.serverConfig.picoCTF) { this.terrain = 'picoctf'; }
      this.editorMode = options != null ? options.editorMode : undefined;
      this.requiresSubscription = !me.isPremium();
      if (this.editorMode) {
        if (this.terrain == null) { this.terrain = 'dungeon'; }
      }
      this.levelStatusMap = {};
      this.levelPlayCountMap = {};
      this.levelDifficultyMap = {};
      this.levelScoreMap = {};

      if (this.terrain === "hoc-2018") {
        $('body').append($("<img src='https://code.org/api/hour/begin_codecombat_play.png' style='visibility: hidden;'>"));
      }

      if (utils.getQueryVariable('hour_of_code')) {
        if (me.isStudent() || me.isTeacher()) {
          if (this.terrain === 'dungeon') {
            const newCampaign = 'intro';
            api.users.getCourseInstances({ userID: me.id, campaignSlug: newCampaign }, { data: { project: '_id' } })
            .then(courseInstances => {
              if (courseInstances.length) {
                const courseInstanceID = _.first(courseInstances)._id;
                return application.router.navigate(`/play/${newCampaign}?course-instance=${courseInstanceID}`, { trigger: true, replace: true });
              } else {
                application.router.navigate((me.isStudent() ? '/students' : '/teachers'), {trigger: true, replace: true});
                return noty({text: 'Please create or join a classroom first', layout: 'topCenter', timeout: 8000, type: 'success'});
              }
            });
            return;
          }
        }
        if (this.terrain === 'game-dev-hoc') {
          if (window.tracker != null) {
            window.tracker.trackEvent('Start HoC Campaign', {label: 'game-dev-hoc'});
          }
        }
        me.set('hourOfCode', true);
        me.patch();
        const pixelCode = (() => { switch (this.terrain) {
          case 'game-dev-hoc': return 'code_combat_gamedev';
          case 'game-dev-hoc-2': return 'code_combat_build_arcade';
          case 'ai-league-hoc': return 'codecombat_esports';
          case 'goblins-hoc': return 'codecombat_goblins';
          default: return 'code_combat';
        } })();
        $('body').append($(`<img src='https://code.org/api/hour/begin_${pixelCode}.png' style='visibility: hidden;'>`));
      } else if (me.isTeacher() && !utils.getQueryVariable('course-instance') &&
          !application.getHocCampaign() && (!this.terrain === "hoc-2018")) {
        // redirect teachers away from home campaigns
        application.router.navigate('/teachers', { trigger: true, replace: true });
        return;
      } else if (location.pathname === '/paypal/subscribe-callback') {
        this.payPalToken = utils.getQueryVariable('token');
        api.users.executeBillingAgreement({userID: me.id, token: this.payPalToken})
        .then(billingAgreement => {
          const value = Math.round(parseFloat(__guard__(__guard__(__guard__(billingAgreement != null ? billingAgreement.plan : undefined, x2 => x2.payment_definitions), x1 => x1[0].amount), x => x.value) != null ? __guard__(__guard__(__guard__(billingAgreement != null ? billingAgreement.plan : undefined, x2 => x2.payment_definitions), x1 => x1[0].amount), x => x.value) : 0) * 100);
          if (application.tracker != null) {
            application.tracker.trackEvent('Finished subscription purchase', { value, service: 'paypal' });
          }
          noty({text: $.i18n.t('subscribe.confirmation'), layout: 'topCenter', timeout: 8000});
          return me.fetch({cache: false, success: () => (typeof this.render === 'function' ? this.render() : undefined)});
      }).catch(err => {
          return console.error(err);
        });
      }

      if (userUtils.shouldShowLibraryLoginModal() && me.isAnonymous()) {
        this.openModalView(new CreateAccountModal({ startOnPath: 'individual-basic' }));
      }

      if (window.serverConfig.picoCTF) {
        this.supermodel.addRequestResource({url: '/picoctf/problems', success: picoCTFProblems => {
          this.picoCTFProblems = picoCTFProblems;

        }}).load();
      } else {
        if (!this.editorMode) {
          this.sessions = this.supermodel.loadCollection(new LevelSessionsCollection(), 'your_sessions', {cache: false}, 1).model;
          this.listenToOnce(this.sessions, 'sync', this.onSessionsLoaded);
        }
        if (!this.terrain) {
          this.campaigns = this.supermodel.loadCollection(new CampaignsCollection(), 'campaigns', null, 1).model;
          this.listenToOnce(this.campaigns, 'sync', this.onCampaignsLoaded);
          return;
        }
      }

      this.campaign = new Campaign({_id:this.terrain});
      this.campaign = this.supermodel.loadModel(this.campaign).model;

      // Temporary attempt to make sure all earned rewards are accounted for. Figure out a better solution...
      this.earnedAchievements = new CocoCollection([], {url: '/db/earned_achievement', model:EarnedAchievement, project: ['earnedRewards']});
      this.listenToOnce(this.earnedAchievements, 'sync', function() {
        const earned = me.get('earned');
        let hadMissedAny = false;
        for (var m of Array.from(this.earnedAchievements.models)) {
          var loadedEarned;
          if (!(loadedEarned = m.get('earnedRewards'))) { continue; }
          for (var group of ['heroes', 'levels', 'items']) {
            if (!loadedEarned[group]) { continue; }
            for (var reward of Array.from(loadedEarned[group])) {
              if (!Array.from(earned[group]).includes(reward)) {
                console.warn('Filling in a gap for reward', group, reward);
                earned[group].push(reward);
                hadMissedAny = true;
              }
            }
          }
        }
        if (hadMissedAny) {
          return (window.tracker != null ? window.tracker.trackEvent('Fixed Missing Achievement Reward', {category: 'World Map', label: this.terrain}) : undefined);
        }
      });

      this.supermodel.loadCollection(this.earnedAchievements, 'achievements', {cache: false});

      if (utils.getQueryVariable('course-instance') != null) {
        this.courseLevelsFake = {};
        this.courseInstanceID = utils.getQueryVariable('course-instance');
        this.courseInstance = new CourseInstance({_id: this.courseInstanceID});
        const jqxhr = this.courseInstance.fetch();
        this.supermodel.trackRequest(jqxhr);
        new Promise(jqxhr.then).then(() => {
          const courseID = this.courseInstance.get('courseID');

          this.course = new Course({_id: courseID});
          this.supermodel.trackRequest(this.course.fetch());
          if (this.courseInstance.get('classroomID')) {
            const classroomID = this.courseInstance.get('classroomID');
            this.classroom = new Classroom({_id: classroomID});
            this.supermodel.trackRequest(this.classroom.fetch());
            return this.listenToOnce(this.classroom, 'sync', () => {
              me.setLastClassroomItems(this.classroom.get('classroomItems', true));
              this.updateClassroomSessions();
              this.render();
              this.courseInstance.sessions = new CocoCollection([], {
                url: this.courseInstance.url() + '/course-level-sessions/' + me.id,
                model: LevelSession
              });
              this.supermodel.loadCollection(this.courseInstance.sessions, {
                data: { project: 'state.complete,level.original,playtime,changed,state.topScores' }
              });
              this.courseInstance.sessions.comparator = 'changed';
              this.listenToOnce(this.courseInstance.sessions, 'sync', () => {
                this.courseStats = this.classroom.statsForSessions(this.courseInstance.sessions, this.course.id);
                return this.render();
              });
              this.courseLevels = new Levels();
              this.supermodel.trackRequest(this.courseLevels.fetchForClassroomAndCourse(classroomID, courseID, {
                data: { project: 'concepts,practice,assessment,primerLanguage,type,slug,name,original,description,shareable,i18n' }
              })
              );
              return this.listenToOnce(this.courseLevels, 'sync', () => {
                let idx, k, v;
                const existing = this.campaign.get('levels');
                const courseLevels = this.courseLevels.toArray();
                const classroomCourse = _.find(globalVar.currentView.classroom.get('courses'), {_id:globalVar.currentView.course.id});
                const levelPositions = {};
                for (var level of Array.from(classroomCourse.levels)) {
                  if (level.position) { levelPositions[level.original] = level.position; }
                }
                for (k in courseLevels) {
                  v = courseLevels[k];
                  idx = v.get('original');
                  if (!existing[idx]) {
                    // a level which has been removed from the campaign but is saved in the course
                    this.courseLevelsFake[idx] = v.toJSON();
                  } else {
                    this.courseLevelsFake[idx] = existing[idx];
                    // carry over positions stored in course, if there are any
                    if (levelPositions[idx]) {
                      this.courseLevelsFake[idx].position = levelPositions[idx];
                    }
                  }
                  this.courseLevelsFake[idx].courseIdx = parseInt(k);
                  this.courseLevelsFake[idx].requiresSubscription = false;
                }
                // Fill in missing positions, for courses which have levels that no longer exist in campaigns
                for (k in courseLevels) {
                  v = courseLevels[k];
                  k = parseInt(k);
                  idx = v.get('original');
                  if (!this.courseLevelsFake[idx].position) {
                    var nextPosition, prevPosition;
                    var prevLevel = courseLevels[k-1];
                    var nextLevel = courseLevels[k+1];
                    if (prevLevel && nextLevel) {
                      var prevIdx = prevLevel.get('original');
                      var nextIdx = nextLevel.get('original');
                      prevPosition = this.courseLevelsFake[prevIdx].position;
                      nextPosition = this.courseLevelsFake[nextIdx].position;
                    }
                    if (prevPosition && nextPosition) {
                      // split the diff between the previous, next levels
                      this.courseLevelsFake[idx].position = {
                        x: (prevPosition.x + nextPosition.x)/2,
                        y: (prevPosition.y + nextPosition.y)/2
                      };
                    } else {
                      // otherwise just line them up along the bottom
                      var x = 10 + ((k / courseLevels.length) * 80);
                      this.courseLevelsFake[idx].position = { x, y: 10 };
                    }
                  }
                }
                return this.render();
            });
          });
          }
        });
      }

      this.listenToOnce(this.campaign, 'sync', this.getLevelPlayCounts);
      $(window).on('resize', this.onWindowResize);
      this.probablyCachedMusic = storage.load("loaded-menu-music");
      const musicDelay = this.probablyCachedMusic ? 1000 : 10000;
      const delayMusicStart = () => _.delay((() => { if (!this.destroyed) { return this.playMusic(); } }), musicDelay);
      this.playMusicTimeout = delayMusicStart();
      this.hadEverChosenHero = __guard__(me.get('heroConfig'), x => x.thangType);
      this.listenTo(me, 'change:purchased', function() { return this.renderSelectors('#gems-count'); });
      this.listenTo(me, 'change:spent', function() { return this.renderSelectors('#gems-count'); });
      this.listenTo(me, 'change:earned', function() { return this.renderSelectors('#gems-count'); });
      this.listenTo(me, 'change:heroConfig', function() { return this.updateHero(); });

      if (utils.getQueryVariable('hour_of_code') || (this.terrain === "hoc-2018")) {
        if (!sessionStorage.getItem(this.terrain)) {
          sessionStorage.setItem(this.terrain, "seen-modal");
          clearTimeout(this.playMusicTimeout);
          setTimeout(() => {
              let activity = 'ai-league';
              if (this.terrain === 'hoc-2018') { activity = 'teacher-gd'; }
              if (this.terrain === 'goblins-hoc') { activity = 'goblins'; }
              return this.openModalView(new HoCModal({
                activity,
                showVideo: this.terrain === "hoc-2018",
                onDestroy: () => {
                  if (this.destroyed) { return; }
                  delayMusicStart();
                  return this.highlightElement('.level.next', {delay: 500, duration: 60000, rotation: 0, sides: ['top']});
                }
              })
              );
            }
          , 0);
        }
      }

      if (window.tracker != null) {
        window.tracker.trackEvent('Loaded World Map', {category: 'World Map', label: this.terrain});
      }
    }

    destroy() {
      let ambientSound;
      if (this.setupManager != null) {
        this.setupManager.destroy();
      }
      this.$el.find('.ui-draggable').off().draggable('destroy');
      $(window).off('resize', this.onWindowResize);
      if (ambientSound = this.ambientSound) {
        // Doesn't seem to work; stops immediately.
        createjs.Tween.get(ambientSound).to({volume: 0.0}, 1500).call(() => ambientSound.stop());
      }
      if (this.musicPlayer != null) {
        this.musicPlayer.destroy();
      }
      clearTimeout(this.playMusicTimeout);
      clearInterval(this.portalScrollInterval);
      Backbone.Mediator.unsubscribe('audio-player:loaded', this.playAmbientSound, this);
      return super.destroy();
    }

    showLoading($el) {
      if (!this.campaign) {
        this.$el.find('.game-controls, .user-status').addClass('hidden');
        return this.$el.find('.portal .campaign-name span').text($.i18n.t('common.loading'));
      }
    }

    hideLoading() {
      if (!this.campaign) {
        return this.$el.find('.game-controls, .user-status').removeClass('hidden');
      }
    }

    openPromotionModal(e) {
      if (e) { if (window.tracker != null) {
        window.tracker.trackEvent('Click Promotion Modal Button');
      } }
      return this.openModalView(new PromotionModal());
    }

    openPlayItemsModal(e) {
      e.stopPropagation();
      return this.openModalView(new PlayItemsModal());
    }

    openPlayHeroesModal(e) {
      e.stopPropagation();
      return this.openModalView(new PlayHeroesModal());
    }

    openPlayAchievementsModal(e) {
      e.stopPropagation();
      return this.openModalView(new PlayAchievementsModal());
    }

    openBuyGemsModal(e) {
      e.stopPropagation();
      return this.openModalView(new BuyGemsModal());
    }

    openContactModal(e) {
      e.stopPropagation();
      return this.openModalView(new ContactModal());
    }

    openCreateAccountModal(e) {
      e.stopPropagation();
      return this.openModalView(new CreateAccountModal());
    }

    openAnonymousTeacherModal(e) {
      e.stopPropagation();
      this.openModalView(new AnonymousTeacherModal());
      return this.endHighlight();
    }

    onClickAmazonCampaign(e) {
      if (window.tracker != null) {
        window.tracker.trackEvent('Click Amazon Modal Button');
      }
      return this.openModalView(new AmazonHocModal({hideCongratulation: true}));
    }

    onClickAnonClassroomClose() { return __guard__(this.$el.find('#anonymous-classroom-signup-dialog'), x => x.hide()); }

    onClickAnonClassroomJoin() {
      const classCode = __guard__(this.$el.find('#anon-classroom-signup-code'), x => x.val());
      if (_.isEmpty(classCode)) { return; }
      if (window.tracker != null) {
        window.tracker.trackEvent('Anonymous Classroom Signup Modal Join Class', {category: 'Signup'}, classCode);
      }
      return application.router.navigate(`/students?_cc=${classCode}`, { trigger: true });
    }

    onClickAnonClassroomSignup() {
      if (window.tracker != null) {
        window.tracker.trackEvent('Anonymous Classroom Signup Modal Create Teacher', {category: 'Signup'});
      }
      return this.openModalView(new CreateAccountModal({startOnPath: 'teacher'}));
    }

    onClickVideosButton() {
      return this.openModalView(new CourseVideosModal({courseInstanceID: this.courseInstanceID, courseID: this.course.get('_id')}));
    }

    onClickEsportsButton(e) {
      if (this.$levelInfo != null) {
        this.$levelInfo.hide();
      }
      const arenaSlug = $(e.target).data('arena');
      if (window.tracker != null) {
        window.tracker.trackEvent('Click LevelInfo AI League Button', { category: 'World Map', label: arenaSlug });
      }
      this.$levelInfo = this.$el.find(`.level-info-container.league-arena-tooltip[data-arena='${arenaSlug}']`).show();
      console.log(this.$levelInfo, 'click it', arenaSlug);
      return this.adjustLevelInfoPosition(e);
    }

    onClickEsportsLink(e) {
      const arenaSlug = $(e.target).data('arena');
      return (window.tracker != null ? window.tracker.trackEvent('Click Play AI League Button', { category: 'World Map', label: arenaSlug }) : undefined);
    }

    getLevelPlayCounts() {
      let level;
      if (!me.isAdmin()) { return; }
      return;  // TODO: get rid of all this? It's redundant with new campaign editor analytics, unless we want to show player counts on leaderboards buttons.
      const success = levelPlayCounts => {
        if (this.destroyed) { return; }
        for (level of Array.from(levelPlayCounts)) {
          this.levelPlayCountMap[level._id] = {playtime: level.playtime, sessions: level.sessions};
        }
        if (this.fullyRendered) { return this.render(); }
      };

      const levelSlugs = ((() => {
        const result = [];
        const object = this.getLevels();
        for (var levelID in object) {
          level = object[levelID];
          result.push(level.slug);
        }
        return result;
      })());
      const levelPlayCountsRequest = this.supermodel.addRequestResource('play_counts', {
        url: '/db/level/-/play_counts',
        data: {ids: levelSlugs},
        method: 'POST',
        success
      }, 0);
      return levelPlayCountsRequest.load();
    }

    onLoaded() {
      if (this.isChinaOldBrowser()) {
        if (!storage.load('hideBrowserRecommendation')) {
          const BrowserRecommendationModal = require('views/core/BrowserRecommendationModal');
          this.openModalView(new BrowserRecommendationModal());
        }
      }

      if (this.isClassroom()) {
        this.updateClassroomSessions();
      } else {
        if (!this.editorMode) {
          for (var session of Array.from(this.sessions.models)) {
            if (this.levelStatusMap[session.get('levelID')] !== 'complete') {  // Don't overwrite a complete session with an incomplete one
              this.levelStatusMap[session.get('levelID')] = __guard__(session.get('state'), x => x.complete) ? 'complete' : 'started';
            }
            if (__guard__(session.get('state'), x1 => x1.difficulty)) { this.levelDifficultyMap[session.get('levelID')] = session.get('state').difficulty; }
          }
        }
      }

      if (!this.editorMode) { this.buildLevelScoreMap(); }
      // HoC: Fake us up a "mode" for HeroVictoryModal to return hero without levels realizing they're in a copycat campaign, or clear it if we started playing.
      if (((this.campaign != null ? this.campaign.get('type') : undefined) === 'hoc') || (me.isStudent() && !this.courseInstance && ((this.campaign != null ? this.campaign.get('slug') : undefined) === 'intro'))) {
        application.setHocCampaign(this.campaign.get('slug'));
      } else {
        application.setHocCampaign('');
      }

      if (this.fullyRendered) { return; }
      this.fullyRendered = true;
      this.render();
      this.checkForUnearnedAchievements();
      if (!__guard__(me.get('heroConfig'), x2 => x2.thangType)) { this.preloadTopHeroes(); }
      if (['forest', 'desert'].includes(this.terrain)) { this.$el.find('#campaign-status').delay(4000).animate({top: "-=58"}, 1000); }
      if (this.campaign && this.isRTL(utils.i18n(this.campaign.attributes, 'fullName'))) {
        this.$('.campaign-name').attr('dir', 'rtl');
      }
      if (!me.isInHourOfCode() && this.terrain) {
        let needle, needle1;
        if (me.get('name') && (needle = me.get('lastLevel'), ['forgetful-gemsmith', 'signs-and-portents', 'true-names'].includes(needle)) &&
        (me.level() < 5) && !((needle1 = me.get('ageRange'), ['18-24', '25-34', '35-44', '45-100'].includes(needle1))) &&
        !storage.load('sent-parent-email') && !(me.isPremium() || me.isStudent() || me.isTeacher())) {
          this.openModalView(new ShareProgressModal());
        }
      } else {
        this.maybeShowPendingAnnouncement();
      }

      // Roblox Modal:
      return this.maybeShowRobloxModal();
    }

    updateClassroomSessions() {
      if (this.classroom) {
        let session;
        const classroomLevels = this.classroom.getLevels();
        this.classroomLevelMap = _.zipObject(classroomLevels.map(l => l.get('original')), classroomLevels.models);
        const defaultLanguage = this.classroom.get('aceConfig').language;
        for (session of Array.from(this.sessions.slice())) {
          var classroomLevel = this.classroomLevelMap[session.get('level').original];
          if (!classroomLevel) {
            continue;
          }
          var expectedLanguage = classroomLevel.get('primerLanguage') || defaultLanguage;
          if (session.get('codeLanguage') !== expectedLanguage) {
            // console.log("Inside remove session")
            this.sessions.remove(session);
            continue;
          }
        }
        if (!this.editorMode) {
          for (session of Array.from(this.sessions.models)) {
            if (this.levelStatusMap[session.get('levelID')] !== 'complete') {  // Don't overwrite a complete session with an incomplete one
              this.levelStatusMap[session.get('levelID')] = __guard__(session.get('state'), x => x.complete) ? 'complete' : 'started';
            }
            if (__guard__(session.get('state'), x1 => x1.difficulty)) { this.levelDifficultyMap[session.get('levelID')] = session.get('state').difficulty; }
          }
          if (this.courseInstance.get('classroomID') === "5d12e7e36eea5a00ac71dc8f") {  // Tarena national final classroom
            if (!this.levelStatusMap['game-dev-2-final-project']) {  //make sure all players could access GD2 final on competition day
              return this.levelStatusMap['game-dev-2-final-project'] = 'started';
            }
          }
        }
      }
    }

    buildLevelScoreMap() {
      for (var session of Array.from(this.sessions.models)) {
        var levels = this.getLevels();
        if (!levels) { return; }
        var levelOriginal = __guard__(session.get('level'), x => x.original);
        if (!levelOriginal) { continue; }
        var level = levels[levelOriginal];
        var topScore = _.first(LevelSession.getTopScores({session: session.toJSON(), level}));
        this.levelScoreMap[levelOriginal] = topScore;
      }
    }

    userQualifiesForRobloxModal() {
      if (me.freeOnly()) { return false; }
      if (storage.load('roblox-clicked')) { return false; }
      if (userUtils.isInLibraryNetwork() || userUtils.libraryName() || me.get('isCreatedViaLibrary')) { return false; }
      if (me.isPremium()) { return true; }
      if (me.get('hourOfCode')) { return false; }
      if (storage.load('paywall-reached')) { return true; }
      return false;
    }

    maybeShowRobloxModal() {
      if (this.userQualifiesForRobloxModal()) {
        return $(".roblox-level").show();
      }
    }

    onRobloxLevelClick(e) {
      if (window.tracker != null) {
        window.tracker.trackEvent("Mine Explored", {engageAction: "campaign_level_click"});
      }
      return this.openModalView(new MineModal());
    }

    onHackStackLevelClick(e) {
      if (window.tracker != null) {
        window.tracker.trackEvent("HackStack Explored", {engageAction: "campaign_level_click"});
      }
      // Backbone.Mediator.publish 'router:navigate', route: '/ai/new_project'
      return window.open('/ai/new_project', '_blank');
    }

    setCampaign(campaign) {
      this.campaign = campaign;
      return this.render();
    }

    onSubscribed() {
      this.requiresSubscription = false;
      return this.render();
    }

    getRenderData(context) {
      let left;
      if (context == null) { context = {}; }
      context = super.getRenderData(context);
      context.campaign = this.campaign;
      context.levels = _.values($.extend(true, {}, (left = this.getLevels()) != null ? left : {}));
      if ((me.level() < 12) && (this.terrain === 'dungeon') && !this.editorMode) {
        context.levels = _.reject(context.levels, {slug: 'signs-and-portents'});
      }
      if (me.freeOnly()) {
        context.levels = _.reject(context.levels, level => {
          if ((['course', 'course-ladder'].includes(level.type)) && me.isStudent() && !this.courseInstance) { return true; }  // Too much hassle to get Wakka Maul working for CS1 with no classroom
          return level.requiresSubscription;
        });
      }
      if (features.brainPop) {
        context.levels = _.filter(context.levels, level => ['dungeons-of-kithgard', 'gems-in-the-deep', 'shadow-guard', 'enemy-mine', 'true-names'].includes(level.slug));
      }
      this.annotateLevels(context.levels);
      let count = this.countLevels(context.levels);
      if (this.courseStats != null) {
        context.levelsCompleted = this.courseStats.levels.numDone;
        context.levelsTotal = this.courseStats.levels.size;
      } else {
        context.levelsCompleted = count.completed;
        context.levelsTotal = count.total;
      }

      if ((this.sessions != null ? this.sessions.loaded : undefined) || this.editorMode) { this.determineNextLevel(context.levels); }
      // put lower levels in last, so in the world map they layer over one another properly.
      context.levels = (_.sortBy(context.levels, l => l.position.y)).reverse();
      if (this.campaign) { this.campaign.renderedLevels = context.levels; }

      context.levelStatusMap = this.levelStatusMap;
      context.levelDifficultyMap = this.levelDifficultyMap;
      context.levelPlayCountMap = this.levelPlayCountMap;
      context.isIPadApp = application.isIPadApp;
      context.picoCTF = window.serverConfig.picoCTF;
      context.requiresSubscription = this.requiresSubscription;
      context.editorMode = this.editorMode;
      context.adjacentCampaigns = _.filter(_.values(_.cloneDeep((this.campaign != null ? this.campaign.get('adjacentCampaigns') : undefined) || {})), ac => {
        if (me.isStudent() || me.isTeacher()) { return false; }
        if (ac.showIfUnlocked && !this.editorMode) {
          let needle;
          if (_.isString(ac.showIfUnlocked) && (needle = ac.showIfUnlocked, !Array.from(me.levels()).includes(needle))) { return false; }
          if (_.isArray(ac.showIfUnlocked) && (_.intersection(ac.showIfUnlocked, me.levels()).length <= 0)) { return false; }
        }
        ac.name = utils.i18n(ac, 'name');
        const styles = [];
        if (ac.color) { styles.push(`color: ${ac.color}`); }
        if (ac.rotation) { styles.push(`transform: rotate(${ac.rotation}deg)`); }
        if (ac.position == null) { ac.position = { x: 10, y: 10 }; }
        styles.push(`left: ${ac.position.x}%`);
        styles.push(`top: ${ac.position.y}%`);
        ac.style = styles.join('; ');
        return true;
      });
      context.marked = marked;
      context.i18n = utils.i18n;

      if (this.campaigns) {
        let campaign, levels;
        context.campaigns = {};
        for (campaign of Array.from(this.campaigns.models)) {
          if (campaign.get('slug') !== 'auditions') {
            context.campaigns[campaign.get('slug')] = campaign;
            if (this.sessions != null ? this.sessions.loaded : undefined) {
              var left1;
              levels = _.values($.extend(true, {}, (left1 = campaign.get('levels')) != null ? left1 : {}));
              if ((me.level() < 12) && (campaign.get('slug') === 'dungeon') && !this.editorMode) {
                levels = _.reject(levels, {slug: 'signs-and-portents'});
              }
              if (me.freeOnly()) {
                levels = _.reject(levels, level => level.requiresSubscription);
              }
              count = this.countLevels(levels);
              campaign.levelsTotal = count.total;
              campaign.levelsCompleted = count.completed;
              if (campaign.get('slug') === 'dungeon') {
                campaign.locked = false;
              } else if (!campaign.levelsTotal) {
                campaign.locked = true;
              } else {
                campaign.locked = true;
              }
            }
          }
        }
        for (campaign of Array.from(this.campaigns.models)) {
          var left2;
          var object = (left2 = campaign.get('adjacentCampaigns')) != null ? left2 : {};
          for (var acID in object) {
            var ac = object[acID];
            if (_.isString(ac.showIfUnlocked)) {
              var needle;
              if ((needle = ac.showIfUnlocked, Array.from(me.levels()).includes(needle))) { __guard__(_.find(this.campaigns.models, {id: acID}), x => x.locked = false); }
            } else if (_.isArray(ac.showIfUnlocked)) {
              if (_.intersection(ac.showIfUnlocked, me.levels()).length > 0) { __guard__(_.find(this.campaigns.models, {id: acID}), x1 => x1.locked = false); }
            }
          }
        }
      }

      if (this.terrain && _.string.contains(this.terrain, 'hoc') && me.isTeacher()) {
        context.showGameDevAlert = true;
      }

      return context;
    }

    afterRender() {
      super.afterRender();
      if ($.isTouchCapable() && (screen.availHeight < screen.availWidth)) {
        // scroll to vertical center on landscape touchscreens
        $('.portal').animate({
          scrollTop: ( $(".portals").height() - $(".portal").height() ) / 2
        }, 100);
      }
      this.onWindowResize();

      $('#anon-classroom-signup-code').keydown(function(event) {
        if (event.keyCode === 13) {
          // click join classroom button if enter is pressed in the text box
          return $("#anon-classroom-join-btn").click();
        }
      });

      if (!application.isIPadApp) {
        _.defer(() => (this.$el != null ? this.$el.find('.game-controls .btn:not(.poll)').addClass('has-tooltip').tooltip() : undefined));  // Have to defer or i18n doesn't take effect.
        const view = this;
        this.$el.find('.level, .campaign-switch').addClass('has-tooltip').tooltip().each(function() {
          if (!me.isAdmin() || !view.editorMode) { return; }
          return $(this).draggable().on('dragstop', function() {
            const bg = $('.map-background');
            const x = (($(this).offset().left - bg.offset().left) + ($(this).outerWidth() / 2)) / bg.width();
            const y = 1 - ((($(this).offset().top - bg.offset().top) + ($(this).outerHeight() / 2)) / bg.height());
            const e = { position: { x: (100 * x), y: (100 * y) }, levelOriginal: $(this).data('level-original'), campaignID: $(this).data('campaign-id') };
            if (e.levelOriginal) { view.trigger('level-moved', e); }
            if (e.campaignID) { return view.trigger('adjacent-campaign-moved', e); }
          });
        });
      }
      this.updateVolume();
      this.updateHero();
      if (!window.currentModal && !!this.fullyRendered) {
        this.highlightElement('.level.next', {delay: 500, duration: 60000, rotation: 0, sides: ['top']});
        if (this.editorMode) { this.createLines(); }
        if (this.options.showLeaderboard) {
          this.showLeaderboard(this.options.justBeatLevel != null ? this.options.justBeatLevel.get('slug') : undefined);
        } else if (this.shouldShow('promotion')) {
          const timesPointedOutPromotion = storage.load("pointed-out-promotion") || 0;
          if (!timesPointedOutPromotion) {
            this.openPromotionModal();
            storage.save("pointed-out-promotion", timesPointedOutPromotion + 1);
          } else if (timesPointedOutPromotion < 5) {
            this.$el.find('button.promotion-menu-icon').addClass('highlighted').tooltip('show');
            storage.save("pointed-out-promotion", timesPointedOutPromotion + 1);
          }
        }
      }
      return this.applyCampaignStyles();
    }

    onShiftS(e) {
      if (this.editorMode) { return this.generateCompletionRates(); }
    }

    generateCompletionRates() {
      if (!me.isAdmin()) { return; }
      const startDay = utils.getUTCDay(-14);
      const endDay = utils.getUTCDay(-1);
      $(".map-background").css('background-image','none');
      $(".gradient").remove();
      $("#campaign-view").css("background-color", "black");
      return (() => {
        const result = [];
        for (var level of Array.from((this.campaign != null ? this.campaign.renderedLevels : undefined) != null ? (this.campaign != null ? this.campaign.renderedLevels : undefined) : [])) {
          $(`div[data-level-slug=${level.slug}] .level-kind`).text("Loading...");
          var request = this.supermodel.addRequestResource('level_completions', {
            url: '/db/analytics_perday/-/level_completions',
            data: {startDay, endDay, slug: level.slug},
            method: 'POST',
            success: this.onLevelCompletionsLoaded.bind(this, level)
          }, 0);
          result.push(request.load());
        }
        return result;
      })();
    }

    onLevelCompletionsLoaded(level, data) {
      let color, offset, ratio;
      if (this.destroyed) { return; }
      let started = 0;
      let finished = 0;
      for (var day of Array.from(data)) {
        started += day.started != null ? day.started : 0;
        finished += day.finished != null ? day.finished : 0;
      }
      if (started === 0) {
        ratio = 0;
      } else {
        ratio = finished / started;
      }
      const rateDisplay = (ratio * 100).toFixed(1) + '%';
      $(`div[data-level-slug=${level.slug}] .level-kind`).html((started < 1000 ? started : (started / 1000).toFixed(1) + "k") + "<br>" + rateDisplay);
      if (ratio <= 0.5) {
        color = "rgb(255, 0, 0)";
      } else if ((ratio > 0.5) && (ratio <= 0.85)) {
        offset = (ratio - 0.5) / 0.35;
        color = `rgb(255, ${Math.round(256 * offset)}, 0)`;
      } else if ((ratio > 0.85) && (ratio <= 0.95)) {
        offset = (ratio - 0.85) / 0.1;
        color = `rgb(${Math.round(256 * (1-offset))}, 256, 0)`;
      } else {
        color = "rgb(0, 256, 0)";
      }
      $(`div[data-level-slug=${level.slug}] .level-kind`).css({"color":color, "width":256+"px", "transform":"translateX(-50%) translateX(15px)"});
      return $(`div[data-level-slug=${level.slug}]`).css("background-color", color);
    }

    afterInsert() {
      super.afterInsert();
      const preloadImages = ['/images/pages/base/modal_background.png', '/images/level/popover_background.png', '/images/level/code_palette_wood_background.png', '/images/level/code_editor_background_border.png'];
      _.delay((() => Array.from(preloadImages).map((img) => ($('<img/>')[0].src = img))), 2000);
      if (utils.getQueryVariable('signup') && !me.get('email')) {
        return this.promptForSignup();
      }
      if (!me.isPremium() && (this.isPremiumCampaign() || (this.options.worldComplete && !features.noAuth && !me.isInHourOfCode()))) {
        if (!me.get('email')) {
          return this.promptForSignup();
        }
        const campaignSlug = window.location.pathname.split('/')[2];
        return this.promptForSubscription(campaignSlug, 'premium campaign visited');
      }
    }

    promptForSignup() {
      if (this.terrain && Array.from(this.terrain).includes('hoc')) { return; }
      if (features.noAuth || ((this.campaign != null ? this.campaign.get('type') : undefined) === 'hoc')) { return; }
      this.endHighlight();
      return this.openModalView(new CreateAccountModal({supermodel: this.supermodel}));
    }

    promptForSubscription(slug, label) {
      this.paywallReached();
      if ((this.campaign != null ? this.campaign.get('type') : undefined) === 'hoc') { return console.log('Game dev HoC does not encourage subscribing.'); }
      if (me.isStudent()) { return console.log("Students shouldn't be prompted to subscribe"); }
      this.endHighlight();
      this.openModalView(new SubscribeModal());
      // TODO: Added levelID on 2/9/16. Remove level property and associated AnalyticsLogEvent 'properties.level' index later.
      return window.tracker != null ? window.tracker.trackEvent('Show subscription modal', {category: 'Subscription', label, level: slug, levelID: slug}) : undefined;
    }

    isPremiumCampaign(slug) {
      if (!slug) { slug = window.location.pathname.split('/')[2]; }
      if (!slug) { return; }
      if (Array.from(slug).includes('hoc')) { return false; }
      return /campaign-(game|web)-dev-\d/.test(slug);
    }

    paywallReached() {
      storage.save('paywall-reached', true);
      return this.maybeShowRobloxModal();
    }

    annotateLevels(orderedLevels) {
      let level, levelIndex;
      if (this.isClassroom()) { return; }

      let betaLevelIndex = 0;
      let betaLevelCompletedIndex = 0;
      for (levelIndex = 0; levelIndex < orderedLevels.length; levelIndex++) {
        var needle;
        level = orderedLevels[levelIndex];
        if (level.position == null) { level.position = { x: 10, y: 10 }; }
        level.locked = !me.ownsLevel(level.original);
        if ((level.slug === 'kithgard-mastery') && (this.calculateExperienceScore() === 0)) { level.locked = true; }
        if (level.requiresSubscription && this.requiresSubscription && me.isInHourOfCode()) { level.locked = true; }
        if (['started', 'complete'].includes(this.levelStatusMap[level.slug])) { level.locked = false; }
        if (this.editorMode) { level.locked = false; }
        if ((needle = this.campaign != null ? this.campaign.get('name') : undefined, ['Auditions', 'Intro'].includes(needle))) { level.locked = false; }
        if (me.isInGodMode()) { level.locked = false; }
        if (level.adminOnly && !['started', 'complete'].includes(this.levelStatusMap[level.slug])) { level.disabled = true; }
        if (me.isInGodMode()) { level.disabled = false; }

        level.color = 'rgb(255, 80, 60)';
        if (!this.isClassroom() && ((this.campaign != null ? this.campaign.get('type') : undefined) !== 'hoc')) {
          if (level.requiresSubscription) { level.color = 'rgb(80, 130, 200)'; }
        }
          //level.color = 'rgb(200, 80, 200)' if level.adventurer  # Disable adventurer stuff for now

        if (level.locked) { level.color = 'rgb(193, 193, 193)'; }
        level.unlocksHero = __guard__(_.find(level.rewards, 'hero'), x => x.hero);
        if (level.unlocksHero) {
          var needle1;
          level.purchasedHero = (needle1 = level.unlocksHero, Array.from((__guard__(me.get('purchased'), x1 => x1.heroes) || [])).includes(needle1));
        }

        level.unlocksItem = __guard__(_.find(level.rewards, 'item'), x2 => x2.item);
        level.unlocksPet = utils.petThangIDs.indexOf(level.unlocksItem) !== -1;

        if (this.classroom != null) {
          level.unlocksItem = false;
          level.unlocksPet = false;
        }

        if (window.serverConfig.picoCTF) {
          var problem;
          if (problem = _.find(this.picoCTFProblems || [], {pid: level.picoCTFProblem})) {
            if (problem.unlocked || (level.slug === 'digital-graffiti')) { level.locked = false; }
            //level.locked = false  # Testing to see all levels
            level.description = `\
### ${problem.name}
${level.description || problem.description}

${problem.category} - ${problem.score} points\
`;
            if (problem.solved) { level.color = 'rgb(80, 130, 200)'; }
          }
        }

        level.hidden = level.locked && ((this.campaign != null ? this.campaign.get('type') : undefined) !== 'hoc');
        if (level.concepts != null ? level.concepts.length : undefined) {
          level.displayConcepts = level.concepts;
          var maxConcepts = 6;
          if (level.displayConcepts.length > maxConcepts) {
            level.displayConcepts = level.displayConcepts.slice(-maxConcepts);
          }
        }

        level.unlockedInSameCampaign = levelIndex < 5;  // First few are always counted (probably unlocked in previous campaign)
        for (var otherLevel of Array.from(orderedLevels)) {
          if (!level.unlockedInSameCampaign && (otherLevel !== level)) {
            for (var reward of Array.from((otherLevel.rewards != null ? otherLevel.rewards : []))) {
              if (reward.level) {
                if (!level.unlockedInSameCampaign) { level.unlockedInSameCampaign = reward.level === level.original; }
              }
            }
          }
        }

        if ((level.releasePhase === 'internalRelease') && !(me.isAdmin() || me.isArtisan() || me.isInGodMode() || this.editorMode)) {
          level.hidden = (level.locked = (level.disabled = true));
        } else if ((level.releasePhase === 'beta') && !this.editorMode) {
          var experimentValue = me.getM7ExperimentValue();
          if (experimentValue === 'beta') {
            level.disabled = false;
            level.unlockedInSameCampaign = true;
            if (betaLevelIndex === betaLevelCompletedIndex) {
              // All preceding beta levels, if any, have been completed, so this one is unlocked
              level.locked = (level.hidden = false);
              level.color = 'rgb(255, 80, 60)';
            } else {
              // This beta level is not unlocked yet
              level.locked = (level.hidden = true);
              level.color = 'rgb(193, 193, 193)';
            }
            ++betaLevelIndex;
            if (this.levelStatusMap[level.slug] === 'complete') { ++betaLevelCompletedIndex; }
          } else {
            level.hidden = (level.locked = (level.disabled = true));
          }
        }
      }
      if (betaLevelIndex && (betaLevelCompletedIndex < betaLevelIndex)) {
        // Lock all non-beta levels until beta levels are completed
        for (levelIndex = 0; levelIndex < orderedLevels.length; levelIndex++) {
          level = orderedLevels[levelIndex];
          if ((level.releasePhase !== 'beta') && !level.locked) {
            level.locked = (level.hidden = true);
            level.color = 'rgb(193, 193, 193)';
          }
        }
      }
      return null;
    }

    countLevels(orderedLevels) {
      let level;
      const count = {total: 0, completed: 0};

      if ((this.campaign != null ? this.campaign.get('type') : undefined) === 'hoc') {
        // HoC: Just order left-to-right instead of looking at unlocks, which we don't use for this copycat campaign
        orderedLevels = _.sortBy(orderedLevels, level => level.position.x);
        for (level of Array.from(orderedLevels)) { if (this.levelStatusMap[level.slug] === 'complete') { count.completed++; } }
        count.total = orderedLevels.length;
        return count;
      }

      for (let levelIndex = 0; levelIndex < orderedLevels.length; levelIndex++) {
        var needle;
        level = orderedLevels[levelIndex];
        if (level.locked == null) { this.annotateLevels(orderedLevels); }  // Annotate if we haven't already.
        if (level.disabled) { continue; }
        var completed = this.levelStatusMap[level.slug] === 'complete';
        var started = this.levelStatusMap[level.slug] === 'started';
        if ((level.unlockedInSameCampaign || !level.locked) && (started || completed || !(level.locked && level.practice && (needle = level.slug.substring(level.slug.length - 2), ['-a', '-b', '-c', '-d'].includes(needle))))) { ++count.total; }
        if (completed) { ++count.completed; }
      }

      return count;
    }

    showLeaderboard(levelSlug) {
      const leaderboardModal = new LeaderboardModal({supermodel: this.supermodel, levelSlug});
      return this.openModalView(leaderboardModal);
    }

    isClassroom() { return (this.courseInstanceID != null); }

    determineNextLevel(orderedLevels) {
      let level;
      if (this.isClassroom()) {
        if (this.courseStats != null) { this.applyCourseLogicToLevels(orderedLevels); }
        return true;
      }

      if (me.getM7ExperimentValue() === 'beta') {
        // Point out next experimental level, if any are incomplete
        for (level of Array.from(orderedLevels)) {
          if ((level.releasePhase === 'beta') && (this.levelStatusMap[level.slug] !== 'complete')) {
            level.next = true;
            return;
          }
        }
      }

      let dontPointTo = ['lost-viking', 'kithgard-mastery'];  // Challenge levels we don't want most players bashing heads against
      const subscriptionPrompts = [{slug: 'boom-and-bust', unless: 'defense-of-plainswood'}];

      if ((this.campaign != null ? this.campaign.get('type') : undefined) === 'hoc') {
        // HoC: Just order left-to-right instead of looking at unlocks, which we don't use for this copycat campaign
        orderedLevels = _.sortBy(orderedLevels, level => level.position.x);
        for (level of Array.from(orderedLevels)) {
          if (this.levelStatusMap[level.slug] !== 'complete') {
            level.next = true;
            // Unlock and re-annotate this level
            // May not be unlocked/awarded due to different HoC progression using mostly shared levels
            level.locked = false;
            level.hidden = level.locked;
            level.disabled = false;
            level.color = 'rgb(255, 80, 60)';
            return;
          }
        }
      }

      const findNextLevel = (level, practiceOnly) => {
        for (var nextLevelOriginal of Array.from(level.nextLevels)) {
          var nextLevel = _.find(orderedLevels, {original: nextLevelOriginal});
          if (!nextLevel || nextLevel.locked) { continue; }
          if (practiceOnly && !this.campaign.levelIsPractice(nextLevel)) { continue; }
          if (this.campaign.levelIsAssessment(nextLevel)) { continue; }
          if (this.campaign.levelIsAssessment(level) && this.campaign.levelIsPractice(nextLevel)) { continue; }

          // If it's a challenge level, we efficiently determine whether we actually do want to point it out.
          // 2021-09-21: disabling for now, guessing it doesn't work well and makes experiments harder
          if (false && (nextLevel.slug === 'kithgard-mastery') && !this.levelStatusMap[nextLevel.slug] && (this.calculateExperienceScore() >= 3)) {
            var timesPointedOut;
            if (!((timesPointedOut = storage.load(`pointed-out-${nextLevel.slug}`) || 0) > 3)) {
              // We may determineNextLevel more than once per render, so we can't just do this once. But we do give up after a couple highlights.
              dontPointTo = _.without(dontPointTo, nextLevel.slug);
              storage.save(`pointed-out-${nextLevel.slug}`, timesPointedOut + 1);
            }
          }

          // Should we point this level out?
          if (!nextLevel.disabled && (this.levelStatusMap[nextLevel.slug] !== 'complete') && !Array.from(dontPointTo).includes(nextLevel.slug) &&
          !nextLevel.replayable && (
            me.isPremium() || !nextLevel.requiresSubscription || //nextLevel.adventurer or  # Disable adventurer stuff for now
            _.any(subscriptionPrompts, prompt => (nextLevel.slug === prompt.slug) && !this.levelStatusMap[prompt.unless])
          )) {
            nextLevel.next = true;
            return true;
          }
        }
        return false;
      };

      let foundNext = false;
      for (let levelIndex = 0; levelIndex < orderedLevels.length; levelIndex++) {
        // Iterate through all levels in order and look to find the first unlocked one that meets all our criteria for being pointed out as the next level.
        level = orderedLevels[levelIndex];
        if (this.campaign.get('type') === 'course') {
          level.nextLevels = [];
          for (var nextLevelIndex = 0; nextLevelIndex < orderedLevels.length; nextLevelIndex++) {
            var nextLevel = orderedLevels[nextLevelIndex];
            if (nextLevelIndex > levelIndex) {
              if (nextLevel.practice && level.nextLevels.length) { continue; }
              if (level.practice && !nextLevel.practice) { break; }
              level.nextLevels.push(nextLevel.original);
              if (!nextLevel.practice) { break; }
            }
          }
        } else {
          level.nextLevels = (Array.from(level.rewards != null ? level.rewards : []).filter((reward) => reward.level).map((reward) => reward.level));
        }
        if (!foundNext && !this.campaign.levelIsAssessment(level)) { foundNext = findNextLevel(level, true); } // Check practice levels first
        if (!foundNext) { foundNext = findNextLevel(level, false); }
      }

      if (!foundNext && orderedLevels[0] && !orderedLevels[0].locked && (this.levelStatusMap[orderedLevels[0].slug] !== 'complete')) {
        return orderedLevels[0].next = true;
      }
    }

    calculateExperienceScore() {
      let needle;
      const adultPoint = (needle = me.get('ageRange'), ['18-24', '25-34', '35-44', '45-100'].includes(needle));  // They have to have answered the poll for this, likely after Shadow Guard.
      let speedPoints = 0;
      for (var [levelSlug, speedThreshold] of [['dungeons-of-kithgard', 50], ['gems-in-the-deep', 55], ['shadow-guard', 55], ['forgetful-gemsmith', 40], ['true-names', 40]]) {
        if (__guard__(_.find(this.sessions != null ? this.sessions.models : undefined, session => session.get('levelID') === levelSlug), x => x.attributes.playtime) <= speedThreshold) {
          ++speedPoints;
        }
      }
      const experienceScore = adultPoint + speedPoints;  // 0-6 score of how likely we think they are to be experienced and ready for Kithgard Mastery
      return experienceScore;
    }

    createLines() {
      return Array.from((this.campaign != null ? this.campaign.renderedLevels : undefined) != null ? (this.campaign != null ? this.campaign.renderedLevels : undefined) : []).map((level) =>
        (() => {
          const result = [];
          for (var nextLevelOriginal of Array.from(level.nextLevels != null ? level.nextLevels : [])) {
            var nextLevel;
            if (nextLevel = _.find(this.campaign.renderedLevels, {original: nextLevelOriginal})) {
              result.push(this.createLine(level.position, nextLevel.position));
            } else {
              result.push(undefined);
            }
          }
          return result;
        })());
    }

    createLine(o1, o2) {
      const mapHeight = parseFloat($(".map").css("height"));
      const mapWidth = parseFloat($(".map").css("width"));
      if (!(mapHeight > 0)) { return; }
      const ratio =  mapWidth / mapHeight;
      const p1 = {x: o1.x, y: o1.y / ratio};
      const p2 = {x: o2.x, y: o2.y / ratio};
      const length = Math.sqrt(Math.pow(p1.x - p2.x , 2) + Math.pow(p1.y - p2.y, 2));
      const angle = (Math.atan2(p1.y - p2.y, p2.x - p1.x) * 180) / Math.PI;
      const transform = `translateY(-50%) translateX(-50%) rotate(${angle}deg) translateX(50%)`;
      const line = $('<div>').appendTo('.map').addClass('next-level-line').css({transform, width: length + '%', left: o1.x + '%', bottom: (o1.y - 0.5) + '%'});
      return line.append($('<div class="line">')).append($('<div class="point">'));
    }

    applyCampaignStyles() {
      let backgroundColor, backgrounds;
      if (!(this.campaign != null ? this.campaign.loaded : undefined)) { return; }
      if ((backgrounds = this.campaign.get('backgroundImage')) && backgrounds.length) {
        backgrounds = _.sortBy(backgrounds, 'width');
        backgrounds.reverse();
        const rules = [];
        for (let i = 0; i < backgrounds.length; i++) {
          var background = backgrounds[i];
          var rule = `#campaign-view .map-background { background-image: url(/file/${background.image}); }`;
          if (i) { rule = `@media screen and (max-width: ${background.width}px) { ${rule} }`; }
          rules.push(rule);
        }
        utils.injectCSS(rules.join('\n'));
      }
      if (backgroundColor = this.campaign.get('backgroundColor')) {
        const backgroundColorTransparent = this.campaign.get('backgroundColorTransparent');
        this.$el.css('background-color', backgroundColor);
        for (var pos of ['top', 'right', 'bottom', 'left']) {
          this.$el.find(`.${pos}-gradient`).css('background-image', `linear-gradient(to ${pos}, ${backgroundColorTransparent} 0%, ${backgroundColor} 100%)`);
        }
      }
      return this.playAmbientSound();
    }

    onMouseEnterPortals(e) {
      if (!(this.campaigns != null ? this.campaigns.loaded : undefined) || !(this.sessions != null ? this.sessions.loaded : undefined)) { return; }
      this.portalScrollInterval = setInterval(this.onMouseMovePortals, 100);
      return this.onMouseMovePortals(e);
    }

    onMouseLeavePortals(e) {
      if (!this.portalScrollInterval) { return; }
      clearInterval(this.portalScrollInterval);
      return this.portalScrollInterval = null;
    }

    onMouseMovePortals(e) {
      if (!this.portalScrollInterval) { return; }
      const $portal = this.$el.find('.portal');
      const $portals = this.$el.find('.portals');
      if (e) {
        this.portalOffsetX = Math.round(Math.max(0, e.clientX - $portal.offset().left));
      }
      const bodyWidth = $('body').innerWidth();
      const fraction = this.portalOffsetX / bodyWidth;
      if (0.2 < fraction && fraction < 0.8) { return; }
      const direction = fraction < 0.5 ? 1 : -1;
      const magnitude = (0.2 * bodyWidth * (direction === -1 ? fraction - 0.8 : 0.2 - fraction)) / 0.2;
      const portalsWidth = 2853;  // TODO: if we add campaigns or change margins, this will get out of date...
      let scrollTo = $portals.offset().left + (direction * magnitude);
      scrollTo = Math.max(bodyWidth - portalsWidth, scrollTo);
      scrollTo = Math.min(0, scrollTo);
      return $portals.stop().animate({marginLeft: scrollTo}, 100, 'linear');
    }

    onSessionsLoaded(e) {
      if (this.editorMode) { return; }
      this.render();
      if (!me.get('anonymous') && !me.inEU() && !window.serverConfig.picoCTF) { return this.loadUserPollsRecord(); }
    }

    onCampaignsLoaded(e) {
      return this.render();
    }

    preloadLevel(levelSlug) {
      let courseID;
      const levelURL = `/db/level/${levelSlug}`;
      let level = new Level().setURL(levelURL);
      level = this.supermodel.loadModel(level, null, 0).model;

      // Note that this doesn't just preload the level. For sessions which require the
      // campaign to be included, it also creates the session. If this code is changed,
      // make sure to accommodate campaigns with free-in-certain-campaign-contexts levels,
      // such as game dev levels in game-dev-hoc.
      let sessionURL = `/db/level/${levelSlug}/session?campaign=${this.campaign.id}`;
      if (courseID = this.course != null ? this.course.get('_id') : undefined) {
        sessionURL += `&course=${courseID}`;
        if (this.courseInstanceID) {
          sessionURL += `&courseInstance=${this.courseInstanceID}`;
        }
      }

      this.preloadedSession = new LevelSession().setURL(sessionURL);
      this.listenToOnce(this.preloadedSession, 'sync', this.onSessionPreloaded);
      this.listenToOnce(this.preloadedSession, 'error', this.onSessionPreloadError);
      this.preloadedSession = this.supermodel.loadModel(this.preloadedSession, {cache: false}).model;
      return this.preloadedSession.levelSlug = levelSlug;
    }

    onSessionPreloaded(session) {
      let difficulty;
      session.url = function() { return '/db/level.session/' + this.id; };
      const levelElement = this.$el.find('.level-info-container:visible');
      if (session.levelSlug !== levelElement.data('level-slug')) { return; }
      if (!(difficulty = __guard__(session.get('state'), x => x.difficulty))) { return; }
      const badge = $(`<span class='badge'>${difficulty}</span>`);
      levelElement.find('.start-level .badge').remove();
      levelElement.find('.start-level').append(badge);
      return levelElement.toggleClass('has-loading-error', false);
    }

    onSessionPreloadError(session, error) {
      if (/requires a subscription to play/.test(__guard__(error != null ? error.responseJSON : undefined, x => x.message))) { return; }  // We handle this with SubscribeModal separately
      const levelElement = this.$el.find('.level-info-container:visible');
      if (session.levelSlug !== levelElement.data('level-slug')) { return; }
      levelElement.find('.level-error-message').text((error.responseJSON != null ? error.responseJSON.message : undefined) || `Cannot load this level--error ${error.statusCode || 500}`);
      return levelElement.toggleClass('has-loading-error', true);
    }

    onClickMap(e) {
      if (this.$levelInfo != null) {
        this.$levelInfo.hide();
      }
      if ((this.sessions != null ? this.sessions.models.length : undefined) < 3) {
        // Restore the next level higlight for very new players who might otherwise get lost.
        return this.highlightElement('.level.next', {delay: 500, duration: 60000, rotation: 0, sides: ['top']});
      }
    }

    onClickLevel(e) {
      e.preventDefault();
      e.stopPropagation();
      if (this.$levelInfo != null) {
        this.$levelInfo.hide();
      }
      const levelElement = $(e.target).parents('.level');
      const levelSlug = levelElement.data('level-slug');
      if (!levelSlug) { return; } // Roblox Modal
      const levelOriginal = levelElement.data('level-original');
      if (this.editorMode) {
        return this.trigger('level-clicked', levelOriginal);
      }
      this.$levelInfo = this.$el.find(`.level-info-container[data-level-slug=${levelSlug}]`).show();
      this.checkForCourseOption(levelOriginal);
      this.adjustLevelInfoPosition(e);
      this.endHighlight();
      return this.preloadLevel(levelSlug);
    }

    onDoubleClickLevel(e) {
      if (!this.editorMode) { return; }
      const levelElement = $(e.target).parents('.level');
      const levelOriginal = levelElement.data('level-original');
      return this.trigger('level-double-clicked', levelOriginal);
    }

    onClickStartLevel(e) {
      const levelElement = $(e.target).parents('.level-info-container');
      const levelSlug = levelElement.data('level-slug');
      const levelOriginal = levelElement.data('level-original');
      const level = _.find(_.values(this.getLevels()), {slug: levelSlug});

      let defaultAccess = me.get('hourOfCode') || ((this.campaign != null ? this.campaign.get('type') : undefined) === 'hoc') || ((this.campaign != null ? this.campaign.get('slug') : undefined) === 'intro') ? 'long' : 'short';
      if (new Date(me.get('dateCreated')) < new Date('2021-09-21')) {
        defaultAccess = 'all';
      }
      let access = me.getExperimentValue('home-content', defaultAccess);
      if (me.showChinaResourceInfo() || (me.get('country') === 'japan')) {
        access = 'short';
      }
      const freeAccessLevels = ((() => {
        const result = [];
        for (var fal of Array.from(utils.freeAccessLevels)) {           if (_.any([
        fal.access === 'short',
        (fal.access === 'medium') && ['medium', 'long', 'extended'].includes(access),
        (fal.access === 'long') && ['long', 'extended'].includes(access),
        (fal.access === 'extended') && (access === 'extended')
      ])) {
            result.push(fal.slug);
          }
        }
        return result;
      })());
      const requiresSubscription = level.requiresSubscription || ((access !== 'all') && !Array.from(freeAccessLevels).includes(level.slug));
      const canPlayAnyway = _.any([
        !this.requiresSubscription,
        //level.adventurer  # Disable adventurer stuff for now
        this.levelStatusMap[level.slug],
        this.campaign.get('type') === 'hoc',
        (level.releasePhase === 'beta') && (me.getM7ExperimentValue() === 'beta')
      ]);
      if (requiresSubscription && !canPlayAnyway) {
        return this.promptForSubscription(levelSlug, 'map level clicked');
      } else {
        this.startLevel(levelElement);
        return (window.tracker != null ? window.tracker.trackEvent('Clicked Start Level', {category: 'World Map', levelID: levelSlug}) : undefined);
      }
    }

    onClickCourseVersion(e) {
      const levelElement = $(e.target).parents('.level-info-container');
      const levelSlug = $(e.target).parents('.level-info-container').data('level-slug');
      const levelOriginal = levelElement.data('level-original');
      const courseID = $(e.target).parents('.course-version').data('course-id');
      const courseInstanceID = $(e.target).parents('.course-version').data('course-instance-id');

      const classroomLevel = this.classroomLevelMap != null ? this.classroomLevelMap[levelOriginal] : undefined;

      // If classroomItems is on, don't go to PlayLevelView directly.
      // Go through LevelSetupManager which will load required modals before going to PlayLevelView.
      if(me.showHeroAndInventoryModalsToStudents() && !(classroomLevel != null ? classroomLevel.isAssessment() : undefined)) {
        this.startLevel(levelElement, courseID, courseInstanceID);
        return (window.tracker != null ? window.tracker.trackEvent('Clicked Start Level', {category: 'World Map', levelID: levelSlug}) : undefined);
      } else {
        const url = `/play/level/${levelSlug}?course=${courseID}&course-instance=${courseInstanceID}`;
        return Backbone.Mediator.publish('router:navigate', {route: url});
      }
    }

    startLevel(levelElement, courseID=null, courseInstanceID=null) {
      let options;
      if (this.setupManager != null) {
        this.setupManager.destroy();
      }
      const levelSlug = levelElement.data('level-slug');
      const levelOriginal = levelElement.data('level-original');
      const classroomLevel = this.classroomLevelMap != null ? this.classroomLevelMap[levelOriginal] : undefined;
      if(me.showHeroAndInventoryModalsToStudents() && !(classroomLevel != null ? classroomLevel.isAssessment() : undefined)) {
        const codeLanguage = __guard__(this.classroomLevelMap != null ? this.classroomLevelMap[levelOriginal] : undefined, x => x.get('primerLanguage')) || __guard__(this.classroom != null ? this.classroom.get('aceConfig') : undefined, x1 => x1.language);
        options = {supermodel: this.supermodel, levelID: levelSlug, levelPath: levelElement.data('level-path'), levelName: levelElement.data('level-name'), hadEverChosenHero: this.hadEverChosenHero, parent: this, courseID, courseInstanceID, codeLanguage};
      } else {
        let session;
        if ((this.preloadedSession != null ? this.preloadedSession.loaded : undefined) && (this.preloadedSession.levelSlug === levelSlug)) { session = this.preloadedSession; }
        options = {supermodel: this.supermodel, levelID: levelSlug, levelPath: levelElement.data('level-path'), levelName: levelElement.data('level-name'), hadEverChosenHero: this.hadEverChosenHero, parent: this, session};
      }
      this.setupManager = new LevelSetupManager(options);
      if (!(this.setupManager != null ? this.setupManager.navigatingToPlay : undefined)) {
        if (this.$levelInfo != null) {
          this.$levelInfo.find('.level-info, .progress').toggleClass('hide');
        }
        this.listenToOnce(this.setupManager, 'open', function() {
          if (this.$levelInfo != null) {
            this.$levelInfo.find('.level-info, .progress').toggleClass('hide');
          }
          return (this.$levelInfo != null ? this.$levelInfo.hide() : undefined);
        });
        return this.setupManager.open();
      }
    }

    onClickViewSolutions(e) {
      const levelElement = $(e.target).parents('.level-info-container');
      const levelSlug = levelElement.data('level-slug');
      const level = _.find(_.values(this.getLevels()), {slug: levelSlug});
      if (['ladder', 'hero-ladder', 'course-ladder'].includes(level.type)) {  // Would use isType, but it's not a Level model
        return Backbone.Mediator.publish('router:navigate', {route: `/play/ladder/${levelSlug}`, viewClass: 'views/ladder/LadderView', viewArgs: [{supermodel: this.supermodel}, levelSlug]});
      } else {
        return this.showLeaderboard(levelSlug);
      }
    }

    adjustLevelInfoPosition(e) {
      if (!this.$levelInfo) { return; }
      if (this.$map == null) { this.$map = this.$el.find('.map'); }
      const mapOffset = this.$map.offset();
      const mapX = e.pageX - mapOffset.left;
      const mapY = e.pageY - mapOffset.top;
      const margin = 20;
      const width = this.$levelInfo.outerWidth();
      this.$levelInfo.css('left', Math.min(Math.max(margin, mapX - (width / 2)), this.$map.width() - width - margin));
      const height = this.$levelInfo.outerHeight();
      let top = mapY - this.$levelInfo.outerHeight() - 60;
      if (top < 100) {
        top = mapY + 60;
      }
      return this.$levelInfo.css('top', top);
    }

    onWindowResize(e) {
      let iPadHeight, resultingHeight, resultingWidth;
      const mapHeight = (iPadHeight = 1536);
      const mapWidth = {dungeon: 2350, forest: 2500, auditions: 2500, desert: 2411, mountain: 2422, glacier: 2421}[this.terrain] || 2350;
      const aspectRatio = mapWidth / mapHeight;
      const pageWidth = this.$el.width();
      const pageHeight = this.$el.height();
      const widthRatio = pageWidth / mapWidth;
      const heightRatio = pageHeight / mapHeight;
      // Make sure we can see the whole map, fading to background in one dimension.
      if (heightRatio <= widthRatio) {
        // Left and right margin
        resultingHeight = pageHeight;
        resultingWidth = resultingHeight * aspectRatio;
      } else {
        // Top and bottom margin
        resultingWidth = pageWidth;
        resultingHeight = resultingWidth / aspectRatio;
      }
      const resultingMarginX = (pageWidth - resultingWidth) / 2;
      const resultingMarginY = (pageHeight - resultingHeight) / 2;
      return this.$el.find('.map').css({width: resultingWidth, height: resultingHeight, 'margin-left': resultingMarginX, 'margin-top': resultingMarginY});
    }

    playAmbientSound() {
      let file;
      if (!me.get('volume')) { return; }
      if (this.ambientSound) { return; }
      if (!(file = __guard__(this.campaign != null ? this.campaign.get('ambientSound') : undefined, x => x[AudioPlayer.ext.substr(1)]))) { return; }
      const src = `/file/${file}`;
      if (!__guard__(AudioPlayer.getStatus(src), x1 => x1.loaded)) {
        AudioPlayer.preloadSound(src);
        Backbone.Mediator.subscribeOnce('audio-player:loaded', this.playAmbientSound, this);
        return;
      }
      this.ambientSound = createjs.Sound.play(src, {loop: -1, volume: 0.1});
      return createjs.Tween.get(this.ambientSound).to({volume: 0.5}, 1000);
    }

    playMusic() {
      this.musicPlayer = new MusicPlayer();
      const musicFile = '/music/music-menu';
      Backbone.Mediator.publish('music-player:play-music', {play: true, file: musicFile});
      if (!this.probablyCachedMusic) { return storage.save("loaded-menu-music", true); }
    }

    checkForCourseOption(levelOriginal) {
      const showButton = courseInstance => {
        return this.$el.find(`.course-version[data-level-original='${levelOriginal}']`).removeClass('hidden').data({'course-id': courseInstance.get('courseID'), 'course-instance-id': courseInstance.id});
      };

      if (this.courseInstance != null) {
        return showButton(this.courseInstance);
      } else {
        if (!__guard__(me.get('courseInstances'), x => x.length)) { return; }
        if (this.courseOptionsChecked == null) { this.courseOptionsChecked = {}; }
        if (this.courseOptionsChecked[levelOriginal]) { return; }
        this.courseOptionsChecked[levelOriginal] = true;
        const courseInstances = new CocoCollection([], {url: `/db/course_instance/-/find_by_level/${levelOriginal}`, model: CourseInstance});
        courseInstances.comparator = function(ci) { let left;
        return -((left = ci.get('members')) != null ? left : []).length; };
        this.supermodel.loadCollection(courseInstances, 'course_instances');
        return this.listenToOnce(courseInstances, 'sync', () => {
          let courseInstance;
          if (this.destroyed) { return; }
          if (!(courseInstance = courseInstances.models[0])) { return; }
          return showButton(courseInstance);
        });
      }
    }

    preloadTopHeroes() {
      if (window.serverConfig.picoCTF) { return; }
      return (() => {
        const result = [];
        for (var heroID of ['captain', 'knight']) {
          var url = `/db/thang.type/${ThangType.heroes[heroID]}/version`;
          if (this.supermodel.getModel(url)) { continue; }
          var fullHero = new ThangType();
          fullHero.setURL(url);
          result.push(this.supermodel.loadModel(fullHero));
        }
        return result;
      })();
    }

    updateVolume(volume) {
      if (volume == null) { let left;
      volume = (left = me.get('volume')) != null ? left : 1.0; }
      const classes = ['vol-off', 'vol-down', 'vol-up'];
      const button = $('#volume-button', this.$el);
      button.toggleClass('vol-off', volume <= 0.0);
      button.toggleClass('vol-down', 0.0 < volume && volume < 1.0);
      button.toggleClass('vol-up', volume >= 1.0);
      createjs.Sound.volume = volume === 1 ? 0.6 : volume;  // Quieter for now until individual sound FX controls work again.
      if (volume !== me.get('volume')) {
        me.set('volume', volume);
        me.patch();
        if (volume) { return this.playAmbientSound(); }
      }
    }

    onToggleVolume(e) {
      let newI;
      const button = $(e.target).closest('#volume-button');
      const classes = ['vol-off', 'vol-down', 'vol-up'];
      const volumes = [0, 0.4, 1.0];
      for (let i = 0; i < classes.length; i++) {
        var oldClass = classes[i];
        if (button.hasClass(oldClass)) {
          newI = (i + 1) % classes.length;
          break;
        } else if (i === (classes.length - 1)) {  // no oldClass
          newI = 2;
        }
      }
      return this.updateVolume(volumes[newI]);
    }

    onClickBack(e) {
      return Backbone.Mediator.publish('router:navigate', {
        route: "/play",
        viewClass: CampaignView,
        viewArgs: [{supermodel: this.supermodel}]
      });
    }

    onClickClearStorage(e) {
      localStorage.clear();
      return noty({
        text: 'Local storage cleared. Reload to view the original campaign.',
        layout: 'topCenter',
        timeout: 5000,
        type: 'information'
      });
    }

    updateHero() {
      let hero;
      if (!(hero = __guard__(me.get('heroConfig'), x => x.thangType))) { return; }
      for (var slug in ThangType.heroes) {
        var original = ThangType.heroes[slug];
        if (original === hero) {
          this.$el.find('.player-hero-icon').removeClass().addClass('player-hero-icon ' + slug);
          return;
        }
      }
      return console.error("CampaignView hero update couldn't find hero slug for original:", hero);
    }

    onClickPortalCampaign(e) {
      const campaign = $(e.target).closest('.campaign, .beta-campaign');
      if (campaign.is('.locked') || campaign.is('.silhouette')) { return; }
      const campaignSlug = campaign.data('campaign-slug');
      if (this.isPremiumCampaign(campaignSlug) && !me.isPremium()) {
        return this.promptForSubscription(campaignSlug, 'premium campaign clicked');
      }
      return Backbone.Mediator.publish('router:navigate', {
        route: `/play/${campaignSlug}`,
        viewClass: CampaignView,
        viewArgs: [{supermodel: this.supermodel}, campaignSlug]
      });
    }

    onClickCampaignSwitch(e) {
      const campaignSlug = $(e.target).data('campaign-slug');
      if (this.isPremiumCampaign(campaignSlug) && !me.isPremium()) {
        e.preventDefault();
        e.stopImmediatePropagation();
        return this.promptForSubscription(campaignSlug, 'premium campaign switch clicked');
      }
    }

    loadUserPollsRecord() {
      if (storage.load('ignored-poll')) { return; }
      const url = `/db/user.polls.record/-/user/${me.id}`;
      this.userPollsRecord = new UserPollsRecord().setURL(url);
      const onRecordSync = function() {
        if (this.destroyed) { return; }
        this.userPollsRecord.url = function() { return '/db/user.polls.record/' + this.id; };
        const lastVoted = new Date(this.userPollsRecord.get('changed') || 0);
        const interval = new Date() - lastVoted;
        if (interval > (22 * 60 * 60 * 1000)) {  // Wait almost a day before showing the next poll
          return this.loadPoll();
        } else {
          return console.log('Poll will be ready in', ((22 * 60 * 60 * 1000) - interval) / (60 * 60 * 1000), 'hours.');
        }
      };
      this.listenToOnce(this.userPollsRecord, 'sync', onRecordSync);
      this.userPollsRecord = this.supermodel.loadModel(this.userPollsRecord, null, 0).model;
      if (this.userPollsRecord.loaded) { return onRecordSync.call(this); }
    }

    loadPoll(url, forceShowPoll) {
      if (forceShowPoll == null) { forceShowPoll = false; }
      if (url == null) { url = `/db/poll/${this.userPollsRecord.id}/next`; }
      let tempLoadingPoll = new Poll().setURL(url);
      const onPollSync = function() {
        if (this.destroyed) { return; }
        tempLoadingPoll.url = function() { return '/db/poll/' + this.id; };
        this.poll = tempLoadingPoll;
        const delay = forceShowPoll ? 1000 : 5000;  // Wait a little bit before showing the poll
        return _.delay((() => (typeof this.activatePoll === 'function' ? this.activatePoll(forceShowPoll) : undefined)), delay);
      };
      const onPollError = function(poll, response, request) {
        if (response.status === 404) {
          console.log('There are no more polls left.');
        } else {
          console.error("Couldn't load poll:", response.status, response.statusText);
        }
        if (this.poll) {
          return delete this.poll;
        }
      };
      this.listenToOnce(tempLoadingPoll, 'sync', onPollSync);
      this.listenToOnce(tempLoadingPoll, 'error', onPollError);
      tempLoadingPoll = this.supermodel.loadModel(tempLoadingPoll, null, 0).model;
      if (tempLoadingPoll.loaded) { return onPollSync.call(this); }
    }

    activatePoll(forceShowPoll) {
      if (forceShowPoll == null) { forceShowPoll = false; }
      if (this.shouldShow('promotion')) { return; }
      const pollTitle = utils.i18n(this.poll.attributes, 'name');
      const $pollButton = this.$el.find('button.poll').removeClass('hidden').addClass('highlighted').attr({title: pollTitle}).addClass('has-tooltip').tooltip({title: pollTitle});
      if ((me.get('lastLevel') === 'shadow-guard') || forceShowPoll) {
        return this.showPoll();
      } else {
        $pollButton.tooltip('show');
        return _.delay((() => {
          if ($pollButton != null) {
            $pollButton.tooltip('hide');
          }
          if (!this.destroyed) {
            return storage.save('ignored-poll', true, 5);  //  Don't show again in next N minutes
          }
        }
        ), 20000);  // Don't leave the poll open forever
      }
    }

    showPoll() {
      if (!this.shouldShow('poll')) { return false; }
      const pollModal = new PollModal({supermodel: this.supermodel, poll: this.poll, userPollsRecord: this.userPollsRecord});
      this.openModalView(pollModal);
      const $pollButton = this.$el.find('button.poll');
      pollModal.on('vote-updated', () => $pollButton.removeClass('highlighted').tooltip('hide'));
      pollModal.once('trigger-next-poll', nextPollId => {
        return this.loadPoll('/db/poll/' + nextPollId, true);
      });
      pollModal.once('trigger-show-live-classes', () => {
        return this.openModalView(new LiveClassroomModal);
      });
      return pollModal.once('trigger-codequest-modal', () => {
        return this.openModalView(new Codequest2020Modal);
      });
    }

    onClickPremiumButton(e) {
      this.openModalView(new SubscribeModal());
      return (window.tracker != null ? window.tracker.trackEvent('Show subscription modal', {category: 'Subscription', label: 'campaignview premium button'}) : undefined);
    }

    onClickM7OffButton(e) {
      return noty({ text: $.i18n.t('play.confirm_m7_off'), layout: 'center', type: 'warning', buttons: [
        { text: 'Yes', onClick: $noty => {
          if (me.getM7ExperimentValue() === 'beta') {
            me.updateExperimentValue('m7', 'control');
            $noty.close();
            return this.render();
          }
        }
        }, { text: 'No', onClick($noty) { return $noty.close(); } }]
      });
    }

    getLoadTrackingTag() {
      return __guardMethod__(this.campaign, 'get', o => o.get('slug')) || 'overworld';
    }

    mergeWithPrerendered(el) {
      return true;
    }

    checkForUnearnedAchievements() {
      if (!this.campaign || !globalVar.currentView.sessions) { return; }

      // Another layer attempting to make sure users unlock levels properly.

      // Every time the user goes to the campaign view (after initial load),
      // load achievements for that campaign.
      // Look for any achievements where the related level is complete, but
      // the reward level is not earned.
      // Try to create EarnedAchievements for each such Achievement found.

      const achievements = new Achievements();

      return achievements.fetchForCampaign(
        this.campaign.get('slug'),
        { data: { project: 'related,rewards,name' } })

      .done(achievements => {
        if (this.destroyed) { return; }
        const sessionsComplete = _(globalVar.currentView.sessions.models)
          .filter(s => s.get('levelID'))
          .filter(s => s.get('state') && s.get('state').complete)
          .map(s => [s.get('levelID'), s.id])
          .value();

        const sessionsCompleteMap = _.zipObject(sessionsComplete);

        const campaignLevels = this.getLevels();

        const levelsEarned = _(__guard__(me.get('earned'), x => x.levels))
          .filter(levelOriginal => campaignLevels[levelOriginal])
          .map(levelOriginal => campaignLevels[levelOriginal].slug)
          .filter()
          .value();

        const levelsEarnedMap = _.zipObject(
          levelsEarned,
          _.times(levelsEarned.length, () => true)
        );

        const levelAchievements = _.filter(achievements,
          a => a.rewards && a.rewards.levels && a.rewards.levels.length);

        let hadMissedAny = false;
        for (var achievement of Array.from(levelAchievements)) {
          if (!campaignLevels[achievement.related]) { continue; }
          var relatedLevelSlug = campaignLevels[achievement.related].slug;
          for (var levelOriginal of Array.from(achievement.rewards.levels)) {
            if (!campaignLevels[levelOriginal]) { continue; }
            var rewardLevelSlug = campaignLevels[levelOriginal].slug;
            if (sessionsCompleteMap[relatedLevelSlug] && !levelsEarnedMap[rewardLevelSlug]) {
              var ea = new EarnedAchievement({
                achievement: achievement._id,
                triggeredBy: sessionsCompleteMap[relatedLevelSlug],
                collection: 'level.sessions'
              });
              hadMissedAny = true;
              ea.notyErrors = false;
              ea.save()
              .error(() => console.warn('Achievement NOT complete:', achievement.name));
            }
          }
        }
        if (hadMissedAny) {
          return (window.tracker != null ? window.tracker.trackEvent('Fixed Unearned Achievement', {category: 'World Map', label: this.terrain}) : undefined);
        }
      });
    }

    maybeShowPendingAnnouncement() {
      if (me.freeOnly()) { return false; } // TODO: handle announcements that can be shown to free only servers
      if (this.payPalToken) { return false; }
      if (me.isStudent()) { return false; }
      if (application.getHocCampaign()) { return false; }
      if (me.isInHourOfCode()) { return false; }
      if (userUtils.isInLibraryNetwork() || userUtils.libraryName()) { return false; }
      const latest = window.serverConfig.latestAnnouncement;
      const myLatest = me.get('lastAnnouncementSeen');
      if (typeof latest !== 'number') { return; }
      const accountHours = (new Date() - new Date(me.get("dateCreated"))) / (60 * 60 * 1000); // min*sec*ms
      if (!(accountHours > 18)) { return; }
      if ((latest > myLatest) || (myLatest == null)) {
        me.set('lastAnnouncementSeen', latest);
        me.save();
        if (window.tracker != null) {
          window.tracker.trackEvent('Show announcement modal', {label: latest + ''});
        }
        return this.openModalView(new AnnouncementModal({announcementId: latest}));
      }
    }

    onClickBrainPopReplayButton() {
      return api.users.resetProgress({userId: me.id}).then(() => document.location.reload());
    }

    getLevels() {
      if (this.courseLevels != null) { return this.courseLevelsFake; }
      return (this.campaign != null ? this.campaign.get('levels') : undefined);
    }

    applyCourseLogicToLevels(orderedLevels) {
      let nextSlug = this.courseStats.levels.next != null ? this.courseStats.levels.next.get('slug') : undefined;
      if (nextSlug == null) { nextSlug = this.courseStats.levels.first != null ? this.courseStats.levels.first.get('slug') : undefined; }
      if (!nextSlug) { return; }

      const courseOrder = _.sortBy(orderedLevels, 'courseIdx');
      let found = false;
      let prev = null;
      let lastNormalLevel = null;
      let lockedByTeacher = false;
      for (let levelIndex = 0; levelIndex < courseOrder.length; levelIndex++) {
        var level = courseOrder[levelIndex];
        var playerState = this.levelStatusMap[level.slug];
        level.color = 'rgb(255, 80, 60)';
        level.disabled = false;

        if (level.slug === nextSlug) {
          level.locked = false;
          level.hidden = false;
          level.next = true;
          found = true;
        } else if (['started', 'complete'].includes(playerState)) {
          level.hidden = false;
          level.locked = false;
        } else {
          if (level.practice) {
            if (prev != null ? prev.next : undefined) {
              level.hidden = !(prev != null ? prev.practice : undefined);
              level.locked = true;
            } else if (prev) {
              level.hidden = prev.hidden;
              level.locked = prev.locked && !this.classroom.isStudentOnOptionalLevel(me.get('_id'), this.course.get('_id'), prev.original);
            } else {
              level.hidden = true;
              level.locked = true;
            }
          } else if (level.assessment) {
            level.hidden = false;
            level.locked = this.levelStatusMap[lastNormalLevel != null ? lastNormalLevel.slug : undefined] !== 'complete';
          } else {
            level.locked = found;
            level.hidden = false;
          }
        }

        level.noFlag = !level.next;

        var lockSkippedLevel = false;
        if ((level.slug === this.courseInstance.get('startLockedLevel')) || // lock level begin from startLockedLevel
        this.classroom.isStudentOnLockedLevel(me.get('_id'), this.course.get('_id'), level.original, this.courseInstance.get('startLockedLevel'))) {
          if (!this.classroom.isStudentOnOptionalLevel(me.get('_id'), this.course.get('_id'), level.original)) {
            lockedByTeacher = true;
          } else {
            lockSkippedLevel = true;
          }
        }

        if (lockedByTeacher || lockSkippedLevel) {
          level.locked = true;
          level.lockedByTeacher = true;
        }

        if (level.locked) {
          level.color = 'rgb(193, 193, 193)';
        } else if (level.practice) {
          level.color = 'rgb(45, 145, 81)';
        } else if (level.assessment) {
          level.color = '#AD62F8';
          if (playerState !== 'complete') {
            level.noFlag = false;
          }
        }
        level.unlocksHero = false;
        level.unlocksItem = false;
        prev = level;
        if (!this.campaign.levelIsPractice(level) && !this.campaign.levelIsAssessment(level) && !this.classroom.isStudentOnOptionalLevel(me.get('_id'), this.course.get('_id'), level.original)) {
          lastNormalLevel = level;
        }
      }

      return true;
    }

    shouldShow(what) {
      const isStudentOrTeacher = me.isStudent() || me.isTeacher();
      const isIOS = me.get('iosIdentifierForVendor') || application.isIPadApp;

      if (what === 'classroom-level-play-button') {
        const isValidStudent = me.isStudent() && (this.courseInstance || (__guard__(me.get('courseInstances'), x => x.length) && (this.campaign.get('slug') !== 'intro')));
        const isValidTeacher = me.isTeacher();
        return (isValidStudent || isValidTeacher) && !application.getHocCampaign();
      }

      if (features.noAuth && (what === 'status-line')) {
        return false;
      }

      if (what === 'promotion') {
        return me.finishedAnyLevels() && !features.noAds && !isStudentOrTeacher && (me.get('country') === 'united-states') && (me.get('preferredLanguage', true) === 'en-US') && (new Date() < new Date(2019, 11, 20));
      }

      if (['status-line'].includes(what)) {
        return (me.showGemsAndXpInClassroom() || !isStudentOrTeacher) && !this.editorMode;
      }

      if (['gems'].includes(what)) {
        return me.showGemsAndXpInClassroom() || !isStudentOrTeacher;
      }

      if (['level', 'xp'].includes(what)) {
        return me.showGemsAndXpInClassroom() || !isStudentOrTeacher;
      }

      if (['settings', 'leaderboard', 'back-to-campaigns', 'poll', 'items', 'heros', 'achievements'].includes(what)) {
        return !isStudentOrTeacher && !this.editorMode;
      }

      if (['clans'].includes(what)) {
        return !isStudentOrTeacher && !this.editorMode && !me.get('isCreatedViaLibrary');
      }

      if (['back-to-classroom'].includes(what)) {
        return isStudentOrTeacher && (!application.getHocCampaign() || (this.terrain === 'intro')) && !this.editorMode;
      }

      if (['videos'].includes(what)) {
        return me.isStudent() && ((this.course != null ? this.course.get('_id') : undefined) === utils.courseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE);
      }

      if (['buy-gems'].includes(what)) {
        return !(isIOS || me.freeOnly() || isStudentOrTeacher || !me.canBuyGems() || (application.getHocCampaign() && me.isAnonymous())) && !this.editorMode;
      }

      if (['premium'].includes(what)) {
        return !(me.isPremium() || isIOS || me.freeOnly() || isStudentOrTeacher || (application.getHocCampaign() && me.isAnonymous()) || paymentUtils.hasTemporaryPremiumAccess()) && !this.editorMode;
      }

      if (what === 'anonymous-classroom-signup') {
        return me.isAnonymous() && (me.level() < 8) && me.promptForClassroomSignup() && !this.editorMode;
      }

      if (what === 'amazon-campaign') {
        return (this.campaign != null ? this.campaign.get('slug') : undefined) === 'game-dev-hoc';
      }

      if (what === 'santa-clara-logo') {
        return userUtils.libraryName() === 'santa-clara';
      }

      if (what === 'garfield-logo') {
        return userUtils.libraryName() === 'garfield';
      }

      if (what === 'arapahoe-logo') {
        return userUtils.libraryName() === 'arapahoe';
      }

      if (what === 'houston-logo') {
        return userUtils.libraryName() === 'houston';
      }

      if (what === 'burnaby-logo') {
        return userUtils.libraryName() === 'burnaby';
      }

      if (what === 'liverpool-library-logo') {
        return userUtils.libraryName() === 'liverpool-library';
      }

      if (what === 'lafourche-library-logo') {
        return userUtils.libraryName() === 'lafourche';
      }

      if (what === 'shreve-library-logo') {
        return userUtils.libraryName() === 'shreve';
      }

      if (what === 'vaughan-library-logo') {
        return userUtils.libraryName() === 'vaughan-library';
      }

      if (what === 'surrey-library-logo') {
        return userUtils.libraryName() === 'surrey-library';
      }

      if (what === 'league-arena') {
        // Note: Currently the tooltips don't work in the campaignView overworld.
        return !me.isAnonymous() && (this.campaign != null ? this.campaign.get('slug') : undefined) && !this.editorMode && !me.get('isCreatedViaLibrary');
      }

      if (what === 'roblox-level') {
        return this.userQualifiesForRobloxModal();
      }

      if (what === 'hackstack') {
        return ((typeof me.getHackStackExperimentValue === 'function' ? me.getHackStackExperimentValue() : undefined) === 'beta') && !me.get('isCreatedViaLibrary');
      }

      return true;
    }
  };
  CampaignView.initClass();
  return CampaignView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
function __guardMethod__(obj, methodName, transform) {
  if (typeof obj !== 'undefined' && obj !== null && typeof obj[methodName] === 'function') {
    return transform(obj, methodName);
  } else {
    return undefined;
  }
}