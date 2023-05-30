// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ThangTasksView;
import 'app/styles/artisans/thang-tasks-view.sass';
import RootView from 'views/core/RootView';
import template from 'app/templates/artisans/thang-tasks-view';
import ThangType from 'models/ThangType';
import ThangTypes from 'collections/ThangTypes';
import 'lib/game-libraries';

export default ThangTasksView = (function() {
  ThangTasksView = class ThangTasksView extends RootView {
    static initClass() {
      this.prototype.template = template;
      this.prototype.id = 'thang-tasks-view';
      this.prototype.events = {
        'input input': 'processThangs',
        'change input': 'processThangs'
      };
  
      this.prototype.thangs = {};
      this.prototype.processedThangs = {};
    }

    initialize() {
      this.processThangs = _.debounce(this.processThangs, 250);

      this.thangs = new ThangTypes();
      this.listenTo(this.thangs, 'sync', this.onThangsLoaded);
      return this.supermodel.trackRequest(this.thangs.fetch({
        data: {
          project: 'name,tasks,slug'
        }
      }));
    }

    onThangsLoaded(thangCollection) {
      return this.processThangs();
    }

    processThangs() {
      this.processedThangs = this.thangs.filter(_elem => // Case-insensitive search of input vs name.
      new RegExp(`${$('#name-search')[0].value}`, 'i').test(_elem.get('name')));
      for (var thang of Array.from(this.processedThangs)) {
        thang.tasks = _.filter(thang.attributes.tasks, _elem => // Similar case-insensitive search of input vs description (name).
        new RegExp(`${$('#desc-search')[0].value}`, 'i').test(_elem.name));
      }
      return this.renderSelectors('#thang-table');
    }

    sortThangs(a, b) {
      return a.get('name').localeCompare(b.get('name'));
    }

    // Jade helper
    hasIncompleteTasks(thang) {
      return thang.tasks && (thang.tasks.filter(_elem => !_elem.complete).length > 0);
    }
  };
  ThangTasksView.initClass();
  return ThangTasksView;
})();
