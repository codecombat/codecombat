// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AdminLevelHintsView;
import 'app/styles/admin/admin-level-hints.sass';
import RootView from 'views/core/RootView';
import CocoCollection from 'collections/CocoCollection';
import Article from 'models/Article';
import Level from 'models/Level';
import Campaign from 'models/Campaign';
import Course from 'models/Course';
import utils from 'core/utils';

export default AdminLevelHintsView = (function() {
  AdminLevelHintsView = class AdminLevelHintsView extends RootView {
    static initClass() {
      this.prototype.id = 'admin-level-hints-view';
      this.prototype.template = require('app/templates/admin/admin-level-hints');
    }

    initialize() {
      if (!me.isAdmin()) { return super.initialize(); }
      this.articles = new CocoCollection([], { url: "/db/article", model: Article});
      this.supermodel.loadCollection(this.articles, 'articles');
      this.courses = new CocoCollection([], { url: "/db/course", model: Course});
      this.supermodel.loadCollection(this.courses, 'courses');
      this.campaigns = new CocoCollection([], { url: "/db/campaign?project=levels,slug", model: Campaign});
      this.supermodel.loadCollection(this.campaigns, 'campaigns');
      return super.initialize();
    }

    onLoaded() {
      let campaign;
      const orderedCampaignSlugs = ['dungeon', 'campaign-game-dev-1', 'campaign-web-dev-1', 'forest', 'campaign-game-dev-2', 'campaign-web-dev-2', 'desert', 'mountain', 'glacier'];
      const courseCampaignIds = [];
      for (var course of Array.from(utils.sortCourses(this.courses.models).reverse())) {
        if (course.get('releasePhase') === 'released') {
          campaign = _.find(this.campaigns.models, c => c.id === course.get('campaignID'));
          if (campaign) {
            orderedCampaignSlugs.splice(0, 0, campaign.get('slug'));
          }
        }
      }

      const batchSize = 1000;
      var fetchLevelSessions = (skip, results) => {
        const levelPromises = [];
        for (let i = 0; i <= 4; i++) {
          var levelPromise = Promise.resolve($.get(`/db/level?skip=${skip}&project=slug,documentation,original`));
          levelPromises.push(levelPromise);
          skip += batchSize;
        }
        return new Promise(resolve => setTimeout(resolve.bind(null, Promise.all(levelPromises)), 100))
        .then(resultsMatrix => {
          for (var newResults of Array.from(resultsMatrix)) {
            results = results.concat(newResults);
          }
          if ((results % batchSize) === 0) {
            return fetchLevelSessions(skip, results);
          } else {
            return Promise.resolve(results);
          }
        });
      };
      return fetchLevelSessions(0, [])
      .then(levels => {
        let hints, level;
        let doc;
        const levelHintsMap = {};
        for (level of Array.from(levels)) {
          var docs = level.documentation != null ? level.documentation : {};
          var general = _.filter(((() => {
            const result = [];
            for (doc of Array.from(docs.generalArticles || [])) {               result.push(__guard__(_.find(this.articles.models, article => article.get('original') === doc.original), x => x.attributes));
            }
            return result;
          })()));
          var specific = _.filter(docs.specificArticles || [], a => (a != null));
          hints = (docs.hintsB || docs.hints || []).concat(specific).concat(general);
          hints = _.sortBy(hints, function(doc) {
            if ((doc != null ? doc.name : undefined) === 'Intro') { return -1; }
            return 0;
          });
          levelHintsMap[level.slug] = hints;
        }
        this.campaignHints = [];
        for (campaign of Array.from(this.campaigns.models)) {
          var needle;
          if ((needle = campaign.get('slug'), !Array.from(orderedCampaignSlugs).includes(needle))) { continue; }
          var campaignData = {id: campaign.id, slug: campaign.get('slug'), levels: []};
          for (var levelId in campaign.get('levels')) {
            level = campaign.get('levels')[levelId];
            campaignData.levels.push({id: levelId, slug: level.slug, hints: levelHintsMap[level.slug] || []});
          }
          this.campaignHints.push(campaignData);
        }

        this.campaignHints.sort((a, b) => orderedCampaignSlugs.indexOf(a.slug) - orderedCampaignSlugs.indexOf(b.slug));
        return (typeof this.render === 'function' ? this.render() : undefined);
      });
    }
  };
  AdminLevelHintsView.initClass();
  return AdminLevelHintsView;
})();

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}