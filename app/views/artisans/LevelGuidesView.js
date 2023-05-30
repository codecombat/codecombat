/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LevelGuidesView;
require('app/styles/artisans/level-guides-view.sass');
const RootView = require('views/core/RootView');
const template = require('app/templates/artisans/level-guides-view');

const Campaigns = require('collections/Campaigns');
const Campaign = require('models/Campaign');

const Levels = require('collections/Levels');
const Level = require('models/Level');

module.exports = (LevelGuidesView = (function() {
  let excludedCampaigns = undefined;
  let includedCampaigns = undefined;
  LevelGuidesView = class LevelGuidesView extends RootView {
    static initClass() {
      this.prototype.template = template;
      this.prototype.id = 'level-guides-view';
      this.prototype.events = {
        'click #overview-button': 'onOverviewButtonClicked',
        'click #intro-button': 'onIntroButtonClicked'
      };
  
      excludedCampaigns = [
        'pico-ctf', 'auditions'
      ];
      includedCampaigns = [
        'intro', 'course-2', 'course-3', 'course-4', 'course-5', 'course-6',
        'web-dev-1', 'web-dev-2',
        'game-dev-1', 'game-dev-2'
      ];
      this.prototype.levels = [];
    }

    onOverviewButtonClicked(e) {
      return this.$('.overview').toggleClass('in');
    }
    onIntroButtonClicked(e) {
      return this.$('.intro').toggleClass('in');
    }

    initialize() {

      this.campaigns = new Campaigns();

      this.listenTo(this.campaigns, 'sync', this.onCampaignsLoaded);
      return this.supermodel.trackRequest(this.campaigns.fetch({
        data: {
          project: 'name,slug,levels'
        }
      }));
    }
    onCampaignsLoaded(campCollection) {
      return (() => {
        const result = [];
        for (var camp of Array.from(campCollection.models)) {
          var campaignSlug = camp.get('slug');
          if (Array.from(excludedCampaigns).includes(campaignSlug)) { continue; }
          if (!Array.from(includedCampaigns).includes(campaignSlug)) { continue; }
          var levels = camp.get('levels');

          levels = new Levels();
          this.listenTo(levels, 'sync', this.onLevelsLoaded);
          result.push(levels.fetchForCampaign(campaignSlug));
        }
        return result;
      })();
    }
        //for key, level of levels

    onLevelsLoaded(lvlCollection) {
      lvlCollection.models.reverse();
      //console.log lvlCollection
      for (var level of Array.from(lvlCollection.models)) {
        //console.log level
        var jsIndex, pyIndex;
        var levelSlug = level.get('slug');
        var overview = _.find(level.get('documentation').specificArticles, {name:'Overview'});
        var intro = _.find(level.get('documentation').specificArticles, {name:'Intro'});
        //if intro and overview
        var problems = [];
        if (!overview) {
          problems.push('No Overview');
        } else {
          if (!overview.i18n) {
            problems.push('Overview doesn\'t have i18n field');
          }
          if (!overview.body) {
            problems.push('Overview doesn\'t have a body');
          } else {
            if (__guard__(level.get('campaign'), x => x.indexOf('web')) === -1) {
              jsIndex = overview.body.indexOf('```javascript');
              pyIndex = overview.body.indexOf('```python');
              if (((jsIndex === -1) && (pyIndex !== -1)) || ((jsIndex !== -1) && (pyIndex === -1))) {
                problems.push('Overview is missing a language example.');
              }
            }
          }
        }
        if (!intro) {
          problems.push('No Intro');
        } else {
          if (!intro.i18n) {
            problems.push('Intro doesn\'t have i18n field');
          }
          if (!intro.body) {
            problems.push('Intro doesn\'t have a body');
          } else {
            if (intro.body.indexOf('file/db') === -1) {
              problems.push('Intro is missing image');
            }
            if (__guard__(level.get('campaign'), x1 => x1.indexOf('web')) === -1) {
              jsIndex = intro.body.indexOf('```javascript');
              pyIndex = intro.body.indexOf('```python');
              if (((jsIndex === -1) && (pyIndex !== -1)) || ((jsIndex !== -1) && (pyIndex === -1))) {
                problems.push('Intro is missing a language example.');
              }
            }
          }
        }
        this.levels.push({
          level,
          overview,
          intro,
          problems
        });
        this.levels.sort((a, b) => b.problems.length - a.problems.length);
      }
      return this.renderSelectors('#level-table');
    }
  };
  LevelGuidesView.initClass();
  return LevelGuidesView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}