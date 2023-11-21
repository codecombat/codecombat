/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const factories = require('test/app/factories');
const CampaignView = require('views/play/CampaignView');
const Levels = require('collections/Levels');

describe('CampaignView', () => describe('when 4 earned levels', function() {
  beforeEach(function() {
    let level;
    this.campaignView = new CampaignView();
    this.campaignView.levelStatusMap = {};
    const levels = new Levels(_.times(4, () => factories.makeLevel()));
    this.campaignView.campaign = factories.makeCampaign({}, {levels});
    this.levels = ((() => {
      const result = [];
      for (level of Array.from(levels.models)) {           result.push(level.toJSON());
      }
      return result;
    })());
    const earned = me.get('earned') || {};
    if (earned.levels == null) { earned.levels = []; }
    for (level of Array.from(this.levels)) { earned.levels.push(level.original); }
    return me.set('earned', earned);
  });

  describe('and 3rd one is practice in classroom only', function() {
    beforeEach(function() {
      // Not named "Level Name [ABCD]", so not actually a practice level in home version.
      this.levels[2].practice = true;
      return this.campaignView.annotateLevels(this.levels);
    });
    return it('does not hide the not-really-practice level', function() {
      expect(this.levels[2].hidden).toEqual(false);
      return expect(this.levels[3].hidden).toEqual(false);
    });
  });

  describe('and 2nd rewards a practice a non-practice level', function() {
    beforeEach(function() {
      this.campaignView.levelStatusMap[this.levels[0].slug] = 'complete';
      this.campaignView.levelStatusMap[this.levels[1].slug] = 'complete';
      this.levels[1].rewards = [{level: this.levels[2].original}, {level: this.levels[3].original}];
      this.levels[2].practice = true;
      this.levels[2].name += ' A';
      this.levels[2].slug += '-a';
      this.campaignView.annotateLevels(this.levels);
      return this.campaignView.determineNextLevel(this.levels);
    });
    return it('points at practice level first', function() {
      expect(this.levels[2].next).toEqual(true);
      return expect(this.levels[3].next).not.toBeDefined(true);
    });
  });

  return describe('applyCourseLogicToLevels', function() {

    beforeEach(function() {
      this.campaignView = new CampaignView();
      this.campaignView.courseStats = {
        levels: { 
          first: { get(slug) { return 'levelX'; } } } 
      };
      this.campaignView.classroom = jasmine.createSpyObj('classroom', ['isStudentOnLockedLevel', 'isStudentOnOptionalLevel']);
      this.campaignView.classroom.isStudentOnLockedLevel.and.callFake((id, courseId, original) => original.match(/locked/i));
      this.campaignView.classroom.isStudentOnOptionalLevel.and.callFake((id, courseId, original) => original.match(/optional/i));
      this.campaignView.courseInstance = { get(startLockedLevel) { return undefined; } };
      this.campaignView.course = { get(slug) { return 'course1'; } };
      return this.campaignView.campaign = {
        levelIsPractice(level) { return Boolean(level.practice); },
        levelIsAssessment(level) { return Boolean(level.assessment); }
      };});

    it('should apply locked flag on locked level', function() {
      const orderedLevels = [
        { slug: 'level1', original: 'level1' },
        { slug: 'level2', original: 'level2' },
        { slug: 'level3Locked', original: 'level3Locked' }
      ];

      this.campaignView.applyCourseLogicToLevels(orderedLevels);

      expect(orderedLevels[0].locked).toBe(false);
      expect(orderedLevels[1].locked).toBe(false);
      return expect(orderedLevels[2].locked).toBe(true);
    });

    it('should apply locked flag on all levels after a locked one', function() {
      const orderedLevels = [
        { slug: 'level1', original: 'level1' },
        { slug: 'level2', original: 'level2' },
        { slug: 'level3Locked', original: 'level3Locked' },
        { slug: 'level4', original: 'level4' },
        { slug: 'level5', original: 'level5' }
      ];

      this.campaignView.applyCourseLogicToLevels(orderedLevels);

      expect(orderedLevels[0].locked).toBe(false);
      expect(orderedLevels[1].locked).toBe(false);
      expect(orderedLevels[2].locked).toBe(true);        
      expect(orderedLevels[3].locked).toBe(true);        
      return expect(orderedLevels[4].locked).toBe(true);
    });        

    return it('should not apply locked flag on all levels after a skipped one', function() {
      const orderedLevels = [
        { slug: 'level1', original: 'level1' },
        { slug: 'level2', original: 'level2' },
        { slug: 'level3LockedOptional', original: 'level3LockedOptional' },
        { slug: 'level4', original: 'level4' },
        { slug: 'level5', original: 'level5' }
      ];

      this.campaignView.applyCourseLogicToLevels(orderedLevels);

      expect(orderedLevels[0].locked).toBe(false);
      expect(orderedLevels[1].locked).toBe(false);
      expect(orderedLevels[2].locked).toBe(true);
      expect(orderedLevels[3].locked).toBe(false);        
      return expect(orderedLevels[4].locked).toBe(false);
    });
  });
}));            