import SearchView from 'views/common/SearchView';

class PodcastSearchView extends SearchView {
  id = 'editor-podcast-home-view'
  modelLabel = 'Podcast'
  model = require('models/Podcast')
  modelURL = '/db/podcast'
  tableTemplate = require('app/templates/common/table')
  projection = ['name', 'description', 'slug']
  page = 'podcast'
  canMakeNew = true
}

export default PodcastSearchView;
