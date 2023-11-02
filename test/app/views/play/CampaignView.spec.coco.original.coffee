factories = require 'test/app/factories'
CampaignView = require 'views/play/CampaignView'
Levels = require 'collections/Levels'

describe 'CampaignView', ->

  describe 'when 4 earned levels', ->
    beforeEach ->
      @campaignView = new CampaignView()
      @campaignView.levelStatusMap = {}
      levels = new Levels(_.times(4, -> factories.makeLevel()))
      @campaignView.campaign = factories.makeCampaign({}, {levels})
      @levels = (level.toJSON() for level in levels.models)
      earned = me.get('earned') or {}
      earned.levels ?= []
      earned.levels.push(level.original) for level in @levels
      me.set('earned', earned)

    describe 'and 3rd one is practice in classroom only', ->
      beforeEach ->
        # Not named "Level Name [ABCD]", so not actually a practice level in home version.
        @levels[2].practice = true
        @campaignView.annotateLevels(@levels)
      it 'does not hide the not-really-practice level', ->
        expect(@levels[2].hidden).toEqual(false)
        expect(@levels[3].hidden).toEqual(false)

    describe 'and 2nd rewards a practice a non-practice level', ->
      beforeEach ->
        @campaignView.levelStatusMap[@levels[0].slug] = 'complete'
        @campaignView.levelStatusMap[@levels[1].slug] = 'complete'
        @levels[1].rewards = [{level: @levels[2].original}, {level: @levels[3].original}]
        @levels[2].practice = true
        @levels[2].name += ' A'
        @levels[2].slug += '-a'
        @campaignView.annotateLevels(@levels)
        @campaignView.determineNextLevel(@levels)
      it 'points at practice level first', ->
        expect(@levels[2].next).toEqual(true)
        expect(@levels[3].next).not.toBeDefined(true)

    describe 'applyCourseLogicToLevels', ->

      beforeEach ->
        @campaignView = new CampaignView()
        @campaignView.courseStats = {
          levels: { 
            first: { get: (slug) -> 'levelX' } } 
        }
        @campaignView.classroom = jasmine.createSpyObj('classroom', ['isStudentOnLockedLevel', 'isStudentOnOptionalLevel'])
        @campaignView.classroom.isStudentOnLockedLevel.and.callFake((id, courseId, original) -> original.match /locked/i)
        @campaignView.classroom.isStudentOnOptionalLevel.and.callFake((id, courseId, original) -> original.match /optional/i)
        @campaignView.courseInstance = { get: (startLockedLevel) -> undefined }
        @campaignView.course = { get: (slug) -> 'course1' }
        @campaignView.campaign = {
          levelIsPractice: (level) -> Boolean level.practice
          levelIsAssessment: (level) -> Boolean level.assessment
        }

      it 'should apply locked flag on locked level', ->
        orderedLevels = [
          { slug: 'level1', original: 'level1' },
          { slug: 'level2', original: 'level2' },
          { slug: 'level3Locked', original: 'level3Locked' }
        ]

        @campaignView.applyCourseLogicToLevels(orderedLevels)

        expect(orderedLevels[0].locked).toBe(false)
        expect(orderedLevels[1].locked).toBe(false)
        expect(orderedLevels[2].locked).toBe(true)

      it 'should apply locked flag on all levels after a locked one', ->
        orderedLevels = [
          { slug: 'level1', original: 'level1' },
          { slug: 'level2', original: 'level2' },
          { slug: 'level3Locked', original: 'level3Locked' },
          { slug: 'level4', original: 'level4' },
          { slug: 'level5', original: 'level5' }
        ]

        @campaignView.applyCourseLogicToLevels(orderedLevels)

        expect(orderedLevels[0].locked).toBe(false)
        expect(orderedLevels[1].locked).toBe(false)
        expect(orderedLevels[2].locked).toBe(true)        
        expect(orderedLevels[3].locked).toBe(true)        
        expect(orderedLevels[4].locked).toBe(true)        

      it 'should not apply locked flag on all levels after a skipped one', ->
        orderedLevels = [
          { slug: 'level1', original: 'level1' },
          { slug: 'level2', original: 'level2' },
          { slug: 'level3LockedOptional', original: 'level3LockedOptional' },
          { slug: 'level4', original: 'level4' },
          { slug: 'level5', original: 'level5' }
        ]

        @campaignView.applyCourseLogicToLevels(orderedLevels)

        expect(orderedLevels[0].locked).toBe(false)
        expect(orderedLevels[1].locked).toBe(false)
        expect(orderedLevels[2].locked).toBe(true)
        expect(orderedLevels[3].locked).toBe(false)        
        expect(orderedLevels[4].locked).toBe(false)            