require('app/styles/play/campaign-view.sass')
const RootView = require('views/core/RootView')
const template = require('templates/play/campaign-view')
const LevelSession = require('models/LevelSession')
const EarnedAchievement = require('models/EarnedAchievement')
const CocoCollection = require('collections/CocoCollection')
const Achievements = require('collections/Achievements')
const Campaign = require('models/Campaign')
const AudioPlayer = require('lib/AudioPlayer')
const LevelSetupManager = require('lib/LevelSetupManager')
const ThangType = require('models/ThangType')
const MusicPlayer = require('lib/surface/MusicPlayer')
const storage = require('core/storage')
const CreateAccountModal = require('views/core/CreateAccountModal')
const SubscribeModal = require('views/core/SubscribeModal')
const LeaderboardModal = require('views/play/modal/LeaderboardModal')
const Level = require('models/Level')
const User = require('models/User')
const utils = require('core/utils')
const ShareProgressModal = require('views/play/modal/ShareProgressModal')
const UserPollsRecord = require('models/UserPollsRecord')
const Poll = require('models/Poll')
const PollModal = require('views/play/modal/PollModal')
const AnnouncementModal = require('views/play/modal/AnnouncementModal')
const LiveClassroomModal = require('views/play/modal/LiveClassroomModal')
const Codequest2020Modal = require('views/play/modal/Codequest2020Modal')
const RobloxModal = require('views/core/MineModal') // Roblox modal
const JuniorModal = require('views/core/JuniorModal')
const api = require('core/api')
const Classroom = require('models/Classroom')
const Course = require('models/Course')
const CourseInstance = require('models/CourseInstance')
const Levels = require('collections/Levels')
const createjs = require('lib/createjs-parts')
const PlayItemsModal = require('views/play/modal/PlayItemsModal')
const PlayHeroesModal = require('views/play/modal/PlayHeroesModal')
const PlayAchievementsModal = require('views/play/modal/PlayAchievementsModal')
const BuyGemsModal = require('views/play/modal/BuyGemsModal')
const ContactModal = require('views/core/ContactModal')
const AnonymousTeacherModal = require('views/core/AnonymousTeacherModal')
const AmazonHocModal = require('views/play/modal/AmazonHocModal')
const PromotionModal = require('views/play/modal/PromotionModal')
require('vendor/scripts/jquery-ui-1.11.1.custom')
require('vendor/styles/jquery-ui-1.11.1.custom.css')
const HoCModal = require('views/special_event/HoC2018InterstitialModal')
const CourseVideosModal = require('views/play/level/modal/CourseVideosModal')
const globalVar = require('core/globalVar')
const paymentUtils = require('app/lib/paymentUtils')
const userUtils = require('lib/user-utils')
const AILeaguePromotionModal = require('views/core/AILeaguePromotionModal')
const HackstackPromotionModalView = require('views/ai/HackstackPromotionModalView').default
require('lib/game-libraries')

const ROBLOX_MODAL_SHOWN = 'roblox-modal-shown'
const PROMPTED_FOR_SIGNUP = 'prompted-for-signup'
const PROMPTED_FOR_SUBSCRIPTION = 'prompted-for-subscription'
const AI_LEAGUE_MODAL_SHOWN = 'ai-league-modal-shown'

class LevelSessionsCollection extends CocoCollection {
  static initClass () {
    this.prototype.url = ''
    this.prototype.model = LevelSession
  }

  constructor (model) {
    super()
    this.url = `/db/user/${me.id}/level.sessions?project=state.complete,levelID,state.difficulty,playtime,state.topScores,codeLanguage,level`
  }
}
LevelSessionsCollection.initClass()

class CampaignsCollection extends CocoCollection {
  static initClass () {
    // We don't send all of levels, just the parts needed in countLevels
    this.prototype.url = '/db/campaign/-/overworld?project=slug,adjacentCampaigns,name,fullName,description,i18n,color,levels'
    this.prototype.model = Campaign
  }
}
CampaignsCollection.initClass()

class CampaignView extends RootView {
  static initClass () {
    this.prototype.id = 'campaign-view'
    this.prototype.template = template

    this.prototype.subscriptions = {
      'subscribe-modal:subscribed': 'onSubscribed',
    }

    this.prototype.events = {
      'click #amazon-campaign-logo': 'onClickAmazonCampaign',
      'click #anon-classroom-signup-close': 'onClickAnonClassroomClose',
      'click #anon-classroom-join-btn': 'onClickAnonClassroomJoin',
      'click #anon-classroom-signup-btn': 'onClickAnonClassroomSignup',
      'click .roblox-level': 'onRobloxLevelClick',
      'click .hackstack-level': 'onHackStackLevelClick',
      'click .hackstack-menu-icon': 'onHackStackLevelClick',
      'click .junior-menu-icon': 'onJuniorIconClick',
      'click .map-background': 'onClickMap',
      'click .level': 'onClickLevel',
      'dblclick .level': 'onDoubleClickLevel',
      'click .level-info-container .start-level': 'onClickStartLevel',
      'click .level-info-container .home-version button': 'onClickStartLevel',
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
      'click .m7-off': 'onClickM7OffButton',
    }

    this.prototype.shortcuts = {
      'shift+s': 'onShiftS',
    }

    this.prototype.activeArenas = utils.activeArenas
  }

  constructor (options, terrain) {
    super(options)
    this.onMouseMovePortals = this.onMouseMovePortals.bind(this)
    this.onWindowResize = this.onWindowResize.bind(this)
    this.terrain = terrain
    if (/^classCode/.test(this.terrain)) {
      this.terrain = '' // Stop /play?classCode= from making us try to play a classCode campaign
    }
    if (window.serverConfig.picoCTF) {
      this.terrain = 'picoctf'
    }
    this.editorMode = options?.editorMode
    this.requiresSubscription = !me.isPremium()
    if (this.editorMode && !this.terrain) {
      this.terrain = 'dungeon'
    }
    this.levelStatusMap = {}
    this.levelPlayCountMap = {}
    this.levelDifficultyMap = {}
    this.levelScoreMap = {}
    this.courseLevelsLoaded = false

    if (this.terrain === 'hoc-2018') {
      $('body').append($("<img src='https://code.org/api/hour/begin_codecombat_play.png' style='visibility: hidden;'>"))
    }

    if (utils.getQueryVariable('hour_of_code')) {
      if (me.isStudent() || me.isTeacher()) {
        if (this.terrain === 'dungeon') {
          const newCampaign = 'intro'
          api.users.getCourseInstances({ userID: me.id, campaignSlug: newCampaign }, { data: { project: '_id' } })
            .then(courseInstances => {
              if (courseInstances.length) {
                const courseInstanceID = courseInstances[0]._id
                return application.router.navigate(`/play/${newCampaign}?course-instance=${courseInstanceID}`, { trigger: true, replace: true })
              } else {
                application.router.navigate((me.isStudent() ? '/students' : '/teachers'), { trigger: true, replace: true })
                return noty({ text: 'Please create or join a classroom first', layout: 'topCenter', timeout: 8000, type: 'success' })
              }
            })
          return
        }
      }
      if (this.terrain === 'game-dev-hoc') {
        window.tracker?.trackEvent('Start HoC Campaign', { label: 'game-dev-hoc' })
      }
      me.set('hourOfCode', true)
      me.patch()
      const pixelCode = (() => {
        switch (this.terrain) {
          case 'game-dev-hoc': return 'code_combat_gamedev'
          case 'game-dev-hoc-2': return 'code_combat_build_arcade'
          case 'ai-league-hoc': return 'codecombat_esports'
          case 'goblins-hoc': return 'codecombat_goblins'
          default: return 'code_combat'
        }
      })()
      $('body').append($(`<img src='https://code.org/api/hour/begin_${pixelCode}.png' style='visibility: hidden;'>`))
    } else if (me.isTeacher() && !utils.getQueryVariable('course-instance') &&
        !application.getHocCampaign() && (this.terrain !== 'hoc-2018')) {
      // redirect teachers away from home campaigns
      application.router.navigate('/teachers', { trigger: true, replace: true })
      return
    } else if (location.pathname === '/paypal/subscribe-callback') {
      this.payPalToken = utils.getQueryVariable('token')
      api.users.executeBillingAgreement({ userID: me.id, token: this.payPalToken })
        .then(billingAgreement => {
          const value = Math.round(parseFloat(billingAgreement?.plan?.payment_definitions?.[0]?.amount?.value ?? 0) * 100)
          application.tracker?.trackEvent('Finished subscription purchase', { value, service: 'paypal' })
          noty({ text: $.i18n.t('subscribe.confirmation'), layout: 'topCenter', timeout: 8000 })
          return me.fetch({ cache: false, success: () => this.render?.() })
        }).catch(err => {
          return console.error(err)
        })
    }

    if (userUtils.shouldShowLibraryLoginModal() && me.isAnonymous()) {
      this.openModalView(new CreateAccountModal({ startOnPath: 'individual-basic' }))
    }

    if (window.serverConfig.picoCTF) {
      this.supermodel.addRequestResource({
        url: '/picoctf/problems',
        success: picoCTFProblems => {
          this.picoCTFProblems = picoCTFProblems
        },
      }).load()
    } else {
      if (!this.editorMode) {
        this.sessions = this.supermodel.loadCollection(new LevelSessionsCollection(), 'your_sessions', { cache: false }, 1).model
        this.listenToOnce(this.sessions, 'sync', this.onSessionsLoaded)
      }
      if (!this.terrain) {
        this.campaigns = this.supermodel.loadCollection(new CampaignsCollection(), 'campaigns', null, 1).model
        this.listenToOnce(this.campaigns, 'sync', this.onCampaignsLoaded)
        return
      }
    }

    this.campaign = new Campaign({ _id: this.terrain })
    this.campaign = this.supermodel.loadModel(this.campaign).model

    // Temporary attempt to make sure all earned rewards are accounted for. Figure out a better solution...
    this.earnedAchievements = new CocoCollection([], { url: '/db/earned_achievement', model: EarnedAchievement, project: ['earnedRewards'] })
    this.listenToOnce(this.earnedAchievements, 'sync', function () {
      const earned = me.get('earned')
      let hadMissedAny = false
      for (const m of this.earnedAchievements.models) {
        const loadedEarned = m.get('earnedRewards')
        if (!loadedEarned) continue
        for (const group of ['heroes', 'levels', 'items']) {
          if (!loadedEarned[group]) continue
          for (const reward of loadedEarned[group]) {
            if (!earned[group].includes(reward)) {
              console.warn('Filling in a gap for reward', group, reward)
              earned[group].push(reward)
              hadMissedAny = true
            }
          }
        }
      }
      if (hadMissedAny) {
        window.tracker?.trackEvent('Fixed Missing Achievement Reward', { category: 'World Map', label: this.terrain })
      }
    })

    this.supermodel.loadCollection(this.earnedAchievements, 'achievements', { cache: false })

    if (utils.getQueryVariable('course-instance') != null) {
      this.courseLevelsFake = {}
      this.courseInstanceID = utils.getQueryVariable('course-instance')
      this.courseInstance = new CourseInstance({ _id: this.courseInstanceID })
      const jqxhr = this.courseInstance.fetch()
      this.supermodel.trackRequest(jqxhr)
      new Promise(jqxhr.then).then(() => {
        if (this.destroyed) return
        const courseID = this.courseInstance.get('courseID')

        this.course = new Course({ _id: courseID })
        this.supermodel.trackRequest(this.course.fetch())
        if (this.courseInstance.get('ownerID')) {
          const teacherID = this.courseInstance.get('ownerID')
          this.courseTeacher = new User({ _id: teacherID })
          this.supermodel.trackRequest(this.courseTeacher.fetch())
          this.listenToOnce(this.courseTeacher, 'sync', () => {
            this.render()
          })
        }
        if (this.courseInstance.get('classroomID')) {
          const classroomID = this.courseInstance.get('classroomID')
          this.classroom = new Classroom({ _id: classroomID })
          this.supermodel.trackRequest(this.classroom.fetch())
          this.listenToOnce(this.classroom, 'sync', () => {
            me.setLastClassroomItems(this.classroom.get('classroomItems', true))
            this.updateClassroomSessions()
            this.render()
            this.courseInstance.sessions = new CocoCollection([], {
              url: this.courseInstance.url() + '/course-level-sessions/' + me.id,
              model: LevelSession,
            })
            this.supermodel.loadCollection(this.courseInstance.sessions, {
              data: { project: 'state.complete,level.original,playtime,changed,state.topScores' },
            })
            this.courseInstance.sessions.comparator = 'changed'
            this.listenToOnce(this.courseInstance.sessions, 'sync', () => {
              this.courseStats = this.classroom.statsForSessions(this.courseInstance.sessions, this.course.id)
              this.render()
            })
            if (!['junior', '65c56663d2ca2055e65676af'].includes(this.terrain)) {
              // Fetch the version of the campaign levels for this course.
              // TODO: fully rip this out once we get rid of classroom versioning.
              this.courseLevels = new Levels()
              this.supermodel.trackRequest(this.courseLevels.fetchForClassroomAndCourse(classroomID, courseID, {
                data: { project: 'concepts,practice,assessment,primerLanguage,type,slug,name,original,description,shareable,i18n' },
              }))
              this.listenToOnce(this.courseLevels, 'sync', () => {
                this.courseLevelsLoaded = true
                this.updateCourseLevels()
              })
              this.listenToOnce(this.campaign, 'sync', () => this.updateCourseLevels())
            }
          })
        }
      })
    }

    window.addEventListener('resize', this.onWindowResize)
    this.probablyCachedMusic = storage.load('loaded-menu-music')
    const musicDelay = this.probablyCachedMusic ? 1000 : 10000
    const delayMusicStart = () => setTimeout(() => {
      if (!this.destroyed) {
        this.playMusic()
      }
    }, musicDelay)
    this.playMusicTimeout = delayMusicStart()
    this.hadEverChosenHero = me.get('heroConfig')?.thangType
    this.listenTo(me, 'change:purchased', () => this.renderSelectors('#gems-count'))
    this.listenTo(me, 'change:spent', () => this.renderSelectors('#gems-count'))
    this.listenTo(me, 'change:earned', () => this.renderSelectors('#gems-count'))
    this.listenTo(me, 'change:heroConfig', () => this.updateHero())

    if (utils.getQueryVariable('hour_of_code') || (this.terrain === 'hoc-2018')) {
      if (!sessionStorage.getItem(this.terrain)) {
        sessionStorage.setItem(this.terrain, 'seen-modal')
        clearTimeout(this.playMusicTimeout)
        setTimeout(() => {
          let activity = 'ai-league'
          if (this.terrain === 'hoc-2018') { activity = 'teacher-gd' }
          if (this.terrain === 'goblins-hoc') { activity = 'goblins' }
          this.openModalView(new HoCModal({
            activity,
            showVideo: this.terrain === 'hoc-2018',
            onDestroy: () => {
              if (this.destroyed) { return }
              delayMusicStart()
              this.highlightNextLevel()
            },
          }))
        }, 0)
      }
    }

    this.isMto = me.isMto()
    window.tracker?.trackEvent('Loaded World Map', { category: 'World Map', label: this.terrain })
  }

  destroy () {
    this.setupManager?.destroy()
    this.$el.find('.ui-draggable').off().draggable('destroy')
    window.removeEventListener('resize', this.onWindowResize)
    const ambientSound = this.ambientSound
    if (ambientSound) {
      // Doesn't seem to work; stops immediately.
      createjs.Tween.get(ambientSound).to({ volume: 0.0 }, 1500).call(() => ambientSound.stop())
    }
    this.musicPlayer?.destroy()
    clearTimeout(this.playMusicTimeout)
    clearInterval(this.portalScrollInterval)
    Backbone.Mediator.unsubscribe('audio-player:loaded', this.playAmbientSound, this)
    super.destroy()
  }

  showLoading ($el) {
    if (!this.campaign) {
      this.$el.find('.game-controls, .user-status').addClass('hidden')
      this.$el.find('.portal .campaign-name span').text($.i18n.t('common.loading'))
    }
  }

  hideLoading () {
    if (!this.campaign) {
      this.$el.find('.game-controls, .user-status').removeClass('hidden')
    }
  }

  openPromotionModal (e) {
    if (e) {
      window.tracker?.trackEvent('Click Promotion Modal Button')
    }
    this.openModalView(new PromotionModal())
  }

  openJuniorPromotionModal (e) {
    window.tracker?.trackEvent('Junior Explored')
    this.openModalView(new JuniorModal())
  }

  openPlayItemsModal (e) {
    e.stopPropagation()
    this.openModalView(new PlayItemsModal())
  }

  openPlayHeroesModal (e) {
    e.stopPropagation()
    this.openModalView(new PlayHeroesModal({ campaign: this.campaign }))
  }

  openPlayAchievementsModal (e) {
    e.stopPropagation()
    this.openModalView(new PlayAchievementsModal())
  }

  openBuyGemsModal (e) {
    e.stopPropagation()
    this.openModalView(new BuyGemsModal())
  }

  openContactModal (e) {
    e.stopPropagation()
    this.openModalView(new ContactModal())
  }

  openCreateAccountModal (e) {
    e?.stopPropagation?.()
    this.openModalView(new CreateAccountModal())
  }

  openAnonymousTeacherModal (e) {
    e.stopPropagation()
    this.openModalView(new AnonymousTeacherModal())
    this.endHighlight()
  }

  onClickAmazonCampaign (e) {
    window.tracker?.trackEvent('Click Amazon Modal Button')
    this.openModalView(new AmazonHocModal({ hideCongratulation: true }))
  }

  onClickAnonClassroomClose () {
    this.$el.find('#anonymous-classroom-signup-dialog').hide()
    storage.save('hid-anonymous-classroom-signup-dialog', true)
  }

  onClickAnonClassroomJoin () {
    const classCode = this.$el.find('#anon-classroom-signup-code')?.val()
    if (!classCode) return
    window.tracker?.trackEvent('Anonymous Classroom Signup Modal Join Class', { category: 'Signup' }, classCode)
    application.router.navigate(`/students?_cc=${classCode}`, { trigger: true })
  }

  onClickAnonClassroomSignup () {
    window.tracker?.trackEvent('Anonymous Classroom Signup Modal Create Teacher', { category: 'Signup' })
    this.openModalView(new CreateAccountModal({ startOnPath: 'teacher' }))
  }

  onClickVideosButton () {
    this.openModalView(new CourseVideosModal({ courseInstanceID: this.courseInstanceID, courseID: this.course.get('_id') }))
  }

  onClickEsportsButton (e) {
    this.$levelInfo?.hide()
    const arenaSlug = $(e.target).data('arena')
    window.tracker?.trackEvent('Click LevelInfo AI League Button', { category: 'World Map', label: arenaSlug })
    this.$levelInfo = this.$el.find(`.level-info-container.league-arena-tooltip[data-arena='${arenaSlug}']`).show()
    this.adjustLevelInfoPosition(e)
  }

  onClickEsportsLink (e) {
    const arenaSlug = $(e.target).data('arena')
    window.tracker?.trackEvent('Click Play AI League Button', { category: 'World Map', label: arenaSlug })
  }

  onLoaded () {
    if (this.isChinaOldBrowser()) {
      if (!storage.load('hideBrowserRecommendation')) {
        const BrowserRecommendationModal = require('views/core/BrowserRecommendationModal')
        this.openModalView(new BrowserRecommendationModal())
      }
    }

    if (this.isClassroom()) {
      this.updateClassroomSessions()
    } else {
      if (!this.editorMode) {
        for (const session of this.sessions.models) {
          if (this.levelStatusMap[session.get('levelID')] !== 'complete') { // Don't overwrite a complete session with an incomplete one
            this.levelStatusMap[session.get('levelID')] = session.get('state')?.complete ? 'complete' : 'started'
          }
          if (session.get('state')?.difficulty) {
            this.levelDifficultyMap[session.get('levelID')] = session.get('state').difficulty
          }
        }
      }
    }

    if (!this.editorMode) {
      this.buildLevelScoreMap()
    }
    // HoC: Fake us up a "mode" for HeroVictoryModal to return hero without levels realizing they're in a copycat campaign, or clear it if we started playing.
    if ((this.campaign?.get('type') === 'hoc') || (me.isStudent() && !this.courseInstance && (this.campaign?.get('slug') === 'intro'))) {
      application.setHocCampaign(this.campaign.get('slug'))
    } else {
      application.setHocCampaign('')
    }

    if (this.fullyRendered) {
      return
    }
    this.fullyRendered = true
    this.render()
    this.checkForUnearnedAchievements()
    if (!me.get('heroConfig')?.thangType) {
      this.preloadTopHeroes()
    }
    if (['forest', 'desert'].includes(this.terrain)) {
      this.$el.find('#campaign-status').delay(4000).animate({ top: '-=58' }, 1000)
    }
    if (this.campaign && this.isRTL(utils.i18n(this.campaign.attributes, 'fullName'))) {
      this.$('.campaign-name').attr('dir', 'rtl')
    }
    if (!me.isInHourOfCode() && this.terrain) {
      if (me.get('name') &&
          ['forgetful-gemsmith', 'signs-and-portents', 'true-names'].includes(me.get('lastLevel')) &&
          (me.level() < 5) &&
          !['18-24', '25-34', '35-44', '45-100'].includes(me.get('ageRange')) &&
          !storage.load('sent-parent-email') &&
          !(me.isPremium() || me.isStudent() || me.isTeacher())) {
        this.openModalView(new ShareProgressModal())
      }
    } else {
      this.maybeShowPendingAnnouncement()
    }

    // Roblox Modal:
    this.maybeShowRobloxModal()
  }

  updateCourseLevels () {
    if (!this.campaign.loaded || !this.courseLevelsLoaded) {
      return false
    }
    const existing = this.campaign.get('levels')
    const courseLevels = this.courseLevels.toArray()
    const classroomCourse = globalVar.currentView.classroom.get('courses').find(c => c._id === globalVar.currentView.course.id)
    const levelPositions = {}
    for (const level of classroomCourse.levels) {
      if (level.position) {
        levelPositions[level.original] = level.position
      }
    }
    for (const [k, v] of Object.entries(courseLevels)) {
      const idx = v.get('original')
      if (!existing[idx]) {
        // a level which has been removed from the campaign but is saved in the course
        this.courseLevelsFake[idx] = v.toJSON()
      } else {
        this.courseLevelsFake[idx] = existing[idx]
        // carry over positions stored in course, if there are any
        if (levelPositions[idx]) {
          this.courseLevelsFake[idx].position = levelPositions[idx]
        }
      }
      this.courseLevelsFake[idx].courseIdx = parseInt(k)
      this.courseLevelsFake[idx].requiresSubscription = false
    }
    // Fill in missing positions, for courses which have levels that no longer exist in campaigns
    for (const [k, v] of Object.entries(courseLevels)) {
      const kInt = parseInt(k)
      const idx = v.get('original')
      if (!this.courseLevelsFake[idx].position) {
        const prevLevel = courseLevels[kInt - 1]
        const nextLevel = courseLevels[kInt + 1]
        if (prevLevel && nextLevel) {
          const prevIdx = prevLevel.get('original')
          const nextIdx = nextLevel.get('original')
          const prevPosition = this.courseLevelsFake[prevIdx].position
          const nextPosition = this.courseLevelsFake[nextIdx].position
          if (prevPosition && nextPosition) {
            // split the diff between the previous, next levels
            this.courseLevelsFake[idx].position = {
              x: (prevPosition.x + nextPosition.x) / 2,
              y: (prevPosition.y + nextPosition.y) / 2,
            }
          } else {
            // otherwise just line them up along the bottom
            const x = 10 + ((kInt / courseLevels.length) * 80)
            this.courseLevelsFake[idx].position = { x, y: 10 }
          }
        }
      }
    }
    return this.render()
  }

  updateClassroomSessions () {
    if (this.classroom) {
      const classroomLevels = this.classroom.getLevels()
      this.classroomLevelMap = Object.fromEntries(classroomLevels.map(l => [l.get('original'), l]))
      const defaultLanguage = this.classroom.get('aceConfig').language
      for (const session of this.sessions.slice()) {
        const classroomLevel = this.classroomLevelMap[session.get('level').original]
        if (!classroomLevel) {
          continue
        }
        const expectedLanguage = classroomLevel.get('primerLanguage') || defaultLanguage
        if (session.get('codeLanguage') !== expectedLanguage) {
          this.sessions.remove(session)
          continue
        }
      }
      if (!this.editorMode) {
        for (const session of this.sessions.models) {
          if (this.levelStatusMap[session.get('levelID')] !== 'complete') { // Don't overwrite a complete session with an incomplete one
            this.levelStatusMap[session.get('levelID')] = session.get('state')?.complete ? 'complete' : 'started'
          }
          if (session.get('state')?.difficulty) {
            this.levelDifficultyMap[session.get('levelID')] = session.get('state').difficulty
          }
        }
      }
    }
  }

  buildLevelScoreMap () {
    for (const session of this.sessions.models) {
      const levels = this.getLevels()
      if (!levels) { return }
      const levelOriginal = session.get('level')?.original
      if (!levelOriginal) { continue }
      const level = levels[levelOriginal]
      const topScore = _.first(LevelSession.getTopScores({ session: session.toJSON(), level }))
      this.levelScoreMap[levelOriginal] = topScore
    }
  }

  userQualifiesForRobloxModal () {
    if (me.freeOnly()) { return false }
    if (storage.load('roblox-clicked')) { return false }
    if (userUtils.isInLibraryNetwork() || userUtils.libraryName() || userUtils.isCreatedViaLibrary()) { return false }
    if (me.isPremium()) { return true }
    if (me.get('hourOfCode')) { return false }
    if (storage.load('paywall-reached')) { return true }
    return false
  }

  maybeShowRobloxModal () {
    if (this.userQualifiesForRobloxModal()) {
      $('.roblox-level').show()
    }
  }

  onRobloxLevelClick (e) {
    window.tracker?.trackEvent('Mine Explored', { engageAction: 'campaign_level_click' })
    this.showRobloxModal()
  }

  showRobloxModal () {
    storage.save(ROBLOX_MODAL_SHOWN)
    this.openModalView(new RobloxModal())
  }

  onJuniorIconClick (e) {
    window.tracker?.trackEvent('Junior Icon Explored', { engageAction: 'campaign_level_click' })
    this.openModalView(new JuniorModal())
  }

  onHackStackLevelClick (e) {
    window.tracker?.trackEvent('HackStack Explored', { engageAction: 'campaign_level_click' })
    // Backbone.Mediator.publish 'router:navigate', route: '/ai/new_project'
    this.openModalView(new HackstackPromotionModalView())
  }

  setCampaign (campaign) {
    this.campaign = campaign
    this.render()
  }

  onSubscribed () {
    this.requiresSubscription = false
    this.render()
  }

  getRenderData (context = {}) {
    context = super.getRenderData(context)
    context.campaign = this.campaign
    context.levels = _.values($.extend(true, {}, this.getLevels() ?? {}))
    if ((me.level() < 12) && (this.terrain === 'dungeon') && !this.editorMode) {
      context.levels = _.reject(context.levels, { slug: 'signs-and-portents' })
    }
    if (me.freeOnly()) {
      context.levels = _.reject(context.levels, level => {
        if ((['course', 'course-ladder'].includes(level.type)) && me.isStudent() && !this.courseInstance) { return true } // Too much hassle to get Wakka Maul working for CS1 with no classroom
        return level.requiresSubscription && !me.isStudent()
      })
    }
    if (features.brainPop) {
      context.levels = _.filter(context.levels, level => ['dungeons-of-kithgard', 'gems-in-the-deep', 'shadow-guard', 'enemy-mine', 'true-names'].includes(level.slug))
    }
    this.annotateLevels(context.levels)
    const count = this.countLevels(context.levels)
    if (this.courseStats) {
      context.levelsCompleted = this.courseStats.levels.numDone
      context.levelsTotal = this.courseStats.levels.size
    } else {
      context.levelsCompleted = count.completed
      context.levelsTotal = count.total
    }

    if (this.sessions?.loaded || this.editorMode) {
      this.determineNextLevel(context.levels)
    }
    context.levels = this.collapsePracticeLevels(context.levels)

    // put lower levels in last, so in the world map they layer over one another properly.
    context.levels = _.sortBy(context.levels, l => l.position.y).reverse()
    if (this.campaign) {
      this.campaign.renderedLevels = context.levels
    }

    context.levelStatusMap = this.levelStatusMap
    context.levelDifficultyMap = this.levelDifficultyMap
    context.levelPlayCountMap = this.levelPlayCountMap
    context.isIPadApp = application.isIPadApp
    context.picoCTF = window.serverConfig.picoCTF
    context.requiresSubscription = this.requiresSubscription
    context.editorMode = this.editorMode
    context.adjacentCampaigns = _.filter(_.values(_.cloneDeep(this.campaign?.get('adjacentCampaigns') ?? {})), ac => {
      if (me.isStudent() || me.isTeacher()) { return false }
      if (ac.showIfUnlocked && !this.editorMode) {
        if (_.isString(ac.showIfUnlocked) && !me.levels().includes(ac.showIfUnlocked)) { return false }
        if (_.isArray(ac.showIfUnlocked) && (_.intersection(ac.showIfUnlocked, me.levels()).length <= 0)) { return false }
      }
      ac.name = utils.i18n(ac, 'name')
      const styles = []
      if (ac.color) { styles.push(`color: ${ac.color}`) }
      if (ac.rotation) { styles.push(`transform: rotate(${ac.rotation}deg)`) }
      ac.position = ac.position ?? { x: 10, y: 10 }
      styles.push(`left: ${ac.position.x}%`)
      styles.push(`top: ${ac.position.y}%`)
      ac.style = styles.join('; ')
      return true
    })
    context.marked = marked
    context.i18n = utils.i18n

    if (this.campaigns) {
      context.campaigns = {}
      const publicCampaigns = _.without(this.campaigns.models, (c) => ['tests', 'auditions', 'hackstack'].includes(c.get('slug')))
      for (const campaign of publicCampaigns) {
        context.campaigns[campaign.get('slug')] = campaign
        if (this.sessions?.loaded) {
          let levels = _.values($.extend(true, {}, campaign.get('levels') ?? {}))
          if ((me.level() < 12) && (campaign.get('slug') === 'dungeon') && !this.editorMode) {
            levels = levels.filter(level => level.slug !== 'signs-and-portents')
          }
          if (me.freeOnly() && !me.isStudent()) {
            levels = levels.filter(level => !level.requiresSubscription)
          }
          const count = this.countLevels(levels)
          campaign.levelsTotal = count.total
          campaign.levelsCompleted = count.completed
          campaign.locked = campaign.get('slug') !== 'dungeon' && !campaign.levelsTotal
        }
      }
      for (const campaign of publicCampaigns) {
        for (const [acID, ac] of Object.entries(campaign.get('adjacentCampaigns') ?? {})) {
          if (_.isString(ac.showIfUnlocked)) {
            if (me.levels().includes(ac.showIfUnlocked)) {
              const campaign = _.find(this.campaigns.models, { id: acID })
              if (campaign) {
                campaign.locked = false
              }
            }
          } else if (_.isArray(ac.showIfUnlocked)) {
            if (_.intersection(ac.showIfUnlocked, me.levels()).length > 0) {
              const campaign = _.find(this.campaigns.models, { id: acID })
              if (campaign) {
                campaign.locked = false
              }
            }
          }
        }
      }
    }

    if (this.terrain && _.string.contains(this.terrain, 'hoc') && me.isTeacher()) {
      context.showGameDevAlert = true
    }

    return context
  }

  afterRender () {
    super.afterRender()
    if ($.isTouchCapable() && (screen.availHeight < screen.availWidth)) {
      // scroll to vertical center on landscape touchscreens
      $('.portal').animate({
        scrollTop: ($('.portals').height() - $('.portal').height()) / 2,
      }, 100)
    }
    this.onWindowResize()

    $('#anon-classroom-signup-code').keydown(event => {
      if (event.keyCode === 13) {
        // click join classroom button if enter is pressed in the text box
        $('#anon-classroom-join-btn').click()
      }
    })

    if (!application.isIPadApp) {
      _.defer(() => this.$el?.find('.game-controls .btn:not(.poll)').addClass('has-tooltip').tooltip()) // Have to defer or i18n doesn't take effect.
      const view = this
      this.$el.find('.level, .campaign-switch').addClass('has-tooltip').tooltip().each(function () {
        if (!me.isAdmin() || !view.editorMode) { return }
        $(this).draggable().on('dragstop', function () {
          const bg = $('.map-background')
          const x = (($(this).offset().left - bg.offset().left) + ($(this).outerWidth() / 2)) / bg.width()
          const y = 1 - ((($(this).offset().top - bg.offset().top) + ($(this).outerHeight() / 2)) / bg.height())
          const e = { position: { x: (100 * x), y: (100 * y) }, levelOriginal: $(this).data('level-original'), campaignID: $(this).data('campaign-id') }
          if (e.levelOriginal) { view.trigger('level-moved', e) }
          if (e.campaignID) { view.trigger('adjacent-campaign-moved', e) }
        })
      })
    }
    this.updateVolume()
    this.updateHero()
    if (!window.currentModal && this.fullyRendered) {
      this.highlightNextLevel()
      if (this.editorMode) {
        this.createLines()
      }
      if (this.options.showLeaderboard) {
        this.showLeaderboard(this.options.justBeatLevel?.get('slug'))
      } else if (this.shouldShow('promotion')) {
        const timesPointedOutPromotion = storage.load('pointed-out-promotion') || 0
        if (!timesPointedOutPromotion) {
          this.openPromotionModal()
          storage.save('pointed-out-promotion', timesPointedOutPromotion + 1)
        } else if (timesPointedOutPromotion < 5) {
          this.$el.find('button.promotion-menu-icon').addClass('highlighted').tooltip('show')
          storage.save('pointed-out-promotion', timesPointedOutPromotion + 1)
        }
      } else if (this.shouldShow('junior-promotion')) {
        this.openJuniorPromotionModal()
      }
    }
    return this.applyCampaignStyles()
  }

  onShiftS (e) {
    if (this.editorMode) {
      this.generateCompletionRates()
    }
  }

  generateCompletionRates () {
    if (!me.isAdmin()) { return }
    const startDay = utils.getUTCDay(-14)
    const endDay = utils.getUTCDay(-1)
    $('.map-background').css('background-image', 'none')
    $('.gradient').remove()
    $('#campaign-view').css('background-color', 'black')

    for (const level of this.campaign?.renderedLevels ?? []) {
      $(`div[data-level-slug=${level.slug}] .level-kind`).text('Loading...')
      const request = this.supermodel.addRequestResource('level_completions', {
        url: '/db/analytics_perday/-/level_completions',
        data: { startDay, endDay, slug: level.slug },
        method: 'POST',
        success: this.onLevelCompletionsLoaded.bind(this, level),
      }, 0)
      request.load()
    }
  }

  onLevelCompletionsLoaded (level, data) {
    if (this.destroyed) { return }
    let started = 0
    let finished = 0
    for (const day of data) {
      started += day.started ?? 0
      finished += day.finished ?? 0
    }
    const ratio = started === 0 ? 0 : finished / started
    const rateDisplay = (ratio * 100).toFixed(1) + '%'
    const $levelKind = $(`div[data-level-slug=${level.slug}] .level-kind`)
    $levelKind.html(`${started < 1000 ? started : (started / 1000).toFixed(1) + 'k'}<br>${rateDisplay}`)

    let color
    if (ratio <= 0.5) {
      color = 'rgb(255, 0, 0)'
    } else if (ratio <= 0.85) {
      const offset = (ratio - 0.5) / 0.35
      color = `rgb(255, ${Math.round(256 * offset)}, 0)`
    } else if (ratio <= 0.95) {
      const offset = (ratio - 0.85) / 0.1
      color = `rgb(${Math.round(256 * (1 - offset))}, 256, 0)`
    } else {
      color = 'rgb(0, 256, 0)'
    }
    $levelKind.css({ color, width: '256px', transform: 'translateX(-50%) translateX(15px)' })
    $(`div[data-level-slug=${level.slug}]`).css('background-color', color)
  }

  afterInsert () {
    super.afterInsert()
    const preloadImages = ['/images/pages/base/modal_background.png', '/images/level/popover_background.png', '/images/level/code_palette_wood_background.png', '/images/level/code_editor_background_border.png']
    _.delay(() => preloadImages.forEach(img => ($('<img/>')[0].src = img)), 2000)

    if (utils.getQueryVariable('signup') && me.get('anonymous')) {
      return this.promptForSignup()
    }
    if (!me.isPremium() && (this.isPremiumCampaign() || (this.options.worldComplete && !features.noAuth && !me.isInHourOfCode()))) {
      if (me.get('anonymous')) {
        return this.promptForSignup()
      }
      const campaignSlug = window.location.pathname.split('/')[2]
      return this.promptForSubscription(campaignSlug, 'premium campaign visited')
    }

    if (
      (me.get('anonymous') && storage.load(PROMPTED_FOR_SIGNUP)) || // already prompted for signup, but not signed up
      (!me.isPremium() && storage.load(PROMPTED_FOR_SUBSCRIPTION)) // already prompted for subscription, but not subscribed
    ) {
      if (!storage.load(ROBLOX_MODAL_SHOWN)) {
        this.showRobloxModal()
      } else {
        this.showAiLeagueModal()
      }
    }
  }

  showAiLeagueModal () {
    if (!storage.load(AI_LEAGUE_MODAL_SHOWN)) {
      this.openModalView(new AILeaguePromotionModal(), true)
      storage.save(AI_LEAGUE_MODAL_SHOWN, true)
    }
  }

  promptForSignup () {
    if (/hoc/.test(this.terrain || '')) { return }
    if (features.noAuth || (this.campaign?.get('type') === 'hoc')) { return }
    this.endHighlight()
    storage.save(PROMPTED_FOR_SIGNUP, true)
    return this.openModalView(new CreateAccountModal({ supermodel: this.supermodel }))
  }

  promptForSubscription (slug, label) {
    this.paywallReached()
    if (this.campaign?.get('type') === 'hoc') { return console.log('Game dev HoC does not encourage subscribing.') }
    if (me.isStudent()) { return console.log("Students shouldn't be prompted to subscribe") }
    this.endHighlight()
    const trackProperties = { category: 'Subscription', label, level: slug, levelID: slug }
    if (me.isParentHome()) {
      this.handleParentAccountPremiumPurchase({ trackProperties })
      return
    }

    if (me.get('anonymous')) {
      this.promptForSignup()
      return
    }
    storage.save(PROMPTED_FOR_SUBSCRIPTION, true)
    this.openModalView(new SubscribeModal())
    // TODO: Added levelID on 2/9/16. Remove level property and associated AnalyticsLogEvent 'properties.level' index later.
    window.tracker?.trackEvent('Show subscription modal', trackProperties)
  }

  isPremiumCampaign (slug) {
    if (!slug) { slug = window.location.pathname.split('/')[2] }
    if (!slug) { return }
    if (/hoc/.test(slug)) { return false }
    return /campaign-(game|web)-dev-\d/.test(slug)
  }

  paywallReached () {
    storage.save('paywall-reached', true)
  }

  collapsePracticeLevels (levels) {
    if (!['junior', '65c56663d2ca2055e65676af'].includes(this.terrain)) {
      // Only do this for Junior levels for now
      return levels
    }
    // Collapse practice levels into their parent levels.
    const collapsedLevels = []
    let lastSourceLevel
    for (const level of levels) {
      if (level.practice) {
        lastSourceLevel.practiceLevels = lastSourceLevel.practiceLevels || []
        lastSourceLevel.practiceLevels.push(level)
      } else {
        collapsedLevels.push(level)
        lastSourceLevel = level
      }
    }

    return collapsedLevels
  }

  annotateLevels (orderedLevels) {
    if (this.isClassroom()) { return }

    let betaLevelIndex = 0
    let betaLevelCompletedIndex = 0
    for (let levelIndex = 0; levelIndex < orderedLevels.length; levelIndex++) {
      const level = orderedLevels[levelIndex]
      level.position = level.position ?? { x: 10, y: 10 }
      level.locked = !me.ownsLevel(level.original)
      if ((level.slug === 'kithgard-mastery') && (this.calculateExperienceScore() === 0)) { level.locked = true }
      if (level.requiresSubscription && this.requiresSubscription && me.isInHourOfCode()) { level.locked = true }
      if (['started', 'complete'].includes(this.levelStatusMap[level.slug])) { level.locked = false }
      if (this.editorMode) { level.locked = false }
      if (['Auditions', 'Intro'].includes(this.campaign?.get('name'))) { level.locked = false }
      if (me.isInGodMode()) { level.locked = false }
      if (this.courseInstanceID && level.hasAccessByTeacher(this.courseTeacher)) { level.locked = false }
      if (level.adminOnly && !['started', 'complete'].includes(this.levelStatusMap[level.slug])) { level.disabled = true }
      if (me.isInGodMode()) { level.disabled = false }

      level.color = 'rgb(255, 80, 60)'
      if (!this.isClassroom() && (this.campaign?.get('type') !== 'hoc')) {
        if (level.requiresSubscription) { level.color = 'rgb(80, 130, 200)' }
      }
      // level.color = 'rgb(200, 80, 200)' if level.adventurer  # Disable adventurer stuff for now

      if (level.locked) { level.color = 'rgb(193, 193, 193)' }
      level.unlocksHero = level.rewards?.find(r => r.hero)?.hero
      if (level.unlocksHero) {
        level.purchasedHero = me.get('purchased')?.heroes?.includes(level.unlocksHero)
      }

      level.unlocksItem = level.rewards?.find(r => r.item)?.item
      level.unlocksPet = utils.petThangIDs.indexOf(level.unlocksItem) !== -1

      if (this.classroom) {
        level.unlocksItem = false
        level.unlocksPet = false
      }

      level.hidden = level.locked && (this.campaign?.get('type') !== 'hoc')
      if (level.concepts?.length) {
        level.displayConcepts = level.concepts
        const maxConcepts = 6
        if (level.displayConcepts.length > maxConcepts) {
          level.displayConcepts = level.displayConcepts.slice(-maxConcepts)
        }
      }

      level.unlockedInSameCampaign = levelIndex < 5 // First few are always counted (probably unlocked in previous campaign)
      for (const otherLevel of orderedLevels) {
        if (!level.unlockedInSameCampaign && (otherLevel !== level)) {
          for (const reward of otherLevel.rewards ?? []) {
            if (reward.level) {
              if (!level.unlockedInSameCampaign) { level.unlockedInSameCampaign = reward.level === level.original }
            }
          }
        }
      }

      if ((level.releasePhase === 'internalRelease') && !(me.isAdmin() || me.isArtisan() || me.isInGodMode() || this.editorMode)) {
        level.hidden = (level.locked = (level.disabled = true))
      } else if ((level.releasePhase === 'beta') && !this.editorMode) {
        const experimentValue = me.getM7ExperimentValue()
        if (experimentValue === 'beta') {
          level.disabled = false
          level.unlockedInSameCampaign = true
          if (betaLevelIndex === betaLevelCompletedIndex) {
            // All preceding beta levels, if any, have been completed, so this one is unlocked
            level.locked = (level.hidden = false)
            level.color = 'rgb(255, 80, 60)'
          } else {
            // This beta level is not unlocked yet
            level.locked = (level.hidden = true)
            level.color = 'rgb(193, 193, 193)'
          }
          ++betaLevelIndex
          if (this.levelStatusMap[level.slug] === 'complete') { ++betaLevelCompletedIndex }
        } else {
          level.hidden = (level.locked = (level.disabled = true))
        }
      }
    }
    if (betaLevelIndex && (betaLevelCompletedIndex < betaLevelIndex)) {
      // Lock all non-beta levels until beta levels are completed
      for (const level of orderedLevels) {
        if ((level.releasePhase !== 'beta') && !level.locked) {
          level.locked = (level.hidden = true)
          level.color = 'rgb(193, 193, 193)'
        }
      }
    }
    return null
  }

  countLevels (orderedLevels) {
    const count = { total: 0, completed: 0 }

    if (this.campaign?.get('type') === 'hoc') {
      // HoC: Just order left-to-right instead of looking at unlocks, which we don't use for this copycat campaign
      orderedLevels = _.sortBy(orderedLevels, level => level.position.x)
      for (const level of orderedLevels) {
        if (this.levelStatusMap[level.slug] === 'complete') { count.completed++ }
      }
      count.total = orderedLevels.length
      return count
    }

    for (let levelIndex = 0; levelIndex < orderedLevels.length; levelIndex++) {
      const level = orderedLevels[levelIndex]
      if (level.locked == null) { this.annotateLevels(orderedLevels) } // Annotate if we haven't already.
      if (level.disabled) { continue }
      const completed = this.levelStatusMap[level.slug] === 'complete'
      const started = this.levelStatusMap[level.slug] === 'started'
      if ((level.unlockedInSameCampaign || !level.locked) && (started || completed || !(level.locked && level.practice && /-[a-z]$/.test(level.slug)))) {
        ++count.total
      }
      if (completed) { ++count.completed }
    }

    return count
  }

  showLeaderboard (levelSlug) {
    const leaderboardModal = new LeaderboardModal({ supermodel: this.supermodel, levelSlug })
    return this.openModalView(leaderboardModal)
  }

  isClassroom () {
    return this.courseInstanceID != null
  }

  determineNextLevel (orderedLevels) {
    if (this.isClassroom()) {
      if (this.courseStats) { this.applyCourseLogicToLevels(orderedLevels) }
      return true
    }

    if (me.getM7ExperimentValue() === 'beta') {
      // Point out next experimental level, if any are incomplete
      for (const level of orderedLevels) {
        if ((level.releasePhase === 'beta') && (this.levelStatusMap[level.slug] !== 'complete')) {
          level.next = true
          return
        }
      }
    }

    const dontPointTo = ['lost-viking', 'kithgard-mastery'] // Challenge levels we don't want most players bashing heads against
    const subscriptionPrompts = [{ slug: 'boom-and-bust', unless: 'defense-of-plainswood' }]

    if (this.campaign?.get('type') === 'hoc') {
      // HoC: Just order left-to-right instead of looking at unlocks, which we don't use for this copycat campaign
      orderedLevels = _.sortBy(orderedLevels, level => level.position.x)
      for (const level of orderedLevels) {
        if (this.levelStatusMap[level.slug] !== 'complete') {
          level.next = true
          // Unlock and re-annotate this level
          // May not be unlocked/awarded due to different HoC progression using mostly shared levels
          level.locked = false
          level.hidden = level.locked
          level.disabled = false
          level.color = 'rgb(255, 80, 60)'
          return
        }
      }
    }

    const findNextLevel = (level, practiceOnly) => {
      for (const nextLevelOriginal of level.nextLevels) {
        const nextLevel = _.find(orderedLevels, { original: nextLevelOriginal })
        if (!nextLevel || nextLevel.locked) { continue }
        if (practiceOnly && !this.campaign.levelIsPractice(nextLevel)) { continue }
        if (this.campaign.levelIsAssessment(nextLevel)) { continue }
        if (this.campaign.levelIsAssessment(level) && this.campaign.levelIsPractice(nextLevel)) { continue }

        // // If it's a challenge level, we efficiently determine whether we actually do want to point it out.
        // // 2021-09-21: disabling for now, guessing it doesn't work well and makes experiments harder
        // if (false && (nextLevel.slug === 'kithgard-mastery') && !this.levelStatusMap[nextLevel.slug] && (this.calculateExperienceScore() >= 3)) {
        //   const timesPointedOut = storage.load(`pointed-out-${nextLevel.slug}`) || 0
        //   if (timesPointedOut <= 3) {
        //     // We may determineNextLevel more than once per render, so we can't just do this once. But we do give up after a couple highlights.
        //     dontPointTo = _.without(dontPointTo, nextLevel.slug)
        //     storage.save(`pointed-out-${nextLevel.slug}`, timesPointedOut + 1)
        //   }
        // }

        // Should we point this level out?
        if (!nextLevel.disabled && (this.levelStatusMap[nextLevel.slug] !== 'complete') && !dontPointTo.includes(nextLevel.slug) &&
        !nextLevel.replayable && (
          me.isPremium() || !nextLevel.requiresSubscription || // nextLevel.adventurer or  # Disable adventurer stuff for now
          _.any(subscriptionPrompts, prompt => (nextLevel.slug === prompt.slug) && !this.levelStatusMap[prompt.unless])
        )) {
          if (nextLevel.practice === true && nextLevel.slug.match(level.slug.replace(/-[a-z]$/, ''))) {
            // If this is a practice level for the current level, we don't want to point it out
            // This is a bit of a hack, but it's the best way to handle this for now
            // It works for the Junior levels where they have the same slug with a -a or -b at the end
            continue
          } else {
            nextLevel.next = true
          }
          return true
        }
      }
      return false
    }

    let foundNext = false
    for (let levelIndex = 0; levelIndex < orderedLevels.length; levelIndex++) {
      // Iterate through all levels in order and look to find the first unlocked one that meets all our criteria for being pointed out as the next level.
      const level = orderedLevels[levelIndex]
      if (this.campaign.get('type') === 'course') {
        level.nextLevels = []
        for (let nextLevelIndex = 0; nextLevelIndex < orderedLevels.length; nextLevelIndex++) {
          const nextLevel = orderedLevels[nextLevelIndex]
          if (nextLevelIndex > levelIndex) {
            if (nextLevel.practice && level.nextLevels.length) { continue }
            if (level.practice && !nextLevel.practice) { break }
            level.nextLevels.push(nextLevel.original)
            if (!nextLevel.practice) { break }
          }
        }
      } else {
        level.nextLevels = level.rewards?.filter(reward => reward.level).map(reward => reward.level) ?? []
      }
      if (!foundNext && !this.campaign.levelIsAssessment(level)) { foundNext = findNextLevel(level, true) } // Check practice levels first
      if (!foundNext) { foundNext = findNextLevel(level, false) }
    }

    if (!foundNext && orderedLevels[0] && !orderedLevels[0].locked && (this.levelStatusMap[orderedLevels[0].slug] !== 'complete')) {
      orderedLevels[0].next = true
    }
  }

  calculateExperienceScore () {
    const adultPoint = ['18-24', '25-34', '35-44', '45-100'].includes(me.get('ageRange')) ? 1 : 0 // They have to have answered the poll for this, likely after Shadow Guard.
    let speedPoints = 0
    const speedThresholds = [
      ['dungeons-of-kithgard', 50],
      ['gems-in-the-deep', 55],
      ['shadow-guard', 55],
      ['forgetful-gemsmith', 40],
      ['true-names', 40],
    ]
    for (const [levelSlug, speedThreshold] of speedThresholds) {
      if (this.sessions?.models.find(session => session.get('levelID') === levelSlug)?.attributes.playtime <= speedThreshold) {
        ++speedPoints
      }
    }
    const experienceScore = adultPoint + speedPoints // 0-6 score of how likely we think they are to be experienced and ready for Kithgard Mastery
    return experienceScore
  }

  createLines () {
    for (const level of this.campaign?.renderedLevels || []) {
      for (const nextLevelOriginal of level.nextLevels || []) {
        const nextLevel = _.find(this.campaign.renderedLevels, { original: nextLevelOriginal })
        if (nextLevel) {
          this.createLine(level.position, nextLevel.position)
        }
      }
    }
  }

  createLine (o1, o2) {
    const mapHeight = parseFloat($('.map').css('height'))
    const mapWidth = parseFloat($('.map').css('width'))
    if (!(mapHeight > 0)) { return }
    const ratio = mapWidth / mapHeight
    const p1 = { x: o1.x, y: o1.y / ratio }
    const p2 = { x: o2.x, y: o2.y / ratio }
    const length = Math.sqrt(Math.pow(p1.x - p2.x, 2) + Math.pow(p1.y - p2.y, 2))
    const angle = (Math.atan2(p1.y - p2.y, p2.x - p1.x) * 180) / Math.PI
    const transform = `translateY(-50%) translateX(-50%) rotate(${angle}deg) translateX(50%)`
    const line = $('<div>').appendTo('.map').addClass('next-level-line').css({ transform, width: length + '%', left: o1.x + '%', bottom: (o1.y - 0.5) + '%' })
    return line.append($('<div class="line">')).append($('<div class="point">'))
  }

  applyCampaignStyles () {
    if (!this.campaign?.loaded) { return }
    const backgrounds = this.campaign.get('backgroundImage')
    if (backgrounds?.length) {
      backgrounds.sort((a, b) => b.width - a.width)
      const rules = backgrounds.map((background, i) => {
        let rule = `#campaign-view .map-background { background-image: url(/file/${background.image}); }`
        if (i) { rule = `@media screen and (max-width: ${background.width}px) { ${rule} }` }
        return rule
      })
      utils.injectCSS(rules.join('\n'))
    }
    const backgroundColor = this.campaign.get('backgroundColor')
    if (backgroundColor) {
      const backgroundColorTransparent = this.campaign.get('backgroundColorTransparent')
      this.$el.css('background-color', backgroundColor)
      for (const pos of ['top', 'right', 'bottom', 'left']) {
        this.$el.find(`.${pos}-gradient`).css('background-image', `linear-gradient(to ${pos}, ${backgroundColorTransparent} 0%, ${backgroundColor} 100%)`)
      }
    }
    return this.playAmbientSound()
  }

  onMouseEnterPortals (e) {
    if (!this.campaigns?.loaded || !this.sessions?.loaded) { return }
    this.portalScrollInterval = setInterval(this.onMouseMovePortals, 100)
    return this.onMouseMovePortals(e)
  }

  onMouseLeavePortals (e) {
    if (!this.portalScrollInterval) { return }
    clearInterval(this.portalScrollInterval)
    this.portalScrollInterval = null
  }

  onMouseMovePortals (e) {
    if (!this.portalScrollInterval) { return }
    const $portal = this.$el.find('.portal')
    const $portals = this.$el.find('.portals')
    if (e) {
      this.portalOffsetX = Math.round(Math.max(0, e.clientX - $portal.offset().left))
    }
    const bodyWidth = $('body').innerWidth()
    const fraction = this.portalOffsetX / bodyWidth
    if (fraction > 0.2 && fraction < 0.8) { return }
    const direction = fraction < 0.5 ? 1 : -1
    const magnitude = (0.2 * bodyWidth * (direction === -1 ? fraction - 0.8 : 0.2 - fraction)) / 0.2
    const portalsWidth = 2853 // TODO: if we add campaigns or change margins, this will get out of date...
    let scrollTo = $portals.offset().left + (direction * magnitude)
    scrollTo = Math.max(bodyWidth - portalsWidth, scrollTo)
    scrollTo = Math.min(0, scrollTo)
    return $portals.stop().animate({ marginLeft: scrollTo }, 100, 'linear')
  }

  onSessionsLoaded (e) {
    if (this.editorMode) { return }
    this.render()
    if (!me.get('anonymous') && !me.inEU() && !window.serverConfig.picoCTF) {
      this.loadUserPollsRecord()
    }
  }

  onCampaignsLoaded (e) {
    return this.render()
  }

  preloadLevel (levelSlug) {
    const levelURL = `/db/level/${levelSlug}`
    const level = new Level().setURL(levelURL)
    this.supermodel.loadModel(level, null, 0)

    // Note that this doesn't just preload the level. For sessions which require the
    // campaign to be included, it also creates the session. If this code is changed,
    // make sure to accommodate campaigns with free-in-certain-campaign-contexts levels,
    // such as game dev levels in game-dev-hoc.
    let sessionURL = `/db/level/${levelSlug}/session?campaign=${this.campaign.id}`
    const courseID = this.course?.get('_id')
    if (courseID) {
      sessionURL += `&course=${courseID}`
      if (this.courseInstanceID) {
        sessionURL += `&courseInstance=${this.courseInstanceID}`
      }
    }

    this.preloadedSession = new LevelSession().setURL(sessionURL)
    this.listenToOnce(this.preloadedSession, 'sync', this.onSessionPreloaded)
    this.listenToOnce(this.preloadedSession, 'error', this.onSessionPreloadError)
    this.preloadedSession = this.supermodel.loadModel(this.preloadedSession, { cache: false }).model
    this.preloadedSession.levelSlug = levelSlug
  }

  onSessionPreloaded (session) {
    session.url = function () { return '/db/level.session/' + this.id }
    const levelElement = this.$el.find('.level-info-container:visible')
    if (session.levelSlug !== levelElement.data('level-slug')) { return }
    const difficulty = session.get('state')?.difficulty
    if (!difficulty) { return }
    const badge = $(`<span class='badge'>${difficulty}</span>`)
    levelElement.find('.start-level .badge').remove()
    levelElement.find('.start-level').append(badge)
    levelElement.toggleClass('has-loading-error', false)
  }

  onSessionPreloadError (session, error) {
    if (/requires a subscription to play/.test(error?.responseJSON?.message)) { return } // We handle this with SubscribeModal separately
    const levelElement = this.$el.find('.level-info-container:visible')
    if (session.levelSlug !== levelElement.data('level-slug')) { return }
    levelElement.find('.level-error-message').text(error.responseJSON?.message || `Cannot load this level--error ${error.statusCode || 500}`)
    levelElement.toggleClass('has-loading-error', true)
  }

  highlightNextLevel () {
    this.highlightElement('.level.next', { delay: 500, duration: 60000, rotation: 0, sides: ['top'] })
  }

  onClickMap (e) {
    this.$levelInfo?.hide()
    if (this.sessions?.models.length < 3) {
      // Restore the next level higlight for very new players who might otherwise get lost.
      this.highlightNextLevel()
    }
  }

  onClickLevel (e) {
    e.preventDefault()
    e.stopPropagation()
    this.$levelInfo?.hide()
    const levelElement = $(e.target).closest('.level')
    const levelSlug = levelElement.data('level-slug')
    if (!levelSlug) { return } // Roblox Modal
    const levelOriginal = levelElement.data('level-original')
    if (this.editorMode) {
      return this.trigger('level-clicked', levelOriginal)
    }
    this.$levelInfo = this.$el.find(`.level-info-container[data-level-slug=${levelSlug}]`).show()
    this.checkForCourseOption(levelOriginal)
    this.adjustLevelInfoPosition(e)
    this.endHighlight()
    this.preloadLevel(levelSlug)
  }

  onDoubleClickLevel (e) {
    if (!this.editorMode) { return }
    const levelElement = $(e.target).closest('.level')
    const levelOriginal = levelElement.data('level-original')
    this.trigger('level-double-clicked', levelOriginal)
  }

  onClickStartLevel (e) {
    const levelElement = $(e.target).closest('.btn')
    const levelSlug = levelElement.data('level-slug')
    const levelOriginal = levelElement.data('level-original')
    const levelPath = levelElement.data('level-path')
    const levelName = levelElement.data('level-name')
    const level = _.find(_.values(this.getLevels()), { slug: levelSlug })

    let defaultAccess = me.get('hourOfCode') || (this.campaign?.get('type') === 'hoc') || (this.campaign?.get('slug') === 'intro') ? 'long' : 'short'
    if (new Date(me.get('dateCreated')) < new Date('2021-09-21')) {
      defaultAccess = 'all'
    }
    let access
    if (this.terrain === 'junior') {
      access = 'all' // CodeCombat Junior level access is managed the old way, with level.requiresSubscription, no hardcoded overrides
    }
    access = access || me.getExperimentValue('home-content', defaultAccess)
    if (me.showChinaResourceInfo() || (me.get('country') === 'japan')) {
      access = 'short'
    }
    const freeAccessLevels = utils.freeAccessLevels
      .filter(fal => {
        if (fal.access === 'short') return true
        if (fal.access === 'medium' && ['medium', 'long', 'extended'].includes(access)) return true
        if (fal.access === 'long' && ['long', 'extended'].includes(access)) return true
        if (fal.access === 'extended' && access === 'extended') return true
        return false
      })
      .map(fal => fal.slug)

    const requiresSubscription = level.requiresSubscription || ((access !== 'all') && !freeAccessLevels.includes(level.slug))
    const canPlayAnyway = [
      !this.requiresSubscription,
      // level.adventurer  # Disable adventurer stuff for now
      this.levelStatusMap[level.slug],
      this.campaign.get('type') === 'hoc',
      (level.releasePhase === 'beta') && (me.getM7ExperimentValue() === 'beta'),
    ].some(Boolean)

    if (requiresSubscription && !canPlayAnyway) {
      return this.promptForSubscription(levelSlug, 'map level clicked')
    } else {
      this.startLevel({ levelSlug, levelOriginal, levelPath, levelName })
      window.tracker?.trackEvent('Clicked Start Level', { category: 'World Map', levelID: levelSlug })
    }
  }

  onClickCourseVersion (e) {
    const courseVersionElement = $(e.target).closest('.course-version')
    const levelSlug = courseVersionElement.data('level-slug')
    const levelOriginal = courseVersionElement.data('level-original')
    const courseID = courseVersionElement.data('course-id')
    const courseInstanceID = courseVersionElement.data('course-instance-id')
    const levelPath = courseVersionElement.data('level-path')
    const levelName = courseVersionElement.data('level-name')

    const classroomLevel = this.classroomLevelMap?.[levelOriginal]

    // If classroomItems is on, don't go to PlayLevelView directly.
    // Go through LevelSetupManager which will load required modals before going to PlayLevelView.
    if (me.showHeroAndInventoryModalsToStudents() && (!classroomLevel || classroomLevel.usesSessionHeroInventory())) {
      this.startLevel({ levelSlug, levelOriginal, courseID, courseInstanceID, levelPath, levelName })
      window.tracker?.trackEvent('Clicked Start Level', { category: 'World Map', levelID: levelSlug })
    } else {
      const url = `/play/level/${levelSlug}?course=${courseID}&course-instance=${courseInstanceID}`
      Backbone.Mediator.publish('router:navigate', { route: url })
    }
  }

  startLevel ({ levelOriginal, levelSlug, courseID, courseInstanceID, levelPath, levelName }) {
    this.setupManager?.destroy()
    const classroomLevel = this.classroomLevelMap?.[levelOriginal]
    const session = this.preloadedSession?.loaded && this.preloadedSession.levelSlug === levelSlug ? this.preloadedSession : null
    const codeLanguage = classroomLevel?.get('primerLanguage') || this.classroom?.get('aceConfig')?.language || session?.get('codeLanguage')
    const options = {
      supermodel: this.supermodel,
      levelID: levelSlug,
      levelPath,
      levelName,
      campaign: this.campaign,
      hadEverChosenHero: this.hadEverChosenHero,
      parent: this,
      session,
      courseID,
      courseInstanceID,
      codeLanguage,
    }
    this.setupManager = new LevelSetupManager(options)
    if (!this.setupManager?.navigatingToPlay) {
      this.$levelInfo?.find('.level-info, .progress').toggleClass('hide')
      this.listenToOnce(this.setupManager, 'open', () => {
        this.$levelInfo?.find('.level-info, .progress').toggleClass('hide')
        this.$levelInfo?.hide()
      })
      this.setupManager.open()
    }
  }

  onClickViewSolutions (e) {
    const levelElement = $(e.target).closest('.level-info-container')
    const levelSlug = levelElement.data('level-slug')
    const level = _.find(_.values(this.getLevels()), { slug: levelSlug })
    if (['ladder', 'hero-ladder', 'course-ladder'].includes(level.type)) { // Would use isType, but it's not a Level model
      Backbone.Mediator.publish('router:navigate', { route: `/play/ladder/${levelSlug}`, viewClass: 'views/ladder/LadderView', viewArgs: [{ supermodel: this.supermodel }, levelSlug] })
    } else {
      this.showLeaderboard(levelSlug)
    }
  }

  adjustLevelInfoPosition (e) {
    if (!this.$levelInfo) { return }
    this.$map = this.$map ?? this.$el.find('.map')
    const mapOffset = this.$map.offset()
    const mapX = e.pageX - mapOffset.left
    const mapY = e.pageY - mapOffset.top
    const margin = 20
    const width = this.$levelInfo.outerWidth()
    const left = Math.min(Math.max(margin, mapX - (width / 2)), this.$map.width() - width - margin)
    this.$levelInfo.css('left', left)
    let top = mapY - this.$levelInfo.outerHeight() - 60
    if (top < 100) {
      top = mapY + 60
    }
    this.$levelInfo.css('top', top)
  }

  onWindowResize (e) {
    const mapHeight = 1536
    const mapWidths = {
      dungeon: 2350,
      forest: 2500,
      auditions: 2500,
      desert: 2411,
      mountain: 2421,
      glacier: 2413,
      junior: 2214,
      'campaign-game-dev-1': 2500,
      'campaign-game-dev-2': 2500,
      'campaign-game-dev-3': 2500,
      'campaign-web-dev-1': 2500,
      'campaign-web-dev-2': 2500,
      'game-dev-1': 2500,
      'game-dev-2': 2500,
      'game-dev-3': 2500,
      'web-dev-1': 2500,
      'web-dev-2': 2500,
      'course-3': 2500,
      'course-4': 2411,
      'course-5': 2421,
      'course-6': 2413,
    }
    const mapWidth = mapWidths[this.terrain] || 2350
    const aspectRatio = mapWidth / mapHeight
    const pageWidth = this.$el.width()
    const pageHeight = this.$el.height()
    const widthRatio = pageWidth / mapWidth
    const heightRatio = pageHeight / mapHeight

    let resultingWidth, resultingHeight
    // Make sure we can see the whole map, fading to background in one dimension.
    if (heightRatio <= widthRatio) {
      // Left and right margin
      resultingHeight = pageHeight
      resultingWidth = resultingHeight * aspectRatio
    } else {
      // Top and bottom margin
      resultingWidth = pageWidth
      resultingHeight = resultingWidth / aspectRatio
    }
    const resultingMarginX = (pageWidth - resultingWidth) / 2
    const resultingMarginY = (pageHeight - resultingHeight) / 2
    this.$el.find('.map').css({ width: resultingWidth, height: resultingHeight, 'margin-left': resultingMarginX, 'margin-top': resultingMarginY })
    if (this.pointerInterval) {
      this.highlightNextLevel()
    }
  }

  playAmbientSound () {
    if (!me.get('volume')) { return }
    if (this.ambientSound) { return }
    const file = this.campaign?.get('ambientSound')?.[AudioPlayer.ext.substr(1)]
    if (!file) { return }
    const src = `/file/${file}`
    if (!AudioPlayer.getStatus(src)?.loaded) {
      AudioPlayer.preloadSound(src)
      Backbone.Mediator.subscribeOnce('audio-player:loaded', this.playAmbientSound, this)
      return
    }
    this.ambientSound = createjs.Sound.play(src, { loop: -1, volume: 0.1 })
    createjs.Tween.get(this.ambientSound).to({ volume: 0.5 }, 1000)
  }

  playMusic () {
    this.musicPlayer = new MusicPlayer()
    const musicFile = '/music/music-menu'
    Backbone.Mediator.publish('music-player:play-music', { play: true, file: musicFile })
    if (!this.probablyCachedMusic) {
      storage.save('loaded-menu-music', true)
    }
  }

  checkForCourseOption (levelOriginal) {
    const showButton = courseInstance => {
      this.$el.find(`.level-info-container[data-level-original='${levelOriginal}'] .course-version`)
        .removeClass('hidden')
        .data({ 'course-id': courseInstance.get('courseID'), 'course-instance-id': courseInstance.id })
    }

    if (this.courseInstance) {
      showButton(this.courseInstance)
    } else {
      if (!me.get('courseInstances')?.length) { return }
      this.courseOptionsChecked = this.courseOptionsChecked ?? {}
      if (this.courseOptionsChecked[levelOriginal]) { return }
      this.courseOptionsChecked[levelOriginal] = true
      const courseInstances = new CocoCollection([], { url: `/db/course_instance/-/find_by_level/${levelOriginal}`, model: CourseInstance })
      courseInstances.comparator = ci => -(ci.get('members')?.length ?? 0)
      this.supermodel.loadCollection(courseInstances, 'course_instances')
      this.listenToOnce(courseInstances, 'sync', () => {
        if (this.destroyed) { return }
        const courseInstance = courseInstances.models[0]
        if (courseInstance) {
          showButton(courseInstance)
        }
      })
    }
  }

  preloadTopHeroes () {
    if (window.serverConfig.picoCTF) { return }
    for (const heroID of ['captain', 'knight']) {
      const url = `/db/thang.type/${ThangType.heroes[heroID]}/version`
      if (this.supermodel.getModel(url)) { continue }
      const fullHero = new ThangType()
      fullHero.setURL(url)
      this.supermodel.loadModel(fullHero)
    }
  }

  updateVolume (volume) {
    volume = volume ?? me.get('volume') ?? 1.0
    const button = $('#volume-button', this.$el)
    button.toggleClass('vol-off', volume <= 0.0)
    button.toggleClass('vol-down', volume > 0.0 && volume < 1.0)
    button.toggleClass('vol-up', volume >= 1.0)
    createjs.Sound.volume = volume === 1 ? 0.6 : volume // Quieter for now until individual sound FX controls work again.
    if (volume !== me.get('volume')) {
      me.set('volume', volume)
      me.patch()
      if (volume) {
        this.playAmbientSound()
      }
    }
  }

  onToggleVolume (e) {
    const button = $(e.target).closest('#volume-button')
    const classes = ['vol-off', 'vol-down', 'vol-up']
    const volumes = [0, 0.4, 1.0]
    let newI = 2
    for (let i = 0; i < classes.length; i++) {
      if (button.hasClass(classes[i])) {
        newI = (i + 1) % classes.length
        break
      }
    }
    this.updateVolume(volumes[newI])
  }

  onClickBack (e) {
    Backbone.Mediator.publish('router:navigate', {
      route: '/play',
      viewClass: CampaignView,
      viewArgs: [{ supermodel: this.supermodel }],
    })
  }

  onClickClearStorage (e) {
    localStorage.clear()
    noty({
      text: 'Local storage cleared. Reload to view the original campaign.',
      layout: 'topCenter',
      timeout: 5000,
      type: 'information',
    })
  }

  updateHero () {
    const hero = me.get('heroConfig')?.thangType
    if (!hero) { return }
    for (const [slug, original] of Object.entries(ThangType.heroes)) {
      if (original === hero) {
        this.$el.find('.player-hero-icon').removeClass().addClass(`player-hero-icon ${slug}`)
        return
      }
    }
    console.error("CampaignView hero update couldn't find hero slug for original:", hero)
  }

  onClickPortalCampaign (e) {
    const campaign = $(e.target).closest('.campaign, .beta-campaign')
    if (campaign.is('.locked') || campaign.is('.silhouette')) { return }
    const campaignSlug = campaign.data('campaign-slug')
    if (this.isPremiumCampaign(campaignSlug) && !me.isPremium()) {
      return this.promptForSubscription(campaignSlug, 'premium campaign clicked')
    }
    Backbone.Mediator.publish('router:navigate', {
      route: `/play/${campaignSlug}`,
      viewClass: CampaignView,
      viewArgs: [{ supermodel: this.supermodel }, campaignSlug],
    })
  }

  onClickCampaignSwitch (e) {
    const campaignSlug = $(e.target).data('campaign-slug')
    if (this.isPremiumCampaign(campaignSlug) && !me.isPremium()) {
      e.preventDefault()
      e.stopImmediatePropagation()
      return this.promptForSubscription(campaignSlug, 'premium campaign switch clicked')
    }
  }

  loadUserPollsRecord () {
    if (storage.load('ignored-poll')) { return }
    const url = `/db/user.polls.record/-/user/${me.id}`
    this.userPollsRecord = new UserPollsRecord().setURL(url)
    const onRecordSync = () => {
      if (this.destroyed) { return }
      this.userPollsRecord.url = () => '/db/user.polls.record/' + this.userPollsRecord.id
      const lastVoted = new Date(this.userPollsRecord.get('changed') || 0)
      const interval = new Date() - lastVoted
      if (interval > (22 * 60 * 60 * 1000)) { // Wait almost a day before showing the next poll
        this.loadPoll()
      } else {
        console.log('Poll will be ready in', ((22 * 60 * 60 * 1000) - interval) / (60 * 60 * 1000), 'hours.')
      }
    }
    this.listenToOnce(this.userPollsRecord, 'sync', onRecordSync)
    this.userPollsRecord = this.supermodel.loadModel(this.userPollsRecord, null, 0).model
    if (this.userPollsRecord.loaded) {
      onRecordSync()
    }
  }

  loadPoll (url, forceShowPoll) {
    if (url == null) { url = `/db/poll/${this.userPollsRecord.id}/next` }
    let tempLoadingPoll = new Poll().setURL(url)
    const onPollSync = () => {
      if (this.destroyed) { return }
      tempLoadingPoll.url = () => '/db/poll/' + tempLoadingPoll.id
      this.poll = tempLoadingPoll
      const delay = forceShowPoll ? 1000 : 5000 // Wait a little bit before showing the poll
      setTimeout(() => this.activatePoll?.(forceShowPoll), delay)
    }
    const onPollError = (poll, response, request) => {
      if (response.status === 404) {
        console.log('There are no more polls left.')
      } else {
        console.error("Couldn't load poll:", response.status, response.statusText)
      }
      if (this.poll) {
        delete this.poll
      }
    }
    this.listenToOnce(tempLoadingPoll, 'sync', onPollSync)
    this.listenToOnce(tempLoadingPoll, 'error', onPollError)
    tempLoadingPoll = this.supermodel.loadModel(tempLoadingPoll, null, 0).model
    if (tempLoadingPoll.loaded) {
      onPollSync()
    }
  }

  activatePoll (forceShowPoll) {
    if (this.shouldShow('promotion') || this.shouldShow('junior-promotion')) { return }
    if (!this.poll) { return }
    const pollTitle = utils.i18n(this.poll.attributes, 'name')
    const $pollButton = this.$el.find('button.poll')
      .removeClass('hidden')
      .addClass('highlighted')
      .attr({ title: pollTitle })
      .addClass('has-tooltip')
      .tooltip({ title: pollTitle })

    if ((me.get('lastLevel') === 'shadow-guard') || forceShowPoll) {
      return this.showPoll()
    } else {
      $pollButton.tooltip('show')
      setTimeout(() => {
        $pollButton?.tooltip('hide')
        if (!this.destroyed) {
          storage.save('ignored-poll', true, 5) //  Don't show again in next N minutes
        }
      }, 20000) // Don't leave the poll open forever
    }
  }

  showPoll () {
    if (!this.shouldShow('poll')) { return false }
    if (this.poll.get('slug') === 'how-old-are-you' && userUtils.isCreatedViaLibrary()) {
      return false // since the answers of how-old-are-you poll do no have nextPoll, so just return is fine
    }
    const pollModal = new PollModal({ supermodel: this.supermodel, poll: this.poll, userPollsRecord: this.userPollsRecord })
    this.openModalView(pollModal)
    const $pollButton = this.$el.find('button.poll')
    pollModal.on('vote-updated', () => $pollButton.removeClass('highlighted').tooltip('hide'))
    pollModal.once('trigger-next-poll', nextPollId => {
      this.loadPoll('/db/poll/' + nextPollId, true)
    })
    pollModal.once('trigger-show-live-classes', () => {
      this.openModalView(new LiveClassroomModal())
    })
    pollModal.once('trigger-codequest-modal', () => {
      this.openModalView(new Codequest2020Modal())
    })
  }

  onClickPremiumButton (e) {
    const trackProperties = { category: 'Subscription', label: 'campaignview premium button' }
    if (me.isParentHome()) {
      this.handleParentAccountPremiumPurchase({ trackProperties })
    } else {
      this.openModalView(new SubscribeModal())
      window.tracker?.trackEvent('Show subscription modal', trackProperties)
    }
  }

  handleParentAccountPremiumPurchase ({ trackProperties }) {
    const showModalAndTrack = () => {
      this.openModalView(new SubscribeModal())
      window.tracker?.trackEvent('Show subscription modal', trackProperties)
    }

    if (userUtils.hasSeenParentBuyingforSelfPrompt()) {
      showModalAndTrack()
    } else {
      if (window.confirm($.i18n.t('subscribe.sure_buy_as_parent'))) {
        showModalAndTrack()
      }
      userUtils.markParentBuyingForSelfPromptSeen()
    }
  }

  onClickM7OffButton (e) {
    return noty({
      text: $.i18n.t('play.confirm_m7_off'),
      layout: 'center',
      type: 'warning',
      buttons: [
        {
          text: 'Yes',
          onClick: $noty => {
            if (me.getM7ExperimentValue() === 'beta') {
              me.updateExperimentValue('m7', 'control')
              $noty.close()
              return this.render()
            }
          },
        },
        {
          text: 'No',
          onClick: $noty => $noty.close(),
        },
      ],
    })
  }

  getLoadTrackingTag () {
    return this.campaign?.get('slug') || 'overworld'
  }

  mergeWithPrerendered (el) {
    return true
  }

  checkForUnearnedAchievements () {
    if (!this.campaign || !globalVar.currentView.sessions) { return }

    // Another layer attempting to make sure users unlock levels properly.

    // Every time the user goes to the campaign view (after initial load),
    // load achievements for that campaign.
    // Look for any achievements where the related level is complete, but
    // the reward level is not earned.
    // Try to create EarnedAchievements for each such Achievement found.

    const achievements = new Achievements()

    return achievements.fetchForCampaign(
      this.campaign.get('slug'),
      { data: { project: 'related,rewards,name' } },
    ).done(achievements => {
      if (this.destroyed) { return }
      const sessionsComplete = globalVar.currentView.sessions.models
        .filter(s => s.get('levelID'))
        .filter(s => s.get('state')?.complete)
        .map(s => [s.get('levelID'), s.id])

      const sessionsCompleteMap = Object.fromEntries(sessionsComplete)

      const campaignLevels = this.getLevels()

      const levelsEarned = me.get('earned')?.levels
        ?.filter(levelOriginal => campaignLevels[levelOriginal])
        .map(levelOriginal => campaignLevels[levelOriginal].slug)
        .filter(Boolean) || []

      const levelsEarnedMap = Object.fromEntries(levelsEarned.map(level => [level, true]))

      const levelAchievements = achievements.filter(
        a => a.rewards && a.rewards.levels && a.rewards.levels.length,
      )

      let hadMissedAny = false
      for (const achievement of levelAchievements) {
        if (!campaignLevels[achievement.related]) { continue }
        const relatedLevelSlug = campaignLevels[achievement.related].slug
        for (const levelOriginal of achievement.rewards.levels) {
          if (!campaignLevels[levelOriginal]) { continue }
          const rewardLevelSlug = campaignLevels[levelOriginal].slug
          if (sessionsCompleteMap[relatedLevelSlug] && !levelsEarnedMap[rewardLevelSlug]) {
            const ea = new EarnedAchievement({
              achievement: achievement._id,
              triggeredBy: sessionsCompleteMap[relatedLevelSlug],
              collection: 'level.sessions',
            })
            hadMissedAny = true
            ea.notyErrors = false
            ea.save()
              .error(() => console.warn('Achievement NOT complete:', achievement.name))
          }
        }
      }
      if (hadMissedAny) {
        window.tracker?.trackEvent('Fixed Unearned Achievement', { category: 'World Map', label: this.terrain })
      }
    })
  }

  maybeShowPendingAnnouncement () {
    if (me.freeOnly()) { return false } // TODO: handle announcements that can be shown to free only servers
    if (this.payPalToken) { return false }
    if (me.isStudent()) { return false }
    if (application.getHocCampaign()) { return false }
    if (me.isInHourOfCode()) { return false }
    if (userUtils.isInLibraryNetwork() || userUtils.libraryName()) { return false }
    const latest = window.serverConfig.latestAnnouncement
    const myLatest = me.get('lastAnnouncementSeen')
    if (typeof latest !== 'number') { return }
    const accountHours = (new Date() - new Date(me.get('dateCreated'))) / (60 * 60 * 1000) // min*sec*ms
    if (accountHours <= 18) { return }
    if ((latest > myLatest) || (myLatest == null)) {
      me.set('lastAnnouncementSeen', latest)
      me.save()
      window.tracker?.trackEvent('Show announcement modal', { label: latest + '' })
      return this.openModalView(new AnnouncementModal({ announcementId: latest }))
    }
  }

  onClickBrainPopReplayButton () {
    return api.users.resetProgress({ userId: me.id }).then(() => document.location.reload())
  }

  getLevels () {
    if (this.courseLevels != null) { return this.courseLevelsFake }
    return this.campaign?.get('levels')
  }

  applyCourseLogicToLevels (orderedLevels) {
    const nextSlug = this.courseStats.levels.next?.get('slug') || this.courseStats.levels.first?.get('slug')
    if (!nextSlug) { return }

    const courseOrder = ['junior', '65c56663d2ca2055e65676af'].includes(this.terrain) ? orderedLevels : _.sortBy(orderedLevels, 'courseIdx')
    let found = false
    let prev = null
    let lastNormalLevel = null
    let lockedByTeacher = false
    for (const level of courseOrder) {
      const playerState = this.levelStatusMap[level.slug]
      level.color = 'rgb(255, 80, 60)'
      level.disabled = false

      if (level.slug === nextSlug && !this.classroom.isStudentOnLockedLevel(me.get('_id'), this.course.get('_id'), level.original)) {
        level.locked = false
        level.hidden = false
        level.next = true
        found = true
      } else if (['started', 'complete'].includes(playerState)) {
        level.hidden = false
        level.locked = false
      } else {
        if (level.practice) {
          if (prev?.next) {
            level.hidden = !prev?.practice
            level.locked = true
          } else if (prev) {
            level.hidden = prev.hidden
            level.locked = prev.locked
          } else {
            level.hidden = true
            level.locked = true
          }
        } else if (level.assessment) {
          level.hidden = false
          level.locked = this.levelStatusMap[lastNormalLevel?.slug] !== 'complete'
        } else {
          level.locked = found
          level.hidden = false
        }
      }

      if ((!prev || !prev.locked) && level.locked && this.classroom.isStudentOnOptionalLevel(me.get('_id'), this.course.get('_id'), level.original)) {
        level.locked = false
      }

      level.noFlag = !level.next

      let lockSkippedLevel = false
      const startLockedLevel = this.courseInstance.get('startLockedLevel')
      const legacyLock = startLockedLevel && level.slug === startLockedLevel

      if (legacyLock ||
      this.classroom.isStudentOnLockedLevel(me.get('_id'), this.course.get('_id'), level.original)) {
        if (!this.classroom.isStudentOnOptionalLevel(me.get('_id'), this.course.get('_id'), level.original)) {
          lockedByTeacher = true
        } else {
          lockSkippedLevel = true
        }
      }

      if (lockedByTeacher || lockSkippedLevel) {
        level.locked = true
        level.lockedByTeacher = true
      }

      if (level.locked) {
        level.color = 'rgb(193, 193, 193)'
      } else if (level.practice) {
        level.color = 'rgb(45, 145, 81)'
      } else if (level.assessment) {
        level.color = '#AD62F8'
        if (playerState !== 'complete') {
          level.noFlag = false
        }
      }
      level.unlocksHero = false
      level.unlocksItem = false
      prev = level
      if (!this.campaign.levelIsPractice(level) && !this.campaign.levelIsAssessment(level) && !this.classroom.isStudentOnOptionalLevel(me.get('_id'), this.course.get('_id'), level.original)) {
        lastNormalLevel = level
      }
    }

    return true
  }

  shouldShow (what) {
    const isStudentOrTeacher = me.isStudent() || me.isTeacher()
    const isIOS = me.get('iosIdentifierForVendor') || application.isIPadApp

    if (what === 'junior-level') {
      return me.isHomeUser() && !this.editorMode
    }

    if (what === 'classroom-level-play-button') {
      const isValidStudent = me.isStudent() && (this.courseInstance || (me.get('courseInstances')?.length && (this.campaign.get('slug') !== 'intro')))
      const isValidTeacher = me.isTeacher()
      return (isValidStudent || isValidTeacher) && !application.getHocCampaign()
    }

    if (features.noAuth && (what === 'status-line')) {
      return false
    }

    if (what === 'promotion') {
      return me.finishedAnyLevels() && !features.noAds && !isStudentOrTeacher && (me.get('country') === 'united-states') && (me.get('preferredLanguage', true) === 'en-US') && (new Date() < new Date(2019, 11, 20))
    }

    if (what === 'junior-promotion') {
      return !me.finishedAnyLevels() && !this.terrain && me.getJuniorExperimentValue() === 'beta'
    }

    if (['status-line'].includes(what)) {
      return (me.showGemsAndXpInClassroom() || !isStudentOrTeacher) && !this.editorMode
    }

    if (['gems'].includes(what)) {
      return me.showGemsAndXpInClassroom() || !isStudentOrTeacher
    }

    if (['level', 'xp'].includes(what)) {
      return me.showGemsAndXpInClassroom() || !isStudentOrTeacher
    }

    if (['leaderboard'].includes(what) && this.terrain === 'junior') {
      return false
    }

    if (['settings', 'leaderboard', 'back-to-campaigns', 'poll', 'items', 'heros', 'achievements'].includes(what)) {
      return !isStudentOrTeacher && !this.editorMode
    }

    if (['clans'].includes(what)) {
      return !isStudentOrTeacher && !this.editorMode && !userUtils.isCreatedViaLibrary()
    }

    if (['back-to-classroom'].includes(what)) {
      return isStudentOrTeacher && (!application.getHocCampaign() || (this.terrain === 'intro')) && !this.editorMode
    }

    if (['videos'].includes(what)) {
      return me.isStudent() && this.course?.get('_id') === utils.courseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE && !this.editorMode
    }

    if (['buy-gems'].includes(what)) {
      return !(isIOS || me.freeOnly() || isStudentOrTeacher || !me.canBuyGems() || (application.getHocCampaign() && me.isAnonymous())) && !this.editorMode
    }

    if (['premium'].includes(what)) {
      return !(me.isPremium() || isIOS || me.freeOnly() || isStudentOrTeacher || (application.getHocCampaign() && me.isAnonymous()) || paymentUtils.hasTemporaryPremiumAccess()) && !this.editorMode
    }

    if (what === 'anonymous-classroom-signup') {
      return me.isAnonymous() && (me.level() < 8) && me.promptForClassroomSignup() && !this.editorMode && this.terrain !== 'junior' && !storage.load('hid-anonymous-classroom-signup-dialog')
    }

    if (what === 'amazon-campaign') {
      return this.campaign?.get('slug') === 'game-dev-hoc' && !this.editorMode
    }

    const libraryLogos = [
      'santa-clara', 'garfield', 'arapahoe', 'houston', 'burnaby',
      'liverpool-library', 'lafourche-library', 'shreve-library', 'vaughan-library',
      'surrey-library', 'okanagan-library', 'east-baton-library',
    ]

    if (libraryLogos.includes(what.replace('-logo', ''))) {
      return userUtils.libraryName() === what.replace('-logo', '')
    }

    if (what === 'league-arena') {
      // Note: Currently the tooltips don't work in the campaignView overworld.
      return !me.isAnonymous() && this.campaign?.get('slug') && !this.editorMode && !userUtils.isCreatedViaLibrary()
    }

    if (what === 'roblox-level') {
      return this.userQualifiesForRobloxModal() && !this.editorMode
    }

    if (what === 'roblox-button') {
      return !userUtils.isCreatedViaLibrary() && !this.editorMode
    }

    if (what === 'hackstack') {
      return me.getHackStackExperimentValue() === 'beta' && !userUtils.isCreatedViaLibrary() && !this.editorMode
    }

    return true
  }
}

CampaignView.initClass()

module.exports = CampaignView
