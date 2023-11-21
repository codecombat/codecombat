// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ThangTypeSearchView;
require('app/styles/editor/thang/home.sass');
const SearchView = require('views/common/SearchView');
const utils = require('core/utils');

module.exports = (ThangTypeSearchView = (function() {
  ThangTypeSearchView = class ThangTypeSearchView extends SearchView {
    constructor(...args) {
      super(...args);
      this.onSearchChange = this.onSearchChange.bind(this);
    }

    static initClass() {
      this.prototype.id = 'thang-type-home-view';
      this.prototype.modelLabel = 'Thang Type';
      this.prototype.model = require('models/ThangType');
      this.prototype.modelURL = '/db/thang.type';
      this.prototype.tableTemplate = require('app/templates/editor/thang/table');
      this.prototype.projection = ['original', 'name', 'version', 'description', 'slug', 'kind', 'rasterIcon', 'tasks'];
      this.prototype.page = 'thang';
      this.prototype.archived = utils.isOzaria ? false : undefined;
    }

    getRenderData() {
      const context = super.getRenderData();
      context.currentEditor = 'editor.thang_title';
      context.currentNew = 'editor.new_thang_title';
      context.currentNewSignup = 'editor.new_thang_title_login';
      context.currentSearch = 'editor.thang_search_title';
      context.newModelsAdminOnly = true;
      this.$el.i18n();
      this.applyRTLIfNeeded();
      return context;
    }

    onSearchChange() {
      super.onSearchChange();
      return this.$el.find('img').error(function() { return $(this).hide(); });
    }
  };
  ThangTypeSearchView.initClass();
  return ThangTypeSearchView;
})());

  // TODO: do the new thing on click, not just enter
