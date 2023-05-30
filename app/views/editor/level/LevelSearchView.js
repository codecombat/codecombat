// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LevelSearchView;
import SearchView from 'views/common/SearchView';
import utils from 'core/utils';

export default LevelSearchView = (function() {
  LevelSearchView = class LevelSearchView extends SearchView {
    static initClass() {
      this.prototype.id = 'editor-level-home-view';
      this.prototype.modelLabel = 'Level';
      this.prototype.model = require('models/Level');
      this.prototype.modelURL = '/db/level';
      this.prototype.tableTemplate = require('app/templates/editor/level/table');
      this.prototype.projection = ['slug', 'name', 'description', 'version', 'watchers', 'creator'];
      this.prototype.page = 'level';
      this.prototype.archived = utils.isOzaria ? false : undefined;
    }

    getRenderData() {
      const context = super.getRenderData();
      context.currentEditor = 'editor.level_title';
      context.currentNew = 'editor.new_level_title';
      context.currentNewSignup = 'editor.new_level_title_login';
      context.currentSearch = 'editor.level_search_title';
      this.$el.i18n();
      this.applyRTLIfNeeded();
      return context;
    }
  };
  LevelSearchView.initClass();
  return LevelSearchView;
})();
