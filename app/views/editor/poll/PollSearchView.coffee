SearchView = require 'views/common/SearchView'

module.exports = class PollSearchView extends SearchView
  id: 'editor-poll-home-view'
  modelLabel: 'Poll'
  model: require 'models/Poll'
  modelURL: '/db/poll'
  tableTemplate: require 'templates/editor/poll/poll-search-table'
  projection: ['name', 'description', 'slug', 'priority', 'created']

  getRenderData: ->
    context = super()
    context.currentEditor = 'editor.poll_title'
    context.currentNew = 'editor.new_poll_title'
    context.currentNewSignup = 'editor.new_poll_title_login'
    context.currentSearch = 'editor.poll_search_title'
    context.newModelsAdminOnly = true
    context.unauthorized = true unless me.isAdmin()
    context
