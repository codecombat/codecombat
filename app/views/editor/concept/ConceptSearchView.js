// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ConceptSearchView
require('app/styles/editor/concept/table.sass')
const SearchView = require('views/common/SearchView')

module.exports = (ConceptSearchView = (function () {
  ConceptSearchView = class ConceptSearchView extends SearchView {
    static initClass () {
      this.prototype.id = 'editor-concept-home-view'
      this.prototype.modelLabel = 'Concept'
      this.prototype.model = require('models/Concept')
      this.prototype.modelURL = '/db/concept'
      this.prototype.tableTemplate = require('app/templates/editor/concept/table')
      this.prototype.projection = ['slug', 'name', 'description', 'tagger', 'taggerFunction', 'deprecated', 'automatic']
      this.prototype.page = 'concept'
      this.prototype.canMakeNew = true
    }

    getRenderData () {
      const context = super.getRenderData()
      context.currentEditor = 'editor.concept_title'
      context.currentNew = 'editor.new_concept_title'
      context.currentSearch = 'editor.concept_search_title'
      this.$el.i18n()
      this.applyRTLIfNeeded()
      return context
    }
  }
  ConceptSearchView.initClass()
  return ConceptSearchView
})())
