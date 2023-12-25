// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ArticleSearchView
const SearchView = require('views/common/SearchView')

module.exports = (ArticleSearchView = (function () {
  ArticleSearchView = class ArticleSearchView extends SearchView {
    static initClass () {
      this.prototype.id = 'editor-article-home-view'
      this.prototype.modelLabel = 'Article'
      this.prototype.model = require('models/Article')
      this.prototype.modelURL = '/db/article'
      this.prototype.tableTemplate = require('app/templates/editor/article/table')
      this.prototype.page = 'article'
    }

    getRenderData () {
      const context = super.getRenderData()
      context.currentEditor = 'editor.article_title'
      context.currentNew = 'editor.new_article_title'
      context.currentNewSignup = 'editor.new_article_title_login'
      context.currentSearch = 'editor.article_search_title'
      context.newModelsAdminOnly = true
      this.$el.i18n()
      this.applyRTLIfNeeded()
      return context
    }
  }
  ArticleSearchView.initClass()
  return ArticleSearchView
})())
