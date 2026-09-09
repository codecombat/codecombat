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
const storage = require('core/storage')
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
      return this.campaignView.campaign = {
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
          original: 'level-original',
          name: 'Treasure Cave',
          slug: 'treasure-cave',
          kind: 'mastery',
          type: 'hero',
          releasePhase: 'beta',
          requiresSubscription: true,
          practice: false,
          unlocksItem: 'sword-original',
          rewards: [{ item: 'sword-original' }, { level: 'bonus-original' }, { hero: 'missing-hero' }],
        }]
      })

      it('names rewards from the loaded models and falls back to the original id', function () {
        const data = this.campaignView.getEditorLevelCardData('level-original')
        expect(data.name).toBe('Treasure Cave')
        expect(data.kind).toBe('mastery')
        expect(data.releasePhase).toBe('beta')
        expect(data.requiresSubscription).toBe(true)
        expect(_.pluck(data.rewards, 'name')).toEqual(['Long Sword', 'Bonus Level', 'missing-hero'])
        expect(_.pluck(data.rewards, 'type')).toEqual(['item', 'level', 'hero'])
      })

      it('returns nothing for a level that is not on the map', function () {
        expect(this.campaignView.getEditorLevelCardData('nope')).toBeNull()
      })

      it('renders the name, kind and reward names into the card', function () {
        const $card = $('<div>').html(editorLevelCardTemplate(this.campaignView.getEditorLevelCardData('level-original')))
        expect($card.find('.card-name').text()).toBe('Treasure Cave')
        expect($card.find('.card-facts .kind').text()).toBe('mastery')
        expect($card.find('.card-facts').text()).toContain('premium')
        expect($card.find('.card-reward-name').map(function () { return $(this).text() }).get()).toEqual(['Long Sword', 'Bonus Level', 'missing-hero'])
        expect($card.find('.card-reward-portrait').length).toBe(2)
      })
    })
  })
}))
