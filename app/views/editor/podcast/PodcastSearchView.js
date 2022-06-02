const SearchView = require('views/common/SearchView')

class PodcastSearchView extends SearchView {
  id = 'editor-podcast-home-view'
  modelLabel = 'Podcast'
  model = require('models/Podcast')
  modelURL = '/db/podcast'
  tableTemplate = require('app/templates/editor/course/table')
  projection = ['name', 'description']
  page = 'podcast'
  canMakeNew = true
}

module.exports = PodcastSearchView
