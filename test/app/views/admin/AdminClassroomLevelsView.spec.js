/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const AdminClassroomLevelsView = require('views/admin/AdminClassroomLevelsView');
const AdminClassroomLevelsComponent = AdminClassroomLevelsView.prototype.VueComponent;
const factories = require('test/app/factories');
const Levels = require('collections/Levels');

describe('AdminClassroomLevelsComponent', function() {
  describe('methods', () => describe('courseLevels(courseID)', () => it('returns an ordered list of levels for the given course', function() {
    const campaignALevels = [
      factories.makeLevelObject({campaignIndex: 0}),
      factories.makeLevelObject({campaignIndex: 1})
    ];
    const campaignA = factories.makeCampaignObject({}, {levels: campaignALevels});
    const courseA = factories.makeCourseObject({}, {campaign: campaignA});
    const component = new AdminClassroomLevelsComponent({
      data: {
        courses: [courseA],
        campaigns: [campaignA],
        loading: false
      }
    });
    return expect(component.courseLevels(courseA._id)).toEqual(campaignALevels);
  })));
        
  return describe('computed', () => describe('levelConceptsBySlug', () => it('is a map of levels to a list of concepts first introduced by that level', function() {
    const campaignALevels = [
      factories.makeLevelObject({concepts: ['basic_syntax']}),
      factories.makeLevelObject({concepts: ['basic_syntax', 'math']})
    ];
    const campaignBLevels = [
      factories.makeLevelObject({concepts: ['basic_syntax', 'math']}),
      factories.makeLevelObject({concepts: ['while_loops']})
    ];
    const campaignA = factories.makeCampaignObject({}, {levels: campaignALevels});
    const campaignB = factories.makeCampaignObject({}, {levels: campaignBLevels});
    const courseA = factories.makeCourseObject({}, {campaign: campaignA});
    const courseB = factories.makeCourseObject({}, {campaign: campaignB});

    const component = new AdminClassroomLevelsComponent({
      data: {
        courses: [courseA, courseB],
        campaigns: [campaignA, campaignB],
        loading: false
      }
    });
    expect(component.levelConceptsBySlug[campaignALevels[0].slug]).toEqual(["basic_syntax"]);
    expect(component.levelConceptsBySlug[campaignALevels[1].slug]).toEqual(["math"]);
    expect(component.levelConceptsBySlug[campaignBLevels[0].slug]).toEqual([]);
    return expect(component.levelConceptsBySlug[campaignBLevels[1].slug]).toEqual(["while_loops"]);
  })));
});
        
        
