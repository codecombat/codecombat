require('app/styles/editor/ai-story-world/table.sass')
const SearchView = require('views/common/SearchView')

class AIStoryWorldSearchView extends SearchView {
  static initClass () {
    this.prototype.id = 'editor-ai-story-world-home-view'
    this.prototype.modelLabel = 'Story World'
    this.prototype.model = require('models/AIStoryWorld')
    this.prototype.modelURL = '/db/ai_story_world'
    this.prototype.tableTemplate = require('app/templates/editor/ai-story-world/table')
    this.prototype.projection = ['name', 'slug', 'description', 'parentWorld']
    this.prototype.page = 'ai-story-world'
    this.prototype.canMakeNew = true

    this.prototype.events = { 'click #delete-button': 'deleteAIStoryWorld' }
  }

  getRenderData () {
    const context = super.getRenderData()
    context.currentEditor = 'editor.ai_story_world_title'
    context.currentNew = 'editor.new_ai_story_world_title'
    context.currentNewSignup = 'editor.new_ai_story_world_title_login'
    context.currentSearch = 'editor.ai_story_world_search_title'
    this.$el.i18n()
    this.applyRTLIfNeeded()
    return context
  }

  deleteAIStoryWorld (e) {
    const worldId = $(e.target).parents('tr').data('model')
    const worldName = $(e.target).parents('tr').data('name')
    if (!window.confirm(`Really delete story world ${worldName}?`)) {
      noty({ text: 'Cancelled', timeout: 1000 })
      return
    }
    $.ajax({
      type: 'DELETE',
      url: `/db/ai_story_world/${worldId}`,
      success: () => {
        this.$el.find(`tr[data-model='${worldId}']`).remove()
        noty({ timeout: 2000, text: 'Aaaand it\'s gone.', type: 'success', layout: 'topCenter' })
      },
      error (jqXHR) {
        console.error(jqXHR)
        noty({ timeout: 5000, text: `Deleting the story world failed with error code ${jqXHR.status}`, type: 'error', layout: 'topCenter' })
      },
    })
  }
}
AIStoryWorldSearchView.initClass()

module.exports = AIStoryWorldSearchView
