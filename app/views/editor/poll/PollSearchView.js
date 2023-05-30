// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let PollSearchView;
import SearchView from 'views/common/SearchView';

export default PollSearchView = (function() {
  PollSearchView = class PollSearchView extends SearchView {
    static initClass() {
      this.prototype.id = 'editor-poll-home-view';
      this.prototype.modelLabel = 'Poll';
      this.prototype.model = require('models/Poll');
      this.prototype.modelURL = '/db/poll';
      this.prototype.tableTemplate = require('app/templates/editor/poll/poll-search-table');
      this.prototype.projection = ['name', 'description', 'slug', 'priority', 'created'];
    }

    getRenderData() {
      const context = super.getRenderData();
      context.currentEditor = 'editor.poll_title';
      context.currentNew = 'editor.new_poll_title';
      context.currentNewSignup = 'editor.new_poll_title_login';
      context.currentSearch = 'editor.poll_search_title';
      context.newModelsAdminOnly = true;
      if (!me.isAdmin()) { context.unauthorized = true; }
      return context;
    }
  };
  PollSearchView.initClass();
  return PollSearchView;
})();
