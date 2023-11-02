/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AchievementCollection;
const CocoCollection = require('collections/CocoCollection');
const Achievement = require('models/Achievement');

module.exports = (AchievementCollection = (function() {
  AchievementCollection = class AchievementCollection extends CocoCollection {
    static initClass() {
      this.prototype.url = '/db/achievement';
      this.prototype.model = Achievement;
    }
  
    fetchRelatedToLevel(levelOriginal, options) {
      options = _.extend({data: {}}, options);
      options.data.related = levelOriginal;
      return this.fetch(options);
    }

    fetchForCampaign(campaignHandle, options) {
      options = _.extend({data: {}}, options);
      options.url = `/db/campaign/${campaignHandle}/achievements`;
      return this.fetch(options);
    }
  };
  AchievementCollection.initClass();
  return AchievementCollection;
})());
    
