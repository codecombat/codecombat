const SearchView = require('views/common/SearchView')

class MiniGameSearchView extends SearchView {
  id = 'editor-minigame-home-view'
  modelLabel = 'Mini-Game'
  model = require('models/MiniGame')
  modelURL = '/db/mini_game'
  tableTemplate = require('app/templates/common/table')
  projection = ['name', 'description', 'slug']
  page = 'minigame'
  canMakeNew = true

  getRenderData () {
    const context = super.getRenderData()
    context.currentEditor = 'Mini-Game Editor'
    context.newModelsAdminOnly = true
    if (!me.isAdmin()) { context.unauthorized = true }
    return context
  }
}

module.exports = MiniGameSearchView
