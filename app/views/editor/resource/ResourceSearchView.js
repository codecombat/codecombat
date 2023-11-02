// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ResourceSearchView;
require('app/styles/editor/resource/table.sass');
const SearchView = require('views/common/SearchView');

module.exports = (ResourceSearchView = (function() {
  ResourceSearchView = class ResourceSearchView extends SearchView {
    static initClass() {
      this.prototype.id = 'editor-resource-home-view';
      this.prototype.modelLabel = 'Resource';
      this.prototype.model = require('models/ResourceHubResource');
      this.prototype.modelURL = '/db/resource_hub_resource';
      this.prototype.tableTemplate = require('app/templates/editor/resource/table');
      this.prototype.projection = ['slug', 'name', 'description', 'index', 'watchers', 'product', 'link', 'section', 'priority', 'courses'];
      this.prototype.page = 'resource';
      this.prototype.canMakeNew = true;
    }

    getRenderData() {
      const context = super.getRenderData();
      context.currentEditor = 'editor.resource_title';
      context.currentNew = 'editor.new_resource_title';
      context.currentNewSignup = 'editor.new_resource_title_login';
      context.currentSearch = 'editor.resource_search_title';
      this.$el.i18n();
      this.applyRTLIfNeeded();
      return context;
    }
  };
  ResourceSearchView.initClass();
  return ResourceSearchView;
})());
