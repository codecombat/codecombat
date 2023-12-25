// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let StandardsCorrelationSearchView
require('app/styles/editor/standards/table.sass')
const SearchView = require('views/common/SearchView')

module.exports = (StandardsCorrelationSearchView = (function () {
  StandardsCorrelationSearchView = class StandardsCorrelationSearchView extends SearchView {
    static initClass () {
      this.prototype.id = 'editor-standards-home-view'
      this.prototype.modelLabel = 'standards'
      this.prototype.model = require('models/StandardsCorrelation')
      this.prototype.modelURL = '/db/standards'
      this.prototype.tableTemplate = require('app/templates/editor/standards/table')
      this.prototype.projection = ['slug', 'name']
      this.prototype.page = 'standards'
      this.prototype.canMakeNew = true
    }

    getRenderData () {
      const context = super.getRenderData()
      context.currentEditor = 'editor.standards_title'
      context.currentNew = 'editor.new_standards_title'
      context.currentSearch = 'editor.standards_search_title'
      this.$el.i18n()
      this.applyRTLIfNeeded()
      return context
    }
  }
  StandardsCorrelationSearchView.initClass()
  return StandardsCorrelationSearchView
})())
