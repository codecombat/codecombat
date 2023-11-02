/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LevelTasksView;
require('app/styles/artisans/level-tasks-view.sass');
const RootView = require('views/core/RootView');
const template = require('app/templates/artisans/level-tasks-view');

const Campaigns = require('collections/Campaigns');

const Campaign = require('models/Campaign');

module.exports = (LevelTasksView = (function() {
  let excludedCampaigns = undefined;
  LevelTasksView = class LevelTasksView extends RootView {
    static initClass() {
      this.prototype.template = template;
      this.prototype.id = 'level-tasks-view';
      this.prototype.events = {
        'input .searchInput': 'processLevels',
        'change .searchInput': 'processLevels'
      };
  
      excludedCampaigns = [
        'picoctf', 'auditions','dungeon-branching-test', 'forest-branching-test', 'desert-branching-test'
      ];
    }

    initialize() {
      this.levels = {};
      this.campaigns = new Campaigns();
      return this.supermodel.trackRequest(this.campaigns.fetchCampaignsAndRelatedLevels({ excludes: excludedCampaigns }));
    }

    onLoaded() {
      for (var campaign of Array.from(this.campaigns.models)) {
        for (var level of Array.from(campaign.levels.models)) {
          var levelSlug = level.get('slug');
          this.levels[levelSlug] = level;
        }
      }
      this.processLevels();
      return super.onLoaded();
    }


    processLevels() {
      this.processedLevels = {};
      for (var key in this.levels) {
        var level = this.levels[key];
        var tasks = level.get('tasks');
        var name = level.get('name');
        if (this.processedLevels[key]) { continue; }
        if (!new RegExp(`${$('#name-search')[0].value}`, 'i').test(name)) { continue; }
        var filteredTasks = (tasks != null ? tasks : []).filter(elem => // Similar case-insensitive search of input vs description (name).
        new RegExp(`${$('#desc-search')[0].value}`, 'i').test(elem.name));
        this.processedLevels[key] = {
          tasks: filteredTasks,
          name
        };
      }
      return this.renderSelectors('#level-table');
    }

    // Jade helper
    hasIncompleteTasks(level) {
      return level.tasks && (level.tasks.filter(_elem => !_elem.complete).length > 0);
    }
  };
  LevelTasksView.initClass();
  return LevelTasksView;
})());
