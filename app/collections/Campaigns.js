// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Campaigns;
import Campaign from 'models/Campaign';
import CocoCollection from 'collections/CocoCollection';

export default Campaigns = (function() {
  Campaigns = class Campaigns extends CocoCollection {
    static initClass() {
      this.prototype.model = Campaign;
      this.prototype.url = '/db/campaign';
    }

    initialize(models, options) {
      if (options == null) { options = {}; }
      this.options = options;
      this.forceCourseNumbering = this.options.forceCourseNumbering;
      return super.initialize(...arguments);
    }

    _prepareModel(model, options) {
      model.forceCourseNumbering = this.forceCourseNumbering;
      return super._prepareModel(...arguments);
    }

    fetchByType(type, options) {
      if (options == null) { options = {}; }
      if (options.data == null) { options.data = {}; }
      options.data.type = type;
      return this.fetch(options);
    }
    
    fetchCampaignsAndRelatedLevels(options, levelOptions) {
      if (options == null) { options = {}; }
      if (levelOptions == null) { levelOptions = {}; }
      const Levels = require('collections/Levels');
      if (options.data == null) { options.data = {}; }
      options.data.project = 'slug';
      const exclude = options.exclude || [];
      return this.fetch(options)
        .then(() => {
          const toRemove = this.filter(function(c) { let needle;
          return (needle = c.get('slug'), Array.from(exclude).includes(needle)); });
          this.remove(toRemove);
          if (levelOptions.data == null) { levelOptions.data = {}; }
          if (levelOptions.data.project == null) { levelOptions.data.project = 'thangs,name,slug,campaign,tasks'; }
          const jqxhrs = [];
          for (var campaign of Array.from(this.models)) {
            campaign.levels = new Levels();
            jqxhrs.push(campaign.levels.fetchForCampaign(campaign.get('slug'), levelOptions));
          }
          return $.when(...Array.from(jqxhrs || []));
      });
    }
  };
  Campaigns.initClass();
  return Campaigns;
})();
