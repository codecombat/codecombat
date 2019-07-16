require('app/styles/play/campaign-view.sass')
RootView = require 'views/core/RootView'
template = require 'templates/play/campaign-view'
LevelSession = require 'models/LevelSession'
EarnedAchievement = require 'models/EarnedAchievement'
CocoCollection = require 'collections/CocoCollection'
Achievements = require 'collections/Achievements'
Campaign = require 'models/Campaign'
AudioPlayer = require 'lib/AudioPlayer'
LevelSetupManager = require 'lib/LevelSetupManager'
ThangType = require 'models/ThangType'
MusicPlayer = require 'lib/surface/MusicPlayer'
storage = require 'core/storage'
CreateAccountModal = require 'views/core/CreateAccountModal'
SubscribeModal = require 'views/core/SubscribeModal'
LeaderboardModal = require 'views/play/modal/LeaderboardModal'
Level = require 'models/Level'
utils = require 'core/utils'
require 'three'
ParticleMan = require 'core/ParticleMan'
ShareProgressModal = require 'views/play/modal/ShareProgressModal'
UserPollsRecord = require 'models/UserPollsRecord'
Poll = require 'models/Poll'
PollModal = require 'views/play/modal/PollModal'
CourseInstance = require 'models/CourseInstance'
AnnouncementModal = require 'views/play/modal/AnnouncementModal'
codePlay = require('lib/code-play')
MineModal = require 'views/core/MineModal' # Minecraft modal
CodePlayCreateAccountModal = require 'views/play/modal/CodePlayCreateAccountModal'
api = require 'core/api'
Classroom = require 'models/Classroom'
Course = require 'models/Course'
CourseInstance = require 'models/CourseInstance'
Levels = require 'collections/Levels'
payPal = require('core/services/paypal')
createjs = require 'lib/createjs-parts'
PlayItemsModal = require 'views/play/modal/PlayItemsModal'
PlayHeroesModal = require 'views/play/modal/PlayHeroesModal'
PlayAchievementsModal = require 'views/play/modal/PlayAchievementsModal'
BuyGemsModal = require 'views/play/modal/BuyGemsModal'
ContactModal = require 'views/core/ContactModal'
AnonymousTeacherModal = require 'views/core/AnonymousTeacherModal'
AmazonHocModal = require 'views/play/modal/AmazonHocModal'
require('vendor/scripts/jquery-ui-1.11.1.custom')
require('vendor/styles/jquery-ui-1.11.1.custom.css')
fetchJson = require 'core/api/fetch-json'
HoCModal = require 'views/special_event/HoC2018InterstitialModal.coffee'
CourseVideosModal = require 'views/play/level/modal/CourseVideosModal'

require 'lib/game-libraries'

class LevelSessionsCollection extends CocoCollection
  url: ''
  model: LevelSession

  constructor: (model) ->
    super()
    @url = "/db/user/#{me.id}/level.sessions?project=state.complete,levelID,state.difficulty,playtime,state.topScores,codeLanguage,level"

class CampaignsCollection extends CocoCollection
  # We don't send all of levels, just the parts needed in countLevels
  url: '/db/campaign/-/overworld?project=slug,adjacentCampaigns,name,fullName,description,i18n,color,levels'
  model: Campaign

module.exports = class CampaignView extends RootView
  id: 'campaign-view'
  template: template

  getMeta: ->
    title: $.i18n.t 'play.title'
    meta: [
      { vmid: 'meta-description', name: 'description', content: $.i18n.t 'play.meta_description' }
    ]
    link: [
      { vmid: 'rel-canonical', rel: 'canonical', content: '/play' }
    ]

  subscriptions:
    'subscribe-modal:subscribed': 'onSubscribed'

  events:
    'click #amazon-campaign-logo': 'onClickAmazonCampaign'
    'click #anon-classroom-signup-close': 'onClickAnonClassroomClose'
    'click #anon-classroom-join-btn': 'onClickAnonClassroomJoin'
    'click #anon-classroom-signup-btn': 'onClickAnonClassroomSignup'
    'click .cube-level': 'onSpinningCubeClick' # Minecraft Modal
    'click .map-background': 'onClickMap'
    'click .level': 'onClickLevel'
    'dblclick .level': 'onDoubleClickLevel'
    'click .level-info-container .start-level': 'onClickStartLevel'
    'click .level-info-container .view-solutions': 'onClickViewSolutions'
    'click .level-info-container .course-version button': 'onClickCourseVersion'
    'click #volume-button': 'onToggleVolume'
    'click #back-button': 'onClickBack'
    'click #clear-storage-button': 'onClickClearStorage'
    'click .portal .campaign': 'onClickPortalCampaign'
    'click .portal .beta-campaign': 'onClickPortalCampaign'
    'click a .campaign-switch': 'onClickCampaignSwitch'
    'mouseenter .portals': 'onMouseEnterPortals'
    'mouseleave .portals': 'onMouseLeavePortals'
    'mousemove .portals': 'onMouseMovePortals'
    'click .poll': 'showPoll'
    'click #brain-pop-replay-btn': 'onClickBrainPopReplayButton'
    'click .premium-menu-icon': 'onClickPremiumButton'
    'click [data-toggle="coco-modal"][data-target="play/modal/PlayItemsModal"]': 'openPlayItemsModal'
    'click [data-toggle="coco-modal"][data-target="play/modal/PlayHeroesModal"]': 'openPlayHeroesModal'
    'click [data-toggle="coco-modal"][data-target="play/modal/PlayAchievementsModal"]': 'openPlayAchievementsModal'
    'click [data-toggle="coco-modal"][data-target="play/modal/BuyGemsModal"]': 'openBuyGemsModal'
    'click [data-toggle="coco-modal"][data-target="core/ContactModal"]': 'openContactModal'
    'click [data-toggle="coco-modal"][data-target="core/CreateAccountModal"]': 'openCreateAccountModal'
    'click [data-toggle="coco-modal"][data-target="core/AnonymousTeacherModal"]': 'openAnonymousTeacherModal'
    'click #videos-button': 'onClickVideosButton'

  shortcuts:
    'shift+s': 'onShiftS'

  constructor: (options, @terrain) ->
    super options
    @terrain = 'picoctf' if window.serverConfig.picoCTF
    @editorMode = options?.editorMode
    @requiresSubscription = not me.isPremium()
    # Allow only admins to view the ozaria campaign and only in editor mode
    # New page for non-editor mode `/play-ozaria`
    # Assuming, the ozaria placeholder campaigns will start with 'ozaria'
    # TODO: Remove/update this check before final ozaria launch
    if _.string.startsWith(@terrain, "ozaria") and (not me.showOzariaCampaign() or not @editorMode)
      console.error("ozaria dummy campaign, only editor mode is available for admins!")
      return
    if @editorMode
      @terrain ?= 'dungeon'
    @levelStatusMap = {}
    @levelPlayCountMap = {}
    @levelDifficultyMap = {}
    @levelScoreMap = {}

    if @terrain is "hoc-2018"
      $('body').append($("<img src='https://code.org/api/hour/begin_codecombat_play.png' style='visibility: hidden;'>"))

    if utils.getQueryVariable('hour_of_code')
      if me.isStudent() or me.isTeacher()
        if @terrain is 'dungeon'
          newCampaign = 'intro'
          api.users.getCourseInstances({ userID: me.id, campaignSlug: newCampaign }, { data: { project: '_id' } })
          .then (courseInstances) =>
            if courseInstances.length
              courseInstanceID = _.first(courseInstances)._id
              application.router.navigate("/play/#{newCampaign}?course-instance=#{courseInstanceID}", { trigger: true, replace: true })
            else
              application.router.navigate((if me.isStudent() then '/students' else '/teachers'), {trigger: true, replace: true})
              noty({text: 'Please create or join a classroom first', layout: 'topCenter', timeout: 8000, type: 'success'})
          return
      if @terrain is 'game-dev-hoc'
        window.tracker?.trackEvent 'Start HoC Campaign', label: 'game-dev-hoc'
      me.set('hourOfCode', true)
      me.patch()
      pixelCode = switch @terrain
        when 'game-dev-hoc' then 'code_combat_gamedev'
        when 'game-dev-hoc-2' then 'code_combat_build_arcade'
        else 'code_combat'
      $('body').append($("<img src='https://code.org/api/hour/begin_#{pixelCode}.png' style='visibility: hidden;'>"))
    else if me.isTeacher() and not utils.getQueryVariable('course-instance') and
        not application.getHocCampaign() and not @terrain is "hoc-2018"
      # redirect teachers away from home campaigns
      application.router.navigate('/teachers', { trigger: true, replace: true })
      return
    else if location.pathname is '/paypal/subscribe-callback'
      @payPalToken = utils.getQueryVariable('token')
      api.users.executeBillingAgreement({userID: me.id, token: @payPalToken})
      .then (billingAgreement) =>
        value = Math.round(parseFloat(billingAgreement?.plan?.payment_definitions?[0].amount?.value ? 0) * 100)
        application.tracker?.trackEvent 'Finished subscription purchase', { value, service: 'paypal' }
        noty({text: $.i18n.t('subscribe.confirmation'), layout: 'topCenter', timeout: 8000})
        me.fetch(cache: false, success: => @render?())
      .catch (err) =>
        console.error(err)

    if window.serverConfig.picoCTF
      @supermodel.addRequestResource(url: '/picoctf/problems', success: (@picoCTFProblems) =>).load()
    else
      unless @editorMode
        @sessions = @supermodel.loadCollection(new LevelSessionsCollection(), 'your_sessions', {cache: false}, 1).model
        @listenToOnce @sessions, 'sync', @onSessionsLoaded
      unless @terrain
        @campaigns = @supermodel.loadCollection(new CampaignsCollection(), 'campaigns', null, 1).model
        @listenToOnce @campaigns, 'sync', @onCampaignsLoaded
        return

    @campaign = new Campaign({_id:@terrain})
    @campaign = @supermodel.loadModel(@campaign).model

    # Temporary attempt to make sure all earned rewards are accounted for. Figure out a better solution...
    @earnedAchievements = new CocoCollection([], {url: '/db/earned_achievement', model:EarnedAchievement, project: ['earnedRewards']})
    @listenToOnce @earnedAchievements, 'sync', ->
      earned = me.get('earned')
      for m in @earnedAchievements.models
        continue unless loadedEarned = m.get('earnedRewards')
        for group in ['heroes', 'levels', 'items']
          continue unless loadedEarned[group]
          for reward in loadedEarned[group]
            if reward not in earned[group]
              console.warn 'Filling in a gap for reward', group, reward
              earned[group].push(reward)

    @supermodel.loadCollection(@earnedAchievements, 'achievements', {cache: false})

    if utils.getQueryVariable('course-instance')?
      @courseLevelsFake = {}
      @courseInstanceID = utils.getQueryVariable('course-instance')
      @courseInstance = new CourseInstance(_id: @courseInstanceID)
      jqxhr = @courseInstance.fetch()
      @supermodel.trackRequest(jqxhr)
      new Promise(jqxhr.then).then(=>
        courseID = @courseInstance.get('courseID')

        @course = new Course(_id: courseID)
        @supermodel.trackRequest @course.fetch()
        if @courseInstance.get('classroomID')
          classroomID = @courseInstance.get('classroomID')
          @classroom = new Classroom(_id: classroomID)
          @supermodel.trackRequest @classroom.fetch()
          @listenToOnce @classroom, 'sync', =>
            @updateClassroomSessions()
            @render()
            @courseInstance.sessions = new CocoCollection([], {
              url: @courseInstance.url() + '/course-level-sessions/' + me.id,
              model: LevelSession
            })
            @supermodel.loadCollection(@courseInstance.sessions, {
              data: { project: 'state.complete,level.original,playtime,changed,state.topScores' }
            })
            @courseInstance.sessions.comparator = 'changed'
            @listenToOnce @courseInstance.sessions, 'sync', =>
              @courseStats = @classroom.statsForSessions(@courseInstance.sessions, @course.id)
              @render()
            @courseLevels = new Levels()
            @supermodel.trackRequest @courseLevels.fetchForClassroomAndCourse(classroomID, courseID, {
              data: { project: 'concepts,practice,assessment,primerLanguage,type,slug,name,original,description,shareable,i18n' }
            })
            @listenToOnce @courseLevels, 'sync', =>
              existing = @campaign.get('levels')
              courseLevels = @courseLevels.toArray()
              classroomCourse = _.find(currentView.classroom.get('courses'), {_id:currentView.course.id})
              levelPositions = {}
              for level in classroomCourse.levels
                levelPositions[level.original] = level.position if level.position
              for k,v of courseLevels
                idx = v.get('original')
                if not existing[idx]
                  # a level which has been removed from the campaign but is saved in the course
                  @courseLevelsFake[idx] = v.toJSON()
                else
                  @courseLevelsFake[idx] = existing[idx]
                  # carry over positions stored in course, if there are any
                  if levelPositions[idx]
                    @courseLevelsFake[idx].position = levelPositions[idx]
                @courseLevelsFake[idx].courseIdx = parseInt(k)
                @courseLevelsFake[idx].requiresSubscription = false
              # Fill in missing positions, for courses which have levels that no longer exist in campaigns
              for k,v of courseLevels
                k = parseInt(k)
                idx = v.get('original')
                if not @courseLevelsFake[idx].position
                  prevLevel = courseLevels[k-1]
                  nextLevel = courseLevels[k+1]
                  if prevLevel && nextLevel
                    prevIdx = prevLevel.get('original')
                    nextIdx = nextLevel.get('original')
                    prevPosition = @courseLevelsFake[prevIdx].position
                    nextPosition = @courseLevelsFake[nextIdx].position
                  if prevPosition && nextPosition
                    # split the diff between the previous, next levels
                    @courseLevelsFake[idx].position = {
                      x: (prevPosition.x + nextPosition.x)/2
                      y: (prevPosition.y + nextPosition.y)/2
                    }
                  else
                    # otherwise just line them up along the bottom
                    x = 10 + (k / courseLevels.length) * 80
                    @courseLevelsFake[idx].position = { x, y: 10 }
              @render()
      )

    @listenToOnce @campaign, 'sync', @getLevelPlayCounts
    $(window).on 'resize', @onWindowResize
    @probablyCachedMusic = storage.load("loaded-menu-music")
    musicDelay = if @probablyCachedMusic then 1000 else 10000
    delayMusicStart = => _.delay (=> @playMusic() unless @destroyed), musicDelay
    @playMusicTimeout = delayMusicStart()
    @hadEverChosenHero = me.get('heroConfig')?.thangType
    @listenTo me, 'change:purchased', -> @renderSelectors('#gems-count')
    @listenTo me, 'change:spent', -> @renderSelectors('#gems-count')
    @listenTo me, 'change:earned', -> @renderSelectors('#gems-count')
    @listenTo me, 'change:heroConfig', -> @updateHero()

    if utils.getQueryVariable('hour_of_code') or @terrain is "hoc-2018"
      if not sessionStorage.getItem(@terrain)
        sessionStorage.setItem(@terrain, "seen-modal")
        clearTimeout(@playMusicTimeout)
        setTimeout(=>
            @openModalView new HoCModal({
              showVideo: @terrain is "hoc-2018",
              onDestroy: delayMusicStart,
            })
        , 0)

    window.tracker?.trackEvent 'Loaded World Map', category: 'World Map', label: @terrain

  destroy: ->
    @setupManager?.destroy()
    @$el.find('.ui-draggable').off().draggable 'destroy'
    $(window).off 'resize', @onWindowResize
    if ambientSound = @ambientSound
      # Doesn't seem to work; stops immediately.
      createjs.Tween.get(ambientSound).to({volume: 0.0}, 1500).call -> ambientSound.stop()
    @musicPlayer?.destroy()
    clearTimeout @playMusicTimeout
    @particleMan?.destroy()
    clearInterval @portalScrollInterval
    super()

  showLoading: ($el) ->
    unless @campaign
      @$el.find('.game-controls, .user-status').addClass 'hidden'
      @$el.find('.portal .campaign-name span').text $.i18n.t 'common.loading'

  hideLoading: ->
    unless @campaign
      @$el.find('.game-controls, .user-status').removeClass 'hidden'

  openPlayItemsModal: (e) ->
    e.stopPropagation()
    @openModalView new PlayItemsModal()

  openPlayHeroesModal: (e) ->
    e.stopPropagation()
    @openModalView new PlayHeroesModal()

  openPlayAchievementsModal: (e) ->
    e.stopPropagation()
    @openModalView new PlayAchievementsModal()

  openBuyGemsModal: (e) ->
    e.stopPropagation()
    @openModalView new BuyGemsModal()

  openContactModal: (e) ->
    e.stopPropagation()
    @openModalView new ContactModal()

  openCreateAccountModal: (e) ->
    e.stopPropagation()
    @openModalView new CreateAccountModal()

  openAnonymousTeacherModal: (e) ->
    e.stopPropagation()
    @openModalView new AnonymousTeacherModal()
    @endHighlight()

  onClickAmazonCampaign: (e) ->
    window.tracker?.trackEvent 'Click Amazon Modal Button'
    @openModalView new AmazonHocModal hideCongratulation: true

  onClickAnonClassroomClose: -> @$el.find('#anonymous-classroom-signup-dialog')?.hide()

  onClickAnonClassroomJoin: ->
    classCode = @$el.find('#anon-classroom-signup-code')?.val()
    return if _.isEmpty(classCode)
    window.tracker?.trackEvent 'Anonymous Classroom Signup Modal Join Class', category: 'Signup', classCode
    application.router.navigate("/students?_cc=#{classCode}", { trigger: true })

  onClickAnonClassroomSignup: ->
    window.tracker?.trackEvent 'Anonymous Classroom Signup Modal Create Teacher', category: 'Signup'
    @openModalView(new CreateAccountModal({startOnPath: 'teacher'}))

  onClickVideosButton: ->
    @openModalView(new CourseVideosModal({courseInstanceID: @courseInstanceID, courseID: @course.get('_id')}))

  getLevelPlayCounts: ->
    return unless me.isAdmin()
    return  # TODO: get rid of all this? It's redundant with new campaign editor analytics, unless we want to show player counts on leaderboards buttons.
    success = (levelPlayCounts) =>
      return if @destroyed
      for level in levelPlayCounts
        @levelPlayCountMap[level._id] = playtime: level.playtime, sessions: level.sessions
      @render() if @fullyRendered

    levelSlugs = (level.slug for levelID, level of @getLevels())
    levelPlayCountsRequest = @supermodel.addRequestResource 'play_counts', {
      url: '/db/level/-/play_counts'
      data: {ids: levelSlugs}
      method: 'POST'
      success: success
    }, 0
    levelPlayCountsRequest.load()

  onLoaded: ->
    if @isClassroom()
      @updateClassroomSessions()
    else
      unless @editorMode
        for session in @sessions.models
          unless @levelStatusMap[session.get('levelID')] is 'complete'  # Don't overwrite a complete session with an incomplete one
            @levelStatusMap[session.get('levelID')] = if session.get('state')?.complete then 'complete' else 'started'
          @levelDifficultyMap[session.get('levelID')] = session.get('state').difficulty if session.get('state')?.difficulty

    @buildLevelScoreMap() unless @editorMode
    # HoC: Fake us up a "mode" for HeroVictoryModal to return hero without levels realizing they're in a copycat campaign, or clear it if we started playing.
    application.setHocCampaign(if @campaign?.get('type') is 'hoc' then @campaign.get('slug') else '')

    return if @fullyRendered
    @fullyRendered = true
    @render()
    @checkForUnearnedAchievements()
    @preloadTopHeroes() unless me.get('heroConfig')?.thangType
    @$el.find('#campaign-status').delay(4000).animate({top: "-=58"}, 1000) if @terrain in ['forest', 'desert']
    if @campaign and @isRTL utils.i18n(@campaign.attributes, 'fullName')
      @$('.campaign-name').attr('dir', 'rtl')
    if not me.get('hourOfCode') and @terrain
      if features.codePlay
        if me.get('anonymous') and me.get('lastLevel') is 'true-names' and me.level() < 5
          @openModalView new CodePlayCreateAccountModal()
      else if me.get('name') and me.get('lastLevel') in ['forgetful-gemsmith', 'signs-and-portents', 'true-names'] and
      me.level() < 5 and not (me.get('ageRange') in ['18-24', '25-34', '35-44', '45-100']) and
      not storage.load('sent-parent-email') and not me.isPremium()
        @openModalView new ShareProgressModal()
    else
      @maybeShowPendingAnnouncement()

    # Minecraft Modal:
    #@maybeShowMinecraftModal() # Disable for now


  updateClassroomSessions: ->
    if @classroom
      classroomLevels = @classroom.getLevels()
      @classroomLevelMap = _.zipObject(classroomLevels.map((l) -> l.get('original')), classroomLevels.models)
      defaultLanguage = @classroom.get('aceConfig').language
      for session in @sessions.slice()
        classroomLevel = @classroomLevelMap[session.get('level').original]
        if not classroomLevel
          continue
        expectedLanguage = classroomLevel.get('primerLanguage') or defaultLanguage
        if session.get('codeLanguage') isnt expectedLanguage
          # console.log("Inside remove session")
          @sessions.remove(session)
          continue
      unless @editorMode
        for session in @sessions.models
          unless @levelStatusMap[session.get('levelID')] is 'complete'  # Don't overwrite a complete session with an incomplete one
            @levelStatusMap[session.get('levelID')] = if session.get('state')?.complete then 'complete' else 'started'
          @levelDifficultyMap[session.get('levelID')] = session.get('state').difficulty if session.get('state')?.difficulty
        if @courseInstance.get('classroomID') == "5d12e7e36eea5a00ac71dc8f"  # Tarena national final classroom
          unless @levelStatusMap['game-dev-2-final-project']  #make sure all players could access GD2 final on competition day
            @levelStatusMap['game-dev-2-final-project'] = 'started'

  buildLevelScoreMap: ->
    for session in @sessions.models
      levels = @getLevels()
      return unless levels
      levelOriginal = session.get('level')?.original
      continue unless levelOriginal
      level = levels[levelOriginal]
      topScore = _.first(LevelSession.getTopScores({session: session.toJSON(), level}))
      @levelScoreMap[levelOriginal] = topScore

  # Minecraft Modal:
  maybeShowMinecraftModal: ->
    return false if me.freeOnly()
    userQualifiesForMinecraftModal = (user) ->
      return true if user.isAdmin()
      return false if user.isPremium()
      return false if user.isAnonymous()
      return user.get('testGroupNumber') % 5 is 1

    return unless userQualifiesForMinecraftModal(me)
    if @campaign and @campaign.get('levels')
      levels = @campaign.get('levels')
      level = _.find(levels, {slug: "the-second-kithmaze"})
      if level and @levelStatusMap['the-second-kithmaze'] is 'complete' and /^en/i.test(me.get('preferredLanguage', true))
        $(".cube-level").show()

  # Minecraft Modal:
  onSpinningCubeClick: (e) ->
    window.tracker?.trackEvent "Mine Explored", engageAction: "campaign_level_click"
    @openModalView new MineModal()

  setCampaign: (@campaign) ->
    @render()

  onSubscribed: ->
    @requiresSubscription = false
    @render()

  getRenderData: (context={}) ->
    context = super(context)
    context.campaign = @campaign
    context.levels = _.values($.extend true, {}, @getLevels() ? {})
    if me.level() < 12 and @terrain is 'dungeon' and not @editorMode
      reject = if me.getFourthLevelGroup() is 'signs-and-portents' then 'forgetful-gemsmith' else 'signs-and-portents'
      context.levels = _.reject context.levels, slug: reject
    if me.freeOnly()
      context.levels = _.reject context.levels, (level) ->
        return false if features.codePlay and codePlay.canPlay(level.slug)
        return level.requiresSubscription
    if features.brainPop
      context.levels = _.filter context.levels, (level) ->
        level.slug in ['dungeons-of-kithgard', 'gems-in-the-deep', 'shadow-guard', 'true-names']
    @annotateLevels(context.levels)
    count = @countLevels context.levels
    if @courseStats?
      context.levelsCompleted = @courseStats.levels.numDone
      context.levelsTotal = @courseStats.levels.size
    else
      context.levelsCompleted = count.completed
      context.levelsTotal = count.total

    @determineNextLevel context.levels if @sessions?.loaded or @editorMode
    # put lower levels in last, so in the world map they layer over one another properly.
    context.levels = (_.sortBy context.levels, (l) -> l.position.y).reverse()
    @campaign.renderedLevels = context.levels if @campaign

    context.levelStatusMap = @levelStatusMap
    context.levelDifficultyMap = @levelDifficultyMap
    context.levelPlayCountMap = @levelPlayCountMap
    context.isIPadApp = application.isIPadApp
    context.picoCTF = window.serverConfig.picoCTF
    context.requiresSubscription = @requiresSubscription
    context.editorMode = @editorMode
    context.adjacentCampaigns = _.filter _.values(_.cloneDeep(@campaign?.get('adjacentCampaigns') or {})), (ac) =>
      return false if me.isStudent() or me.isTeacher()
      if ac.showIfUnlocked and not @editorMode
        return false if _.isString(ac.showIfUnlocked) and ac.showIfUnlocked not in me.levels()
        return false if _.isArray(ac.showIfUnlocked) and _.intersection(ac.showIfUnlocked, me.levels()).length <= 0
      ac.name = utils.i18n ac, 'name'
      styles = []
      styles.push "color: #{ac.color}" if ac.color
      styles.push "transform: rotate(#{ac.rotation}deg)" if ac.rotation
      ac.position ?= { x: 10, y: 10 }
      styles.push "left: #{ac.position.x}%"
      styles.push "top: #{ac.position.y}%"
      ac.style = styles.join('; ')
      return true
    context.marked = marked
    context.i18n = utils.i18n

    if @campaigns
      context.campaigns = {}
      for campaign in @campaigns.models when campaign.get('slug') isnt 'auditions'
        context.campaigns[campaign.get('slug')] = campaign
        if @sessions?.loaded
          levels = _.values($.extend true, {}, campaign.get('levels') ? {})
          if me.level() < 12 and campaign.get('slug') is 'dungeon' and not @editorMode
            reject = if me.getFourthLevelGroup() is 'signs-and-portents' then 'forgetful-gemsmith' else 'signs-and-portents'
            levels = _.reject levels, slug: reject
          if me.freeOnly()
            levels = _.reject levels, (level) ->
              return false if features.codePlay and codePlay.canPlay(level.slug)
              return level.requiresSubscription
          count = @countLevels levels
          campaign.levelsTotal = count.total
          campaign.levelsCompleted = count.completed
          if campaign.get('slug') is 'dungeon'
            campaign.locked = false
          else unless campaign.levelsTotal
            campaign.locked = true
          else
            campaign.locked = true
      for campaign in @campaigns.models
        for acID, ac of campaign.get('adjacentCampaigns') ? {}
          if _.isString(ac.showIfUnlocked)
            _.find(@campaigns.models, id: acID)?.locked = false if ac.showIfUnlocked in me.levels()
          else if _.isArray(ac.showIfUnlocked)
            _.find(@campaigns.models, id: acID)?.locked = false if _.intersection(ac.showIfUnlocked, me.levels()).length > 0

    if @terrain and _.string.contains(@terrain, 'hoc') and me.isTeacher()
      context.showGameDevAlert = true

    context

  afterRender: ->
    super()
    @onWindowResize()

    $('#anon-classroom-signup-code').keydown (event) ->
      if (event.keyCode == 13)
        # click join classroom button if enter is pressed in the text box
        $("#anon-classroom-join-btn").click()

    unless application.isIPadApp
      _.defer => @$el?.find('.game-controls .btn:not(.poll)').addClass('has-tooltip').tooltip()  # Have to defer or i18n doesn't take effect.
      view = @
      @$el.find('.level, .campaign-switch').addClass('has-tooltip').tooltip().each ->
        return unless me.isAdmin() and view.editorMode
        $(@).draggable().on 'dragstop', ->
          bg = $('.map-background')
          x = ($(@).offset().left - bg.offset().left + $(@).outerWidth() / 2) / bg.width()
          y = 1 - ($(@).offset().top - bg.offset().top + $(@).outerHeight() / 2) / bg.height()
          e = { position: { x: (100 * x), y: (100 * y) }, levelOriginal: $(@).data('level-original'), campaignID: $(@).data('campaign-id') }
          view.trigger 'level-moved', e if e.levelOriginal
          view.trigger 'adjacent-campaign-moved', e if e.campaignID
    @updateVolume()
    @updateHero()
    unless window.currentModal or not @fullyRendered
      @highlightElement '.level.next', delay: 500, duration: 60000, rotation: 0, sides: ['top']
      @createLines() if @editorMode
      @showLeaderboard @options.justBeatLevel?.get('slug') if @options.showLeaderboard# or true  # Testing
    @applyCampaignStyles()
    @testParticles()

  onShiftS: (e) ->
    @generateCompletionRates() if @editorMode

  generateCompletionRates: ->
    return unless me.isAdmin()
    startDay = utils.getUTCDay -14
    endDay = utils.getUTCDay -1
    $(".map-background").css('background-image','none')
    $(".gradient").remove()
    $("#campaign-view").css("background-color", "black")
    for level in @campaign?.renderedLevels ? []
      $("div[data-level-slug=#{level.slug}] .level-kind").text("Loading...")
      request = @supermodel.addRequestResource 'level_completions', {
        url: '/db/analytics_perday/-/level_completions'
        data: {startDay: startDay, endDay: endDay, slug: level.slug}
        method: 'POST'
        success: @onLevelCompletionsLoaded.bind(@, level)
      }, 0
      request.load()

  onLevelCompletionsLoaded: (level, data) ->
    return if @destroyed
    started = 0
    finished = 0
    for day in data
      started += day.started ? 0
      finished += day.finished ? 0
    if started is 0
      ratio = 0
    else
      ratio = finished / started
    rateDisplay = (ratio * 100).toFixed(1) + '%'
    $("div[data-level-slug=#{level.slug}] .level-kind").html((if started < 1000 then started else (started / 1000).toFixed(1) + "k") + "<br>" + rateDisplay)
    if ratio <= 0.5
      color = "rgb(255, 0, 0)"
    else if ratio > 0.5 and ratio <= 0.85
      offset = (ratio - 0.5) / 0.35
      color = "rgb(255, #{Math.round(256 * offset)}, 0)"
    else if ratio > 0.85 and ratio <= 0.95
      offset = (ratio - 0.85) / 0.1
      color = "rgb(#{Math.round(256 * (1-offset))}, 256, 0)"
    else
      color = "rgb(0, 256, 0)"
    $("div[data-level-slug=#{level.slug}] .level-kind").css({"color":color, "width":256+"px", "transform":"translateX(-50%) translateX(15px)"})
    $("div[data-level-slug=#{level.slug}]").css("background-color", color)

  afterInsert: ->
    super()
    if utils.getQueryVariable('signup') and not me.get('email')
      return @promptForSignup()
    if not me.isPremium() and (@isPremiumCampaign() or (@options.worldComplete and not features.noAuth and not me.get('hourOfCode')))
      if not me.get('email')
        return @promptForSignup()
      campaignSlug = window.location.pathname.split('/')[2]
      return @promptForSubscription campaignSlug, 'premium campaign visited'

  promptForSignup: ->
    return if @terrain and 'hoc' in @terrain
    return if features.noAuth or @campaign?.get('type') is 'hoc'
    @endHighlight()
    @openModalView(new CreateAccountModal(supermodel: @supermodel))

  promptForSubscription: (slug, label) ->
    return console.log('Game dev HoC does not encourage subscribing.') if @campaign?.get('type') is 'hoc'
    @endHighlight()
    @openModalView new SubscribeModal()
    # TODO: Added levelID on 2/9/16. Remove level property and associated AnalyticsLogEvent 'properties.level' index later.
    window.tracker?.trackEvent 'Show subscription modal', category: 'Subscription', label: label, level: slug, levelID: slug

  isPremiumCampaign: (slug) ->
    slug ||= window.location.pathname.split('/')[2]
    return unless slug
    return false if 'hoc' in slug
    /campaign-(game|web)-dev-\d/.test slug

  showAds: ->
    return false # No ads for now.
    if application.isProduction() && !me.isPremium() && !me.isTeacher() && !window.serverConfig.picoCTF
      return me.getCampaignAdsGroup() is 'leaderboard-ads'
    false

  annotateLevels: (orderedLevels) ->
    return if @isClassroom()

    for level, levelIndex in orderedLevels
      level.position ?= { x: 10, y: 10 }
      level.locked = not me.ownsLevel(level.original)
      level.locked = true if level.slug is 'kithgard-mastery' and @calculateExperienceScore() is 0
      level.locked = true if level.requiresSubscription and @requiresSubscription and me.get('hourOfCode')
      level.locked = false if @levelStatusMap[level.slug] in ['started', 'complete']
      level.locked = false if @editorMode
      level.locked = false if @campaign?.get('name') in ['Auditions', 'Intro']
      level.locked = false if me.isInGodMode()
      level.disabled = true if level.adminOnly and @levelStatusMap[level.slug] not in ['started', 'complete']
      level.disabled = false if me.isInGodMode()

      level.color = 'rgb(255, 80, 60)'
      unless @isClassroom() or @campaign?.get('type') is 'hoc'
        level.color = 'rgb(80, 130, 200)' if level.requiresSubscription and not features.codePlay
        level.color = 'rgb(200, 80, 200)' if level.adventurer

      level.color = 'rgb(193, 193, 193)' if level.locked
      level.unlocksHero = _.find(level.rewards, 'hero')?.hero
      if level.unlocksHero
        level.purchasedHero = level.unlocksHero in (me.get('purchased')?.heroes or [])

      level.unlocksItem = _.find(level.rewards, 'item')?.item
      level.unlocksPet = utils.petThangIDs.indexOf(level.unlocksItem) isnt -1

      if @classroom?
        level.unlocksItem = false
        level.unlocksPet = false

      if window.serverConfig.picoCTF
        if problem = _.find(@picoCTFProblems or [], pid: level.picoCTFProblem)
          level.locked = false if problem.unlocked or level.slug is 'digital-graffiti'
          #level.locked = false  # Testing to see all levels
          level.description = """
            ### #{problem.name}
            #{level.description or problem.description}

            #{problem.category} - #{problem.score} points
          """
          level.color = 'rgb(80, 130, 200)' if problem.solved

      level.hidden = level.locked and @campaign?.get('type') isnt 'hoc'
      if level.concepts?.length
        level.displayConcepts = level.concepts
        maxConcepts = 6
        if level.displayConcepts.length > maxConcepts
          level.displayConcepts = level.displayConcepts.slice -maxConcepts

      level.unlockedInSameCampaign = levelIndex < 5  # First few are always counted (probably unlocked in previous campaign)
      for otherLevel in orderedLevels when not level.unlockedInSameCampaign and otherLevel isnt level
        for reward in (otherLevel.rewards ? []) when reward.level
          level.unlockedInSameCampaign ||= reward.level is level.original

  countLevels: (orderedLevels) ->
    count = total: 0, completed: 0

    if @campaign?.get('type') is 'hoc'
      # HoC: Just order left-to-right instead of looking at unlocks, which we don't use for this copycat campaign
      orderedLevels = _.sortBy orderedLevels, (level) -> level.position.x
      count.completed++ for level in orderedLevels when @levelStatusMap[level.slug] is 'complete'
      count.total = orderedLevels.length
      return count

    for level, levelIndex in orderedLevels
      @annotateLevels(orderedLevels) unless level.locked?  # Annotate if we haven't already.
      continue if level.disabled
      completed = @levelStatusMap[level.slug] is 'complete'
      started = @levelStatusMap[level.slug] is 'started'
      ++count.total if (level.unlockedInSameCampaign or not level.locked) and (started or completed or not (level.locked and level.practice and level.slug.substring(level.slug.length - 2) in ['-a', '-b', '-c', '-d']))
      ++count.completed if completed

    count

  showLeaderboard: (levelSlug) ->
    leaderboardModal = new LeaderboardModal supermodel: @supermodel, levelSlug: levelSlug
    @openModalView leaderboardModal

  isClassroom: -> @courseInstanceID?

  determineNextLevel: (orderedLevels) ->
    if @isClassroom()
      @applyCourseLogicToLevels(orderedLevels) if @courseStats?
      return true


    dontPointTo = ['lost-viking', 'kithgard-mastery']  # Challenge levels we don't want most players bashing heads against
    subscriptionPrompts = [{slug: 'boom-and-bust', unless: 'defense-of-plainswood'}]

    if @campaign?.get('type') is 'hoc'
      # HoC: Just order left-to-right instead of looking at unlocks, which we don't use for this copycat campaign
      orderedLevels = _.sortBy orderedLevels, (level) -> level.position.x
      for level in orderedLevels
        if @levelStatusMap[level.slug] isnt 'complete'
          level.next = true
          # Unlock and re-annotate this level
          # May not be unlocked/awarded due to different HoC progression using mostly shared levels
          level.locked = false
          level.hidden = level.locked
          level.disabled = false
          level.color = 'rgb(255, 80, 60)'
          return

    findNextLevel = (level, practiceOnly) =>
      for nextLevelOriginal in level.nextLevels
        nextLevel = _.find orderedLevels, original: nextLevelOriginal
        continue if not nextLevel or nextLevel.locked
        continue if practiceOnly and not @campaign.levelIsPractice(nextLevel)
        continue if @campaign.levelIsAssessment(nextLevel)
        continue if @campaign.levelIsAssessment(level) and @campaign.levelIsPractice(nextLevel)

        # If it's a challenge level, we efficiently determine whether we actually do want to point it out.
        if nextLevel.slug is 'kithgard-mastery' and not @levelStatusMap[nextLevel.slug] and @calculateExperienceScore() >= 3
          unless (timesPointedOut = storage.load("pointed-out-#{nextLevel.slug}") or 0) > 3
            # We may determineNextLevel more than once per render, so we can't just do this once. But we do give up after a couple highlights.
            dontPointTo = _.without dontPointTo, nextLevel.slug
            storage.save "pointed-out-#{nextLevel.slug}", timesPointedOut + 1

        # Should we point this level out?
        if not nextLevel.disabled and @levelStatusMap[nextLevel.slug] isnt 'complete' and nextLevel.slug not in dontPointTo and
        not nextLevel.replayable and (
          me.isPremium() or not nextLevel.requiresSubscription or nextLevel.adventurer or
          _.any(subscriptionPrompts, (prompt) => nextLevel.slug is prompt.slug and not @levelStatusMap[prompt.unless])
        )
          nextLevel.next = true
          return true
      false

    foundNext = false
    for level, levelIndex in orderedLevels
      # Iterate through all levels in order and look to find the first unlocked one that meets all our criteria for being pointed out as the next level.
      if @campaign.get('type') is 'course'
        level.nextLevels = []
        for nextLevel, nextLevelIndex in orderedLevels when nextLevelIndex > levelIndex
          continue if nextLevel.practice and level.nextLevels.length
          break if level.practice and not nextLevel.practice
          level.nextLevels.push nextLevel.original
          break unless nextLevel.practice
      else
        level.nextLevels = (reward.level for reward in level.rewards ? [] when reward.level)
      foundNext = findNextLevel(level, true) unless foundNext or @campaign.levelIsAssessment(level) # Check practice levels first
      foundNext = findNextLevel(level, false) unless foundNext

    if not foundNext and orderedLevels[0] and not orderedLevels[0].locked and @levelStatusMap[orderedLevels[0].slug] isnt 'complete'
      orderedLevels[0].next = true

  calculateExperienceScore: ->
    adultPoint = me.get('ageRange') in ['18-24', '25-34', '35-44', '45-100']  # They have to have answered the poll for this, likely after Shadow Guard.
    speedPoints = 0
    for [levelSlug, speedThreshold] in [['dungeons-of-kithgard', 50], ['gems-in-the-deep', 55], ['shadow-guard', 55], ['forgetful-gemsmith', 40], ['true-names', 40]]
      if _.find(@sessions?.models, (session) -> session.get('levelID') is levelSlug)?.attributes.playtime <= speedThreshold
        ++speedPoints
    experienceScore = adultPoint + speedPoints  # 0-6 score of how likely we think they are to be experienced and ready for Kithgard Mastery
    return experienceScore

  createLines: ->
    for level in @campaign?.renderedLevels ? []
      for nextLevelOriginal in level.nextLevels ? []
        if nextLevel = _.find(@campaign.renderedLevels, original: nextLevelOriginal)
          @createLine level.position, nextLevel.position

  createLine: (o1, o2) ->
    mapHeight = parseFloat($(".map").css("height"))
    mapWidth = parseFloat($(".map").css("width"))
    return unless mapHeight > 0
    ratio =  mapWidth / mapHeight
    p1 = x: o1.x, y: o1.y / ratio
    p2 = x: o2.x, y: o2.y / ratio
    length = Math.sqrt(Math.pow(p1.x - p2.x , 2) + Math.pow(p1.y - p2.y, 2))
    angle = Math.atan2(p1.y - p2.y, p2.x - p1.x) * 180 / Math.PI
    transform = "translateY(-50%) translateX(-50%) rotate(#{angle}deg) translateX(50%)"
    line = $('<div>').appendTo('.map').addClass('next-level-line').css(transform: transform, width: length + '%', left: o1.x + '%', bottom: (o1.y - 0.5) + '%')
    line.append($('<div class="line">')).append($('<div class="point">'))

  applyCampaignStyles: ->
    return unless @campaign?.loaded
    if (backgrounds = @campaign.get 'backgroundImage') and backgrounds.length
      backgrounds = _.sortBy backgrounds, 'width'
      backgrounds.reverse()
      rules = []
      for background, i in backgrounds
        rule = "#campaign-view .map-background { background-image: url(/file/#{background.image}); }"
        rule = "@media screen and (max-width: #{background.width}px) { #{rule} }" if i
        rules.push rule
      utils.injectCSS rules.join('\n')
    if backgroundColor = @campaign.get 'backgroundColor'
      backgroundColorTransparent = @campaign.get 'backgroundColorTransparent'
      @$el.css 'background-color', backgroundColor
      for pos in ['top', 'right', 'bottom', 'left']
        @$el.find(".#{pos}-gradient").css 'background-image', "linear-gradient(to #{pos}, #{backgroundColorTransparent} 0%, #{backgroundColor} 100%)"
    @playAmbientSound()

  testParticles: ->
    return unless @campaign?.loaded and $.browser.chrome  # Sometimes this breaks in non-Chrome browsers, according to A/B tests.
    return if @campaign.get('type') is 'hoc'
    @particleMan ?= new ParticleMan()
    @particleMan.removeEmitters()
    @particleMan.attach @$el.find('.map')
    for level in @campaign.renderedLevels ? {}
      continue if level.hidden and (@campaign.levelIsPractice(level) or @campaign.levelIsAssessment(level) or not level.unlockedInSameCampaign)
      terrain = @terrain.replace('-branching-test', '').replace(/(campaign-)?(game|web)-dev-\d/, 'forest').replace(/(intro|game-dev-hoc)/, 'dungeon')
      particleKey = ['level', terrain]
      particleKey.push level.type if level.type and not (level.type in ['hero', 'course'])  # Would use isType, but it's not a Level model
      particleKey.push 'replayable' if level.replayable
      particleKey.push 'premium' if level.requiresSubscription
      particleKey.push 'gate' if level.slug in ['kithgard-gates', 'siege-of-stonehold', 'clash-of-clones', 'summits-gate']
      particleKey.push 'hero' if level.unlocksHero and not level.unlockedHero
      #particleKey.push 'item' if level.slug is 'robot-ragnarok'  # TODO: generalize
      continue if particleKey.length is 2  # Don't show basic levels
      continue unless level.hidden or _.intersection(particleKey, ['item', 'hero-ladder', 'replayable']).length
      @particleMan.addEmitter level.position.x / 100, level.position.y / 100, particleKey.join('-')

  onMouseEnterPortals: (e) ->
    return unless @campaigns?.loaded and @sessions?.loaded
    @portalScrollInterval = setInterval @onMouseMovePortals, 100
    @onMouseMovePortals e

  onMouseLeavePortals: (e) ->
    return unless @portalScrollInterval
    clearInterval @portalScrollInterval
    @portalScrollInterval = null

  onMouseMovePortals: (e) =>
    return unless @portalScrollInterval
    $portal = @$el.find('.portal')
    $portals = @$el.find('.portals')
    if e
      @portalOffsetX = Math.round Math.max 0, e.clientX - $portal.offset().left
    bodyWidth = $('body').innerWidth()
    fraction = @portalOffsetX / bodyWidth
    return if 0.2 < fraction < 0.8
    direction = if fraction < 0.5 then 1 else -1
    magnitude = 0.2 * bodyWidth * (if direction is -1 then fraction - 0.8 else 0.2 - fraction) / 0.2
    portalsWidth = 2536  # TODO: if we add campaigns or change margins, this will get out of date...
    scrollTo = $portals.offset().left + direction * magnitude
    scrollTo = Math.max bodyWidth - portalsWidth, scrollTo
    scrollTo = Math.min 0, scrollTo
    $portals.stop().animate {marginLeft: scrollTo}, 100, 'linear'

  onSessionsLoaded: (e) ->
    return if @editorMode
    @render()
    @loadUserPollsRecord() unless me.get('anonymous') or me.inEU() or window.serverConfig.picoCTF

  onCampaignsLoaded: (e) ->
    @render()

  preloadLevel: (levelSlug) ->
    levelURL = "/db/level/#{levelSlug}"
    level = new Level().setURL levelURL
    level = @supermodel.loadModel(level, null, 0).model

    # Note that this doesn't just preload the level. For sessions which require the
    # campaign to be included, it also creates the session. If this code is changed,
    # make sure to accommodate campaigns with free-in-certain-campaign-contexts levels,
    # such as game dev levels in game-dev-hoc.
    sessionURL = "/db/level/#{levelSlug}/session?campaign=#{@campaign.id}"

    @preloadedSession = new LevelSession().setURL sessionURL
    @listenToOnce @preloadedSession, 'sync', @onSessionPreloaded
    @preloadedSession = @supermodel.loadModel(@preloadedSession, {cache: false}).model
    @preloadedSession.levelSlug = levelSlug

  onSessionPreloaded: (session) ->
    session.url = -> '/db/level.session/' + @id
    levelElement = @$el.find('.level-info-container:visible')
    return unless session.levelSlug is levelElement.data 'level-slug'
    return unless difficulty = session.get('state')?.difficulty
    badge = $("<span class='badge'>#{difficulty}</span>")
    levelElement.find('.start-level .badge').remove()
    levelElement.find('.start-level').append badge

  onClickMap: (e) ->
    @$levelInfo?.hide()
    if @sessions?.models.length < 3
      # Restore the next level higlight for very new players who might otherwise get lost.
      @highlightElement '.level.next', delay: 500, duration: 60000, rotation: 0, sides: ['top']

  onClickLevel: (e) ->
    e.preventDefault()
    e.stopPropagation()
    @$levelInfo?.hide()
    levelElement = $(e.target).parents('.level')
    levelSlug = levelElement.data('level-slug')
    return unless levelSlug # Minecraft Modal
    levelOriginal = levelElement.data('level-original')
    if @editorMode
      return @trigger 'level-clicked', levelOriginal
    @$levelInfo = @$el.find(".level-info-container[data-level-slug=#{levelSlug}]").show()
    @checkForCourseOption levelOriginal
    @adjustLevelInfoPosition e
    @endHighlight()
    @preloadLevel levelSlug

  onDoubleClickLevel: (e) ->
    return unless @editorMode
    levelElement = $(e.target).parents('.level')
    levelOriginal = levelElement.data('level-original')
    @trigger 'level-double-clicked', levelOriginal

  onClickStartLevel: (e) ->
    levelElement = $(e.target).parents('.level-info-container')
    levelSlug = levelElement.data('level-slug')
    levelOriginal = levelElement.data('level-original')
    level = _.find _.values(@getLevels()), slug: levelSlug

    requiresSubscription = level.requiresSubscription or (me.isOnPremiumServer() and not (level.slug in ['dungeons-of-kithgard', 'gems-in-the-deep', 'shadow-guard', 'forgetful-gemsmith', 'signs-and-portents', 'true-names']))
    canPlayAnyway = _.any([
      not @requiresSubscription
      level.adventurer
      @levelStatusMap[level.slug]
      (features.codePlay and codePlay.canPlay(level.slug))
      @campaign.get('type') is 'hoc'
    ])
    if requiresSubscription and not canPlayAnyway
      @promptForSubscription levelSlug, 'map level clicked'
    else
      @startLevel levelElement
      window.tracker?.trackEvent 'Clicked Start Level', category: 'World Map', levelID: levelSlug

  onClickCourseVersion: (e) ->
    levelElement = $(e.target).parents('.level-info-container')
    levelSlug = $(e.target).parents('.level-info-container').data 'level-slug'
    levelOriginal = levelElement.data('level-original')
    courseID = $(e.target).parents('.course-version').data 'course-id'
    courseInstanceID = $(e.target).parents('.course-version').data 'course-instance-id'

    classroomLevel = @classroomLevelMap?[levelOriginal]

    # If classroomItems is on, don't go to PlayLevelView directly.
    # Go through LevelSetupManager which will load required modals before going to PlayLevelView.
    if(me.showHeroAndInventoryModalsToStudents() and not classroomLevel?.isAssessment())
      @startLevel levelElement, courseID, courseInstanceID
      window.tracker?.trackEvent 'Clicked Start Level', category: 'World Map', levelID: levelSlug
    else
      url = "/play/level/#{levelSlug}?course=#{courseID}&course-instance=#{courseInstanceID}"
      Backbone.Mediator.publish 'router:navigate', route: url

  startLevel: (levelElement, courseID=null, courseInstanceID=null) ->
    @setupManager?.destroy()
    levelSlug = levelElement.data 'level-slug'
    levelOriginal = levelElement.data('level-original')
    classroomLevel = @classroomLevelMap?[levelOriginal]
    if(me.showHeroAndInventoryModalsToStudents() and not classroomLevel?.isAssessment())
      codeLanguage = @classroomLevelMap?[levelOriginal]?.get('primerLanguage') or @classroom?.get('aceConfig')?.language
      options = {supermodel: @supermodel, levelID: levelSlug, levelPath: levelElement.data('level-path'), levelName: levelElement.data('level-name'), hadEverChosenHero: @hadEverChosenHero, parent: @, courseID: courseID, courseInstanceID: courseInstanceID, codeLanguage: codeLanguage}
    else
      session = @preloadedSession if @preloadedSession?.loaded and @preloadedSession.levelSlug is levelSlug
      options = {supermodel: @supermodel, levelID: levelSlug, levelPath: levelElement.data('level-path'), levelName: levelElement.data('level-name'), hadEverChosenHero: @hadEverChosenHero, parent: @, session: session}
    @setupManager = new LevelSetupManager options
    unless @setupManager?.navigatingToPlay
      @$levelInfo?.find('.level-info, .progress').toggleClass('hide')
      @listenToOnce @setupManager, 'open', ->
        @$levelInfo?.find('.level-info, .progress').toggleClass('hide')
        @$levelInfo?.hide()
      @setupManager.open()

  onClickViewSolutions: (e) ->
    levelElement = $(e.target).parents('.level-info-container')
    levelSlug = levelElement.data('level-slug')
    level = _.find _.values(@getLevels()), slug: levelSlug
    if level.type in ['hero-ladder', 'course-ladder']  # Would use isType, but it's not a Level model
      Backbone.Mediator.publish 'router:navigate', route: "/play/ladder/#{levelSlug}", viewClass: 'views/ladder/LadderView', viewArgs: [{supermodel: @supermodel}, levelSlug]
    else
      @showLeaderboard levelSlug

  adjustLevelInfoPosition: (e) ->
    return unless @$levelInfo
    @$map ?= @$el.find('.map')
    mapOffset = @$map.offset()
    mapX = e.pageX - mapOffset.left
    mapY = e.pageY - mapOffset.top
    margin = 20
    width = @$levelInfo.outerWidth()
    @$levelInfo.css('left', Math.min(Math.max(margin, mapX - width / 2), @$map.width() - width - margin))
    height = @$levelInfo.outerHeight()
    top = mapY - @$levelInfo.outerHeight() - 60
    if top < 100
      top = mapY + 60
    @$levelInfo.css('top', top)

  onWindowResize: (e) =>
    mapHeight = iPadHeight = 1536
    mapWidth = {dungeon: 2350, forest: 2500, auditions: 2500, desert: 2411, mountain: 2422, glacier: 2421}[@terrain] or 2350
    aspectRatio = mapWidth / mapHeight
    pageWidth = @$el.width()
    pageHeight = @$el.height()
    pageHeight -= adContainerHeight if adContainerHeight = $('.ad-container').outerHeight()
    widthRatio = pageWidth / mapWidth
    heightRatio = pageHeight / mapHeight
    # Make sure we can see the whole map, fading to background in one dimension.
    if heightRatio <= widthRatio
      # Left and right margin
      resultingHeight = pageHeight
      resultingWidth = resultingHeight * aspectRatio
    else
      # Top and bottom margin
      resultingWidth = pageWidth
      resultingHeight = resultingWidth / aspectRatio
    resultingMarginX = (pageWidth - resultingWidth) / 2
    resultingMarginY = (pageHeight - resultingHeight) / 2
    @$el.find('.map').css(width: resultingWidth, height: resultingHeight, 'margin-left': resultingMarginX, 'margin-top': resultingMarginY)
    @testParticles() if @particleMan

  playAmbientSound: ->
    return unless me.get 'volume'
    return if @ambientSound
    return unless file = @campaign?.get('ambientSound')?[AudioPlayer.ext.substr 1]
    src = "/file/#{file}"
    unless AudioPlayer.getStatus(src)?.loaded
      AudioPlayer.preloadSound src
      Backbone.Mediator.subscribeOnce 'audio-player:loaded', @playAmbientSound, @
      return
    @ambientSound = createjs.Sound.play src, loop: -1, volume: 0.1
    createjs.Tween.get(@ambientSound).to({volume: 0.5}, 1000)

  playMusic: ->
    @musicPlayer = new MusicPlayer()
    musicFile = '/music/music-menu'
    Backbone.Mediator.publish 'music-player:play-music', play: true, file: musicFile
    storage.save("loaded-menu-music", true) unless @probablyCachedMusic

  checkForCourseOption: (levelOriginal) ->
    showButton = (courseInstance) =>
      @$el.find(".course-version[data-level-original='#{levelOriginal}']").removeClass('hidden').data('course-id': courseInstance.get('courseID'), 'course-instance-id': courseInstance.id)

    if @courseInstance?
      showButton @courseInstance
    else
      return unless me.get('courseInstances')?.length
      @courseOptionsChecked ?= {}
      return if @courseOptionsChecked[levelOriginal]
      @courseOptionsChecked[levelOriginal] = true
      courseInstances = new CocoCollection [], url: "/db/course_instance/-/find_by_level/#{levelOriginal}", model: CourseInstance
      courseInstances.comparator = (ci) -> return -(ci.get('members') ? []).length
      @supermodel.loadCollection courseInstances, 'course_instances'
      @listenToOnce courseInstances, 'sync', =>
        return if @destroyed
        return unless courseInstance = courseInstances.models[0]
        showButton courseInstance

  preloadTopHeroes: ->
    return if window.serverConfig.picoCTF
    for heroID in ['captain', 'knight']
      url = "/db/thang.type/#{ThangType.heroes[heroID]}/version"
      continue if @supermodel.getModel url
      fullHero = new ThangType()
      fullHero.setURL url
      @supermodel.loadModel fullHero

  updateVolume: (volume) ->
    volume ?= me.get('volume') ? 1.0
    classes = ['vol-off', 'vol-down', 'vol-up']
    button = $('#volume-button', @$el)
    button.toggleClass 'vol-off', volume <= 0.0
    button.toggleClass 'vol-down', 0.0 < volume < 1.0
    button.toggleClass 'vol-up', volume >= 1.0
    createjs.Sound.volume = if volume is 1 then 0.6 else volume  # Quieter for now until individual sound FX controls work again.
    if volume isnt me.get 'volume'
      me.set 'volume', volume
      me.patch()
      @playAmbientSound() if volume

  onToggleVolume: (e) ->
    button = $(e.target).closest('#volume-button')
    classes = ['vol-off', 'vol-down', 'vol-up']
    volumes = [0, 0.4, 1.0]
    for oldClass, i in classes
      if button.hasClass oldClass
        newI = (i + 1) % classes.length
        break
      else if i is classes.length - 1  # no oldClass
        newI = 2
    @updateVolume volumes[newI]

  onClickBack: (e) ->
    Backbone.Mediator.publish 'router:navigate',
      route: "/play"
      viewClass: CampaignView
      viewArgs: [{supermodel: @supermodel}]

  onClickClearStorage: (e) ->
    localStorage.clear()
    noty {
      text: 'Local storage cleared. Reload to view the original campaign.'
      layout: 'topCenter'
      timeout: 5000
      type: 'information'
    }

  updateHero: ->
    return unless hero = me.get('heroConfig')?.thangType
    for slug, original of ThangType.heroes when original is hero
      @$el.find('.player-hero-icon').removeClass().addClass('player-hero-icon ' + slug)
      return
    console.error "CampaignView hero update couldn't find hero slug for original:", hero

  onClickPortalCampaign: (e) ->
    campaign = $(e.target).closest('.campaign, .beta-campaign')
    return if campaign.is('.locked') or campaign.is('.silhouette')
    campaignSlug = campaign.data('campaign-slug')
    if @isPremiumCampaign(campaignSlug) and not me.isPremium()
      return @promptForSubscription campaignSlug, 'premium campaign clicked'
    Backbone.Mediator.publish 'router:navigate',
      route: "/play/#{campaignSlug}"
      viewClass: CampaignView
      viewArgs: [{supermodel: @supermodel}, campaignSlug]

  onClickCampaignSwitch: (e) ->
    campaignSlug = $(e.target).data('campaign-slug')
    console.log campaignSlug, @isPremiumCampaign campaignSlug
    if @isPremiumCampaign(campaignSlug) and not me.isPremium()
      e.preventDefault()
      e.stopImmediatePropagation()
      return @promptForSubscription campaignSlug, 'premium campaign switch clicked'

  loadUserPollsRecord: ->
    url = "/db/user.polls.record/-/user/#{me.id}"
    @userPollsRecord = new UserPollsRecord().setURL url
    onRecordSync = ->
      return if @destroyed
      @userPollsRecord.url = -> '/db/user.polls.record/' + @id
      lastVoted = new Date(@userPollsRecord.get('changed') or 0)
      interval = new Date() - lastVoted
      if interval > 22 * 60 * 60 * 1000  # Wait almost a day before showing the next poll
        @loadPoll()
      else
        console.log 'Poll will be ready in', (22 * 60 * 60 * 1000 - interval) / (60 * 60 * 1000), 'hours.'
    @listenToOnce @userPollsRecord, 'sync', onRecordSync
    @userPollsRecord = @supermodel.loadModel(@userPollsRecord, null, 0).model
    onRecordSync.call @ if @userPollsRecord.loaded

  loadPoll: ->
    url = "/db/poll/#{@userPollsRecord.id}/next"
    @poll = new Poll().setURL url
    onPollSync = ->
      return if @destroyed
      @poll.url = -> '/db/poll/' + @id
      _.delay (=> @activatePoll?()), 1000
    onPollError = (poll, response, request) ->
      if response.status is 404
        console.log 'There are no more polls left.'
      else
        console.error "Couldn't load poll:", response.status, response.statusText
      delete @poll
    @listenToOnce @poll, 'sync', onPollSync
    @listenToOnce @poll, 'error', onPollError
    @poll = @supermodel.loadModel(@poll, null, 0).model
    onPollSync.call @ if @poll.loaded

  activatePoll: ->
    pollTitle = utils.i18n @poll.attributes, 'name'
    $pollButton = @$el.find('button.poll').removeClass('hidden').addClass('highlighted').attr(title: pollTitle).addClass('has-tooltip').tooltip title: pollTitle
    if me.get('lastLevel') is 'shadow-guard'
      @showPoll()
    else
      $pollButton.tooltip 'show'

  showPoll: ->
    return false unless @shouldShow 'poll'
    pollModal = new PollModal supermodel: @supermodel, poll: @poll, userPollsRecord: @userPollsRecord
    @openModalView pollModal
    $pollButton = @$el.find 'button.poll'
    pollModal.on 'vote-updated', ->
      $pollButton.removeClass('highlighted').tooltip 'hide'

  onClickPremiumButton: (e) ->
    @openModalView new SubscribeModal()
    window.tracker?.trackEvent 'Show subscription modal', category: 'Subscription', label: 'campaignview premium button'

  getLoadTrackingTag: () ->
    @campaign?.get?('slug') or 'overworld'

  mergeWithPrerendered: (el) ->
    true

  checkForUnearnedAchievements: ->
    return unless @campaign and currentView.sessions

    # Another layer attempting to make sure users unlock levels properly.

    # Every time the user goes to the campaign view (after initial load),
    # load achievements for that campaign.
    # Look for any achievements where the related level is complete, but
    # the reward level is not earned.
    # Try to create EarnedAchievements for each such Achievement found.

    achievements = new Achievements()

    achievements.fetchForCampaign(
      @campaign.get('slug'),
      { data: { project: 'related,rewards,name' } })

    .done((achievements) =>
      return if @destroyed
      sessionsComplete = _(currentView.sessions.models)
        .filter (s) => s.get('levelID')
        .filter (s) => s.get('state') && s.get('state').complete
        .map (s) => [s.get('levelID'), s.id]
        .value()

      sessionsCompleteMap = _.zipObject(sessionsComplete)

      campaignLevels = @getLevels()

      levelsEarned = _(me.get('earned')?.levels)
        .filter (levelOriginal) => campaignLevels[levelOriginal]
        .map (levelOriginal) => campaignLevels[levelOriginal].slug
        .filter()
        .value()

      levelsEarnedMap = _.zipObject(
        levelsEarned,
        _.times(levelsEarned.length, -> true)
      )

      levelAchievements = _.filter(achievements,
        (a) -> a.rewards && a.rewards.levels && a.rewards.levels.length)

      for achievement in levelAchievements
        continue unless campaignLevels[achievement.related]
        relatedLevelSlug = campaignLevels[achievement.related].slug
        for levelOriginal in achievement.rewards.levels
          continue unless campaignLevels[levelOriginal]
          rewardLevelSlug = campaignLevels[levelOriginal].slug
          if sessionsCompleteMap[relatedLevelSlug] and not levelsEarnedMap[rewardLevelSlug]
            ea = new EarnedAchievement({
              achievement: achievement._id,
              triggeredBy: sessionsCompleteMap[relatedLevelSlug],
              collection: 'level.sessions'
            })
            ea.notyErrors = false
            ea.save()
            .error ->
              console.warn 'Achievement NOT complete:', achievement.name
    )

  maybeShowPendingAnnouncement: () ->
    return false if me.freeOnly() # TODO: handle announcements that can be shown to free only servers
    return false if @payPalToken
    return false if me.isStudent()
    return false if application.getHocCampaign()
    return false if me.get('hourOfCode')
    latest = window.serverConfig.latestAnnouncement
    myLatest = me.get('lastAnnouncementSeen')
    return unless typeof latest is 'number'
    accountHours = (new Date() - new Date(me.get("dateCreated"))) / (60 * 60 * 1000) # min*sec*ms
    return unless accountHours > 18
    if latest > myLatest or not myLatest?
      me.set('lastAnnouncementSeen', latest)
      me.save()
      window.tracker?.trackEvent 'Show announcement modal', label: latest + ''
      @openModalView new AnnouncementModal({announcementId: latest})

  onClickBrainPopReplayButton: ->
    api.users.resetProgress({userId: me.id}).then(=> document.location.reload())

  getLevels: () ->
    return @courseLevelsFake if @courseLevels?
    @campaign?.get('levels')

  applyCourseLogicToLevels: (orderedLevels) ->
    nextSlug = @courseStats.levels.next?.get('slug')
    nextSlug ?= @courseStats.levels.first?.get('slug')
    return unless nextSlug

    courseOrder = _.sortBy orderedLevels, 'courseIdx'
    found = false
    prev = null
    lastNormalLevel = null
    for level, levelIndex in courseOrder
      playerState = @levelStatusMap[level.slug]
      level.color = 'rgb(255, 80, 60)'
      level.disabled = false

      if level.slug is nextSlug
        level.locked = false
        level.hidden = false
        level.next = true
        found = true
      else if playerState in ['started', 'complete']
        level.hidden = false
        level.locked = false
      else
        if level.practice
          if prev?.next
            level.hidden = !prev?.practice
            level.locked = true
          else if prev
            level.hidden = prev.hidden
            level.locked = prev.locked
          else
            level.hidden = true
            level.locked = true
        else if level.assessment
          level.hidden = false
          level.locked = @levelStatusMap[lastNormalLevel?.slug] isnt 'complete'
        else
          level.locked = found
          level.hidden = false

      level.noFlag = !level.next
      if level.locked
        level.color = 'rgb(193, 193, 193)'
      else if level.practice
        level.color = 'rgb(45, 145, 81)'
      else if level.assessment
        level.color = '#AD62F8'
        if playerState isnt 'complete'
          level.noFlag = false
      level.unlocksHero = false
      level.unlocksItem = false
      prev = level
      if not @campaign.levelIsPractice(level) and not @campaign.levelIsAssessment(level)
        lastNormalLevel = level
    return true

  shouldShow: (what) ->
    isStudentOrTeacher = me.isStudent() or me.isTeacher()
    isIOS = me.get('iosIdentifierForVendor') || application.isIPadApp

    if what is 'classroom-level-play-button'
      isValidStudent = (me.isStudent() and me.get('courseInstances')?.length)
      isValidTeacher = me.isTeacher()
      return (isValidStudent or isValidTeacher) and not application.getHocCampaign()

    if features.codePlay and what in ['clans', 'settings']
      return false

    if features.noAuth and what is 'status-line'
      return false

    if what is 'codeplay-ads'
      return !me.finishedAnyLevels() && serverConfig.showCodePlayAds && !features.noAds && me.get('role') isnt 'student'

    if what in ['status-line']
      return me.showGemsAndXp() or !isStudentOrTeacher

    if what in ['gems']
      return me.showGemsAndXp() or !isStudentOrTeacher

    if what in ['level', 'xp']
      return me.showGemsAndXp() or !isStudentOrTeacher

    if what in ['settings', 'leaderboard', 'back-to-campaigns', 'poll', 'items', 'heros', 'achievements', 'clans', 'poll']
      return !isStudentOrTeacher

    if what in ['back-to-classroom']
      return isStudentOrTeacher and not application.getHocCampaign()

    if what in ['videos']
      return me.isStudent() and @course?.get('_id') == utils.courseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE

    if what in ['buy-gems']
      return not (isIOS or me.freeOnly() or isStudentOrTeacher or !me.canBuyGems() or (application.getHocCampaign() and me.isAnonymous()))

    if what in ['premium']
      return not (me.isPremium() or isIOS or me.freeOnly() or isStudentOrTeacher or (application.getHocCampaign() and me.isAnonymous()))

    if what is 'anonymous-classroom-signup'
      return me.isAnonymous() and me.level() < 8 and me.promptForClassroomSignup()

    if what is 'amazon-campaign'
      return @campaign?.get('slug') is 'game-dev-hoc'

    return true
