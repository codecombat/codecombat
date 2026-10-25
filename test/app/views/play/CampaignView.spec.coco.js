/* eslint-env jasmine */
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const factories = require('test/app/factories')
const CampaignView = require('views/play/CampaignView')
const Levels = require('collections/Levels')
const ThangType = require('models/ThangType')
const Level = require('models/Level')
const LevelSession = require('models/LevelSession')
const globalVar = require('core/globalVar')
const storage = require('core/storage')
const utils = require('core/utils')
const editorLevelCardTemplate = require('templates/play/campaign-editor-level-card')

describe('CampaignView', () => describe('when 4 earned levels', function () {
  beforeEach(function () {
    let level
    this.campaignView = new CampaignView()
    this.campaignView.levelStatusMap = {}
    const levels = new Levels(_.times(4, () => factories.makeLevel()))
    this.campaignView.campaign = factories.makeCampaign({}, { levels })
    this.levels = ((() => {
      const result = []
      for (level of Array.from(levels.models)) {
        result.push(level.toJSON())
      }
      return result
    })())
    const earned = me.get('earned') || {}
    if (earned.levels == null) { earned.levels = [] }
    for (level of Array.from(this.levels)) { earned.levels.push(level.original) }
    return me.set('earned', earned)
  })

  describe('and 3rd one is practice in classroom only', function () {
    beforeEach(function () {
      // Not named "Level Name [ABCD]", so not actually a practice level in home version.
      this.levels[2].practice = true
      return this.campaignView.annotateLevels(this.levels)
    })
    return it('does not hide the not-really-practice level', function () {
      expect(this.levels[2].hidden).toEqual(false)
      return expect(this.levels[3].hidden).toEqual(false)
    })
  })

  describe('and 2nd rewards a practice a non-practice level', function () {
    beforeEach(function () {
      this.campaignView.levelStatusMap[this.levels[0].slug] = 'complete'
      this.campaignView.levelStatusMap[this.levels[1].slug] = 'complete'
      this.levels[1].rewards = [{ level: this.levels[2].original }, { level: this.levels[3].original }]
      this.levels[2].practice = true
      this.levels[2].name += ' A'
      this.levels[2].slug += '-a'
      this.campaignView.annotateLevels(this.levels)
      return this.campaignView.determineNextLevel(this.levels)
    })
    return it('points at practice level first', function () {
      expect(this.levels[2].next).toEqual(true)
      return expect(this.levels[3].next).not.toBeDefined(true)
    })
  })

  describe('applyCourseLogicToLevels', function () {
    beforeEach(function () {
      this.campaignView = new CampaignView()
      this.campaignView.courseStats = {
        levels: { first: { get (slug) { return 'levelX' } } },
      }
      this.campaignView.classroom = jasmine.createSpyObj('classroom', ['isStudentOnLockedLevel', 'isStudentOnOptionalLevel'])
      this.campaignView.classroom.isStudentOnLockedLevel.and.callFake((id, courseId, original) => original.match(/locked/i))
      this.campaignView.classroom.isStudentOnOptionalLevel.and.callFake((id, courseId, original) => original.match(/optional/i))
      this.campaignView.courseInstance = { get (startLockedLevel) { return undefined } }
      this.campaignView.course = { get (slug) { return 'course1' } }
      this.campaignView.campaign = {
        levelIsPractice (level) { return Boolean(level.practice) },
        levelIsAssessment (level) { return Boolean(level.assessment) },
      }
    })

    it('should apply locked flag on locked level', function () {
      const orderedLevels = [
        { slug: 'level1', original: 'level1' },
        { slug: 'level2', original: 'level2' },
        { slug: 'level3Locked', original: 'level3Locked' },
      ]

      this.campaignView.applyCourseLogicToLevels(orderedLevels)

      expect(orderedLevels[0].locked).toBe(false)
      expect(orderedLevels[1].locked).toBe(false)
      return expect(orderedLevels[2].locked).toBe(true)
    })

    it('should apply locked flag on all levels after a locked one', function () {
      const orderedLevels = [
        { slug: 'level1', original: 'level1' },
        { slug: 'level2', original: 'level2' },
        { slug: 'level3Locked', original: 'level3Locked' },
        { slug: 'level4', original: 'level4' },
        { slug: 'level5', original: 'level5' },
      ]

      this.campaignView.applyCourseLogicToLevels(orderedLevels)

      expect(orderedLevels[0].locked).toBe(false)
      expect(orderedLevels[1].locked).toBe(false)
      expect(orderedLevels[2].locked).toBe(true)
      expect(orderedLevels[3].locked).toBe(true)
      return expect(orderedLevels[4].locked).toBe(true)
    })

    it('should not apply locked flag on all levels after a skipped one', function () {
      const orderedLevels = [
        { slug: 'level1', original: 'level1' },
        { slug: 'level2', original: 'level2' },
        { slug: 'level3LockedOptional', original: 'level3LockedOptional' },
        { slug: 'level4', original: 'level4' },
        { slug: 'level5', original: 'level5' },
      ]

      this.campaignView.applyCourseLogicToLevels(orderedLevels)

      expect(orderedLevels[0].locked).toBe(false)
      expect(orderedLevels[1].locked).toBe(false)
      expect(orderedLevels[2].locked).toBe(true)
      expect(orderedLevels[3].locked).toBe(false)
      return expect(orderedLevels[4].locked).toBe(false)
    })

    it('should be all unlocked if all are optional', function () {
      this.campaignView.courseStats = {
        levels: { first: { get (slug) { return 'level1Optional' } } },
      }
      const orderedLevels = [
        { slug: 'level1Optional', original: 'level1Optional' },
        { slug: 'level2Optional', original: 'level2Optional' },
        { slug: 'level3Optional', original: 'level3Optional' },
        { slug: 'level4Optional', original: 'level4Optional' },
        { slug: 'level5Optional', original: 'level5Optional' },
      ]

      this.campaignView.applyCourseLogicToLevels(orderedLevels)

      expect(orderedLevels.map(l => l.locked)).toEqual([false, false, false, false, false])
    })

    it('optional levels should be still locked if there was a locked one before them', function () {
      this.campaignView.courseStats = {
        levels: { first: { get (slug) { return 'level1Optional' } } },
      }
      const orderedLevels = [
        { slug: 'level1Optional', original: 'level1Optional' },
        { slug: 'level2Locked', original: 'level2Locked' },
        { slug: 'level3Optional', original: 'level3Optional' },
        { slug: 'level4Optional', original: 'level4Optional' },
        { slug: 'level5Optional', original: 'level5Optional' },
      ]

      this.campaignView.applyCourseLogicToLevels(orderedLevels)

      expect(orderedLevels.map(l => l.locked)).toEqual([false, true, true, true, true])
    })

    it('optional levels should be still locked if there were some incomplete ones before', function () {
      this.campaignView.courseStats = {
        levels: { first: { get (slug) { return 'level1' } } },
      }
      const orderedLevels = [
        { slug: 'level1', original: 'level1' },
        { slug: 'level2', original: 'level2' },
        { slug: 'level2.1', original: 'level2.1', practice: true },
        { slug: 'level2.2', original: 'level2.2', practice: true },
        { slug: 'level3Optional', original: 'level3Optional', assessment: true },
        { slug: 'level4Optional', original: 'level4Optional' },
        { slug: 'level5Optional', original: 'level5Optional' },
      ]

      this.campaignView.applyCourseLogicToLevels(orderedLevels)

      expect(orderedLevels.map(l => l.locked)).toEqual([false, true, true, true, true, true, true])
    })
  })

  describe('shouldShow hackstack-menu-icon', function () {
    beforeEach(function () {
      this.campaignView = new CampaignView()
    })

    it('hides the icon for students', function () {
      const originalIsStudent = me.isStudent
      me.isStudent = () => true
      try {
        expect(this.campaignView.shouldShow('hackstack-menu-icon')).toBe(false)
      } finally {
        me.isStudent = originalIsStudent
      }
    })

    it('hides the icon for teachers', function () {
      const originalIsTeacher = me.isTeacher
      me.isTeacher = () => true
      try {
        expect(this.campaignView.shouldShow('hackstack-menu-icon')).toBe(false)
      } finally {
        me.isTeacher = originalIsTeacher
      }
    })

    it('shows the icon for non-students and non-teachers', function () {
      const originalIsStudent = me.isStudent
      const originalIsTeacher = me.isTeacher
      me.isStudent = () => false
      me.isTeacher = () => false
      try {
        expect(this.campaignView.shouldShow('hackstack-menu-icon')).toBe(true)
      } finally {
        me.isStudent = originalIsStudent
        me.isTeacher = originalIsTeacher
      }
    })
  })

  describe('maybeAutoShowPromotionModal', function () {
    beforeEach(function () {
      this.campaignView = new CampaignView()
      spyOn(this.campaignView, 'showAiLeagueModal')
      spyOn(this.campaignView, 'showRobloxModal')
    })

    it('shows AI League instead of Roblox after an anonymous signup prompt', function () {
      spyOn(me, 'get').and.returnValue(true)
      spyOn(me, 'isPremium').and.returnValue(false)
      spyOn(storage, 'load').and.callFake(key => key === 'prompted-for-signup')

      this.campaignView.maybeAutoShowPromotionModal()

      expect(this.campaignView.showAiLeagueModal).toHaveBeenCalled()
      expect(this.campaignView.showRobloxModal).not.toHaveBeenCalled()
    })

    it('shows AI League after a subscription prompt for free users', function () {
      spyOn(me, 'get').and.returnValue(false)
      spyOn(me, 'isPremium').and.returnValue(false)
      spyOn(storage, 'load').and.callFake(key => key === 'prompted-for-subscription')

      this.campaignView.maybeAutoShowPromotionModal()

      expect(this.campaignView.showAiLeagueModal).toHaveBeenCalled()
      expect(this.campaignView.showRobloxModal).not.toHaveBeenCalled()
    })

    it('does not show any promo modal without prior prompt state', function () {
      spyOn(me, 'get').and.returnValue(false)
      spyOn(me, 'isPremium').and.returnValue(false)
      spyOn(storage, 'load').and.returnValue(false)

      this.campaignView.maybeAutoShowPromotionModal()

      expect(this.campaignView.showAiLeagueModal).not.toHaveBeenCalled()
      expect(this.campaignView.showRobloxModal).not.toHaveBeenCalled()
    })
  })

  describe('hub music', function () {
    const HUB_CAMPAIGN_ID = '6a9fe655540e9017bfb987df'
    const ambientSound = name => ({ mp3: `db/campaign/x/${name}.mp3`, ogg: `db/campaign/x/${name}.ogg` })
    const hubCampaignRequest = () => _.last(jasmine.Ajax.requests.filter(new RegExp(`/db/campaign/${HUB_CAMPAIGN_ID}`)))
    const respondWithHubCampaign = attrs => hubCampaignRequest().respondWith({
      status: 200,
      responseText: JSON.stringify(_.extend({ _id: HUB_CAMPAIGN_ID, slug: 'rpg' }, attrs)),
    })

    beforeEach(function () {
      jasmine.clock().install()
      this.campaignView = new CampaignView()
      spyOn(this.campaignView, 'render')
      spyOn(this.campaignView, 'playAmbientSound')
      spyOn(this.campaignView, 'playMusic')
    })

    afterEach(function () {
      jasmine.clock().uninstall()
    })

    it('fetches the hub campaign on its own, since the overworld list does not include it', function () {
      expect(hubCampaignRequest()).toBeDefined()
    })

    it('plays the hub campaign ambient sound instead of the menu music', function () {
      respondWithHubCampaign({ ambientSound: ambientSound('hub') })

      expect(this.campaignView.getAmbientSoundFile()).toMatch(/\/hub\.(mp3|ogg)$/)
      expect(this.campaignView.playAmbientSound).toHaveBeenCalled()
      jasmine.clock().tick(10001)
      expect(this.campaignView.playMusic).not.toHaveBeenCalled()
    })

    it('falls back to the menu music when the hub campaign has no ambient sound', function () {
      respondWithHubCampaign({})

      expect(this.campaignView.playAmbientSound).not.toHaveBeenCalled()
      jasmine.clock().tick(10001)
      expect(this.campaignView.playMusic).toHaveBeenCalled()
    })

    it('falls back to the menu music when the hub campaign fails to load', function () {
      hubCampaignRequest().respondWith({ status: 404, responseText: JSON.stringify({}) })

      expect(this.campaignView.playAmbientSound).not.toHaveBeenCalled()
      jasmine.clock().tick(10001)
      expect(this.campaignView.playMusic).toHaveBeenCalled()
    })
  })

  describe('navigateReplacing', function () {
    beforeEach(function () {
      this.campaignView = new CampaignView()
      spyOn(application.router, 'navigate')
    })

    it('keeps the current query string and hash on the new path, replacing the history entry', function () {
      this.campaignView.navigateReplacing('/play/odyssey', 'https://codecombat.com/play/junior?hour_of_code=true&x=1#level-slug')
      expect(application.router.navigate).toHaveBeenCalledWith('/play/odyssey?hour_of_code=true&x=1#level-slug', { trigger: true, replace: true })
    })

    it('leaves the path alone when there is nothing to carry over', function () {
      this.campaignView.navigateReplacing('/play/odyssey', 'https://codecombat.com/play/junior')
      expect(application.router.navigate).toHaveBeenCalledWith('/play/odyssey', { trigger: true, replace: true })
    })
  })

  describe('junior to odyssey redirect', function () {
    beforeEach(function () {
      this.campaignView = new CampaignView()
      this.campaignView.terrain = 'junior'
      this.campaignView.editorMode = false
      spyOn(application.router, 'navigate')
      this.originalTracker = window.tracker
      window.tracker = { trackEvent: jasmine.createSpy('trackEvent') }
    })

    afterEach(function () {
      window.tracker = this.originalTracker
    })

    it('redirects a registered home user', function () {
      spyOn(me, 'isHomeUser').and.returnValue(true)
      expect(this.campaignView.shouldRedirectJuniorToOdyssey()).toBe(true)
    })

    it('redirects an anonymous visitor, who counts as a home user', function () {
      expect(me.isAnonymous()).toBe(true)
      expect(me.isHomeUser()).toBe(true)
      expect(this.campaignView.shouldRedirectJuniorToOdyssey()).toBe(true)
    })

    it('does not redirect a student', function () {
      spyOn(me, 'isHomeUser').and.returnValue(false)
      spyOn(me, 'isStudent').and.returnValue(true)
      expect(this.campaignView.shouldRedirectJuniorToOdyssey()).toBe(false)
    })

    it('does not redirect a teacher', function () {
      spyOn(me, 'isHomeUser').and.returnValue(false)
      spyOn(me, 'isTeacher').and.returnValue(true)
      expect(this.campaignView.shouldRedirectJuniorToOdyssey()).toBe(false)
    })

    it('does not redirect the campaign editor preview', function () {
      spyOn(me, 'isHomeUser').and.returnValue(true)
      this.campaignView.editorMode = true
      expect(this.campaignView.shouldRedirectJuniorToOdyssey()).toBe(false)
    })

    it('leaves other campaigns alone', function () {
      spyOn(me, 'isHomeUser').and.returnValue(true)
      this.campaignView.terrain = 'odyssey'
      expect(this.campaignView.shouldRedirectJuniorToOdyssey()).toBe(false)
      this.campaignView.terrain = 'dungeon'
      expect(this.campaignView.shouldRedirectJuniorToOdyssey()).toBe(false)
    })

    it('keeps a home user on the Junior map with ?force=junior', function () {
      spyOn(me, 'isHomeUser').and.returnValue(true)
      spyOn(utils, 'getDocumentSearchString').and.returnValue('?force=junior')
      expect(this.campaignView.shouldRedirectJuniorToOdyssey()).toBe(false)
    })

    it('ignores other force values', function () {
      spyOn(me, 'isHomeUser').and.returnValue(true)
      spyOn(utils, 'getDocumentSearchString').and.returnValue('?force=true')
      expect(this.campaignView.shouldRedirectJuniorToOdyssey()).toBe(true)
    })

    it('replaces the page with /play/odyssey and tracks the redirect', function () {
      spyOn(me, 'isHomeUser').and.returnValue(true)
      spyOn(this.campaignView, 'navigateReplacing')
      expect(this.campaignView.redirectMiddleware()).toBe(true)
      expect(this.campaignView.navigateReplacing).toHaveBeenCalledWith('/play/odyssey')
      expect(window.tracker.trackEvent).toHaveBeenCalledWith('Redirected Junior to Odyssey', { category: 'World Map', label: 'junior' })
    })

    it('does not track or navigate when there is no redirect', function () {
      spyOn(me, 'isHomeUser').and.returnValue(false)
      spyOn(this.campaignView, 'navigateReplacing')
      this.campaignView.redirectMiddleware()
      expect(this.campaignView.navigateReplacing).not.toHaveBeenCalled()
      expect(window.tracker.trackEvent).not.toHaveBeenCalled()
    })
  })

  describe('campaign editor level markers', function () {
    beforeEach(function () {
      this.campaignView = new CampaignView({ editorMode: true }, 'dungeon')
      spyOn(this.campaignView, 'render')
    })

    afterEach(function () {
      // Otherwise the view keeps re-rendering on every `me` change in later specs.
      this.campaignView.destroy()
    })

    it('starts with compact markers, not the player flags', function () {
      expect(this.campaignView.showFullFlags).toBe(false)
    })

    it('re-renders once when the flag toggle actually changes', function () {
      this.campaignView.setShowFullFlags(true)
      this.campaignView.setShowFullFlags(true)
      expect(this.campaignView.showFullFlags).toBe(true)
      expect(this.campaignView.render.calls.count()).toBe(1)
    })

    it('can start with the player flags when the editor remembered that choice', function () {
      const view = new CampaignView({ editorMode: true, showFullFlags: true }, 'dungeon')
      expect(view.showFullFlags).toBe(true)
      view.destroy()
    })

    it('never shows full flags on the player map', function () {
      const view = new CampaignView()
      spyOn(view, 'render')
      view.setShowFullFlags(true)
      expect(view.showFullFlags).toBe(false)
      expect(view.render).not.toHaveBeenCalled()
      view.destroy()
    })

    describe('hover card', function () {
      beforeEach(function () {
        const sword = new ThangType({ original: 'sword-original', name: 'Long Sword' })
        sword.setURL('/db/thang.type/sword-original/version')
        this.campaignView.supermodel.registerModel(sword)
        const bonus = new Level({ original: 'bonus-original', name: 'Bonus Level' })
        bonus.setURL('/db/level/bonus-original/version')
        this.campaignView.supermodel.registerModel(bonus)
        this.campaignView.campaign = factories.makeCampaign()
        this.campaignView.campaign.renderedLevels = [{
          original: 'on-map-original',
          name: 'Level On This Map',
          slug: 'level-on-this-map',
          rewards: [],
        }, {
          original: 'level-original',
          name: 'Treasure Cave',
          slug: 'treasure-cave',
          kind: 'mastery',
          type: 'hero',
          releasePhase: 'beta',
          requiresSubscription: true,
          practice: false,
          unlocksItem: 'sword-original',
          rewards: [{ item: 'sword-original' }, { level: 'bonus-original' }, { level: 'on-map-original' }, { hero: 'missing-hero' }],
        }]
      })

      it('names rewards from the loaded models and falls back to the original id', function () {
        const data = this.campaignView.getEditorLevelCardData('level-original')
        expect(data.name).toBe('Treasure Cave')
        expect(data.kind).toBe('mastery')
        expect(data.releasePhase).toBe('beta')
        expect(data.requiresSubscription).toBe(true)
        expect(_.pluck(data.rewards, 'name')).toEqual(['Long Sword', 'Bonus Level', 'Level On This Map', 'missing-hero'])
        expect(_.pluck(data.rewards, 'type')).toEqual(['item', 'level', 'level', 'hero'])
      })

      it('returns nothing for a level that is not on the map', function () {
        expect(this.campaignView.getEditorLevelCardData('nope')).toBeNull()
      })

      it('renders the name, kind and reward names into the card', function () {
        const $card = $('<div>').html(editorLevelCardTemplate(this.campaignView.getEditorLevelCardData('level-original')))
        expect($card.find('.card-name').text()).toBe('Treasure Cave')
        expect($card.find('.card-facts .kind').text()).toBe('mastery')
        expect($card.find('.card-facts').text()).toContain('premium')
        expect($card.find('.card-reward-name').map(function () { return $(this).text() }).get()).toEqual(['Long Sword', 'Bonus Level', 'Level On This Map', 'missing-hero'])
        expect($card.find('.card-reward-portrait').length).toBe(2)
      })
    })
  })

  describe('checkForUnearnedAchievements', function () {
    const earnedAchievementPosts = () => jasmine.Ajax.requests.filter(/\/db\/earned_achievement/).filter(r => r.method === 'POST')
    // The view's own loading also reads under /db/user/<id>/..., so match the user document itself (the test me has no id).
    const meFetches = () => jasmine.Ajax.requests.filter(/^\/db\/user(\/[^/?]*)?(\?|$)/).filter(r => r.method === 'GET')

    beforeEach(function () {
      this.previousCurrentView = globalVar.currentView
      this.lastLevel = factories.makeLevel()
      this.rewardInSameCampaign = factories.makeLevel()
      this.rewardInNextCampaign = factories.makeLevel()
      const campaignSlug = _.uniqueId('campaign-slug-')
      this.campaignView = new CampaignView()
      this.campaignView.campaign = factories.makeCampaign({ slug: campaignSlug }, { levels: new Levels([this.lastLevel, this.rewardInSameCampaign]) })
      spyOn(this.campaignView, 'render')
      this.session = new LevelSession({ _id: _.uniqueId('session_'), levelID: this.lastLevel.get('slug'), state: { complete: true } })
      globalVar.currentView = { sessions: { models: [this.session] } }
      this.achievement = { _id: _.uniqueId('achievement_'), name: 'Last Level Complete', related: this.lastLevel.get('original') }
      this.respondWithAchievements = () => _.last(jasmine.Ajax.requests.filter(new RegExp(`/db/campaign/${campaignSlug}/achievements`))).respondWith({
        status: 200,
        responseText: JSON.stringify([this.achievement]),
      })
      this.own = (...levels) => {
        const earned = me.get('earned') || {}
        earned.levels = (earned.levels || []).concat(levels.map(level => level.get('original')))
        me.set('earned', earned)
      }
    })

    afterEach(function () {
      globalVar.currentView = this.previousCurrentView
    })

    it('awards an achievement whose missing reward level is in another campaign', function () {
      this.achievement.rewards = { levels: [this.rewardInNextCampaign.get('original')] }
      this.campaignView.checkForUnearnedAchievements()
      this.respondWithAchievements()

      const posts = earnedAchievementPosts()
      expect(posts.length).toBe(1)
      expect(JSON.parse(posts[0].params)).toEqual(jasmine.objectContaining({
        achievement: this.achievement._id,
        triggeredBy: this.session.id,
        collection: 'level.sessions',
      }))
    })

    it('still awards an achievement whose missing reward level is in this campaign', function () {
      this.achievement.rewards = { levels: [this.rewardInSameCampaign.get('original')] }
      this.campaignView.checkForUnearnedAchievements()
      this.respondWithAchievements()

      expect(earnedAchievementPosts().length).toBe(1)
    })

    it('sends one request for an achievement with several missing reward levels', function () {
      this.achievement.rewards = { levels: [this.rewardInSameCampaign.get('original'), this.rewardInNextCampaign.get('original'), 'level-in-no-campaign'] }
      this.campaignView.checkForUnearnedAchievements()
      this.respondWithAchievements()

      expect(earnedAchievementPosts().length).toBe(1)
    })

    it('sends nothing when every reward level is already owned', function () {
      this.achievement.rewards = { levels: [this.rewardInSameCampaign.get('original'), this.rewardInNextCampaign.get('original')] }
      this.own(this.rewardInSameCampaign, this.rewardInNextCampaign)
      this.campaignView.checkForUnearnedAchievements()
      this.respondWithAchievements()

      expect(earnedAchievementPosts().length).toBe(0)
      expect(meFetches().length).toBe(0)
    })

    it('sends nothing when the related level is not complete', function () {
      this.achievement.rewards = { levels: [this.rewardInNextCampaign.get('original')] }
      this.session.set('state', { complete: false })
      this.campaignView.checkForUnearnedAchievements()
      this.respondWithAchievements()

      expect(earnedAchievementPosts().length).toBe(0)
    })

    it('does not send the same achievement again on the next visit to the map', function () {
      this.achievement.rewards = { levels: [this.rewardInNextCampaign.get('original')] }
      this.campaignView.checkForUnearnedAchievements()
      this.respondWithAchievements()
      this.campaignView.checkForUnearnedAchievements()
      this.respondWithAchievements()

      expect(earnedAchievementPosts().length).toBe(1)
    })

    it('tries again on the next visit when the save failed', function () {
      this.achievement.rewards = { levels: [this.rewardInNextCampaign.get('original')] }
      this.campaignView.checkForUnearnedAchievements()
      this.respondWithAchievements()
      earnedAchievementPosts()[0].respondWith({ status: 409, responseText: JSON.stringify({}) })
      expect(meFetches().length).toBe(0)
      this.campaignView.checkForUnearnedAchievements()
      this.respondWithAchievements()

      expect(earnedAchievementPosts().length).toBe(2)
    })

    it('reloads me and redraws the map once the award is saved', function () {
      this.achievement.rewards = { levels: [this.rewardInNextCampaign.get('original')] }
      this.campaignView.checkForUnearnedAchievements()
      this.respondWithAchievements()
      expect(meFetches().length).toBe(0)
      earnedAchievementPosts()[0].respondWith({ status: 201, responseText: JSON.stringify({ _id: 'earned-achievement-id' }) })

      expect(meFetches().length).toBe(1)
      this.campaignView.render.calls.reset()
      meFetches()[0].respondWith({ status: 200, responseText: JSON.stringify(me.toJSON()) })
      expect(this.campaignView.render).toHaveBeenCalled()
    })

    it('shows the unlocked levels even when reloading me fails', function () {
      this.achievement.rewards = { levels: [this.rewardInNextCampaign.get('original')] }
      this.campaignView.checkForUnearnedAchievements()
      this.respondWithAchievements()
      earnedAchievementPosts()[0].respondWith({ status: 201, responseText: JSON.stringify({ _id: 'earned-achievement-id' }) })
      this.campaignView.render.calls.reset()
      meFetches()[0].respondWith({ status: 500, responseText: JSON.stringify({}) })

      expect(me.ownsLevel(this.rewardInNextCampaign.get('original'))).toBe(true)
      expect(this.campaignView.render).toHaveBeenCalled()
    })

    it('still reloads me when the player left the map before the save finished', function () {
      this.achievement.rewards = { levels: [this.rewardInNextCampaign.get('original')] }
      this.campaignView.checkForUnearnedAchievements()
      this.respondWithAchievements()
      this.campaignView.destroy()
      earnedAchievementPosts()[0].respondWith({ status: 201, responseText: JSON.stringify({ _id: 'earned-achievement-id' }) })

      expect(meFetches().length).toBe(1)
      meFetches()[0].respondWith({ status: 500, responseText: JSON.stringify({}) })
      expect(me.ownsLevel(this.rewardInNextCampaign.get('original'))).toBe(true)
    })

    it('waits for the save to retry after a dropped connection instead of giving up on the first failure', function () {
      spyOn(_, 'delay') // CocoModel.save schedules its retry with _.delay
      this.achievement.rewards = { levels: [this.rewardInNextCampaign.get('original')] }
      this.campaignView.checkForUnearnedAchievements()
      this.respondWithAchievements()
      // A dropped connection: browsers report status 0, the fake request starts at null.
      const dropped = earnedAchievementPosts()[0]
      dropped.status = 0
      dropped.responseError()

      // Still in flight: a new visit to the map must not post it again, and there is nothing to reload yet.
      this.campaignView.checkForUnearnedAchievements()
      this.respondWithAchievements()
      expect(earnedAchievementPosts().length).toBe(1)
      expect(meFetches().length).toBe(0)

      const retry = _.delay.calls.mostRecent().args[0]
      retry()
      expect(earnedAchievementPosts().length).toBe(2)
      earnedAchievementPosts()[1].respondWith({ status: 201, responseText: JSON.stringify({ _id: 'earned-achievement-id' }) })
      expect(meFetches().length).toBe(1)
    })
  })

  describe('getMapSize', function () {
    const Campaign = require('models/Campaign')
    const viewFor = (attrs, { editorMode = true, imageSize = { width: 1920, height: 1080 } } = {}) => {
      const view = new CampaignView()
      view.editorMode = editorMode
      view.campaign = new Campaign(attrs)
      view.mapImageSize = imageSize
      return view
    }

    it('sizes a graph-map hackstack campaign to its image in the editor', function () {
      expect(viewFor({ type: 'hackstack' }).getMapSize()).toEqual({ width: 1920, height: 1080 })
    })

    it('keeps the classic 3:2 box for hero campaigns', function () {
      expect(viewFor({ type: 'hero' }).getMapSize()).toEqual({ width: 1920, height: 1280 })
    })

    it('keeps the classic box for side-scroller hackstack campaigns', function () {
      expect(viewFor({ type: 'hackstack', isSideScrollerCampaign: true }).getMapSize()).toEqual({ width: 1920, height: 1280 })
    })

    it('keeps the classic box outside the editor', function () {
      expect(viewFor({ type: 'hackstack' }, { editorMode: false }).getMapSize()).toEqual({ width: 1920, height: 1280 })
    })

    it('keeps the classic box until the image size is known', function () {
      expect(viewFor({ type: 'hackstack' }, { imageSize: null }).getMapSize()).toEqual({ width: 1920, height: 1280 })
    })
  })
}))
