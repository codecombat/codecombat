AdminClassroomLevelsView = require 'views/admin/AdminClassroomLevelsView'
AdminClassroomLevelsComponent = AdminClassroomLevelsView.prototype.VueComponent
factories = require 'test/app/factories'
Levels = require 'collections/Levels'

describe 'AdminClassroomLevelsComponent', ->
  describe 'methods', ->
    describe 'courseLevels(courseID)', ->
      it 'returns an ordered list of levels for the given course', ->
        campaignALevels = [
          factories.makeLevelObject({campaignIndex: 0})
          factories.makeLevelObject({campaignIndex: 1})
        ]
        campaignA = factories.makeCampaignObject({}, {levels: campaignALevels})
        courseA = factories.makeCourseObject({}, {campaign: campaignA})
        component = new AdminClassroomLevelsComponent({
          data: {
            courses: [courseA]
            campaigns: [campaignA]
            loading: false
          }
        })
        expect(component.courseLevels(courseA._id)).toEqual(campaignALevels)
        
  describe 'computed', ->
    describe 'levelConceptsBySlug', ->
      it 'is a map of levels to a list of concepts first introduced by that level', ->
        campaignALevels = [
          factories.makeLevelObject({concepts: ['basic_syntax']})
          factories.makeLevelObject({concepts: ['basic_syntax', 'math']})
        ]
        campaignBLevels = [
          factories.makeLevelObject({concepts: ['basic_syntax', 'math']})
          factories.makeLevelObject({concepts: ['while_loops']})
        ]
        campaignA = factories.makeCampaignObject({}, {levels: campaignALevels})
        campaignB = factories.makeCampaignObject({}, {levels: campaignBLevels})
        courseA = factories.makeCourseObject({}, {campaign: campaignA})
        courseB = factories.makeCourseObject({}, {campaign: campaignB})

        component = new AdminClassroomLevelsComponent({
          data: {
            courses: [courseA, courseB]
            campaigns: [campaignA, campaignB]
            loading: false
          }
        })
        expect(component.levelConceptsBySlug[campaignALevels[0].slug]).toEqual(["basic_syntax"])
        expect(component.levelConceptsBySlug[campaignALevels[1].slug]).toEqual(["math"])
        expect(component.levelConceptsBySlug[campaignBLevels[0].slug]).toEqual([])
        expect(component.levelConceptsBySlug[campaignBLevels[1].slug]).toEqual(["while_loops"])
        
        
