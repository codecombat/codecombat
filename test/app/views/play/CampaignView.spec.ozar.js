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

xdescribe('CampaignView', () => describe('when 4 earned levels', function() {
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

  return describe('and 2nd rewards a practice a non-practice level', function() {
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
}));
