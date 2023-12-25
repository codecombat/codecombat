// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AchievementSearchView
const SearchView = require('views/common/SearchView')

module.exports = (AchievementSearchView = (function () {
  AchievementSearchView = class AchievementSearchView extends SearchView {
    static initClass () {
      this.prototype.id = 'editor-achievement-home-view'
      this.prototype.modelLabel = 'Achievement'
      this.prototype.model = require('models/Achievement')
      this.prototype.modelURL = '/db/achievement'
      this.prototype.tableTemplate = require('app/templates/editor/achievement/table')
      this.prototype.projection = ['name', 'description', 'collection', 'slug']
    }

    getRenderData () {
      const context = super.getRenderData()
      context.currentEditor = 'editor.achievement_title'
      context.currentNew = 'editor.new_achievement_title'
      context.currentNewSignup = 'editor.new_achievement_title_login'
      context.currentSearch = 'editor.achievement_search_title'
      context.newModelsAdminOnly = true
      if (!me.isAdmin() && !me.isArtisan()) { context.unauthorized = true }
      return context
    }
  }
  AchievementSearchView.initClass()
  return AchievementSearchView
})())
