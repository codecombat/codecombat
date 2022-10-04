const SearchView = require('views/common/SearchView')

class AnnouncementSearchView extends SearchView{
  id = 'editor-announcement-home-view'
  modelLabel = 'Announcement'
  model = require('models/Announcement')
  modelURL = '/db/announcements'
  tableTemplate = require('app/templates/common/table')
  projection = []
  page = 'announcement'
  canMakeNew = true
}

module.exports = AnnouncementSearchView
