SearchView = require 'views/kinds/SearchView'

module.exports = class ThangTypeHomeView extends SearchView
  id: 'thang-type-home-view'
  modelLabel: 'Thang Type'
  model: require 'models/ThangType'
  modelURL: '/db/thang.type'
  page: 'thang'
  tableTemplate: require 'templates/kinds/table'

  onSearchChange: =>
    super()
    @$el.find("img").error(-> $(this).hide())

  # TODO: do the new thing on click, not just enter