require('app/styles/artisans/thang-tasks-view.sass')
RootView = require 'views/core/RootView'
template = require 'templates/artisans/thang-tasks-view'

ThangType = require 'models/ThangType'

ThangTypes = require 'collections/ThangTypes'

require 'lib/game-libraries'

module.exports = class ThangTasksView extends RootView
  template: template
  id: 'thang-tasks-view'
  events:
    'input input': 'processThangs'
    'change input': 'processThangs'

  thangs: {}
  processedThangs: {}

  initialize: () ->
    @processThangs = _.debounce(@processThangs, 250)

    @thangs = new ThangTypes()
    @listenTo(@thangs, 'sync', @onThangsLoaded)
    @supermodel.trackRequest(@thangs.fetch(
      data:
        project: 'name,tasks,slug'
    ))
      
  onThangsLoaded: (thangCollection) ->
    @processThangs()

  processThangs: ->
    @processedThangs = @thangs.filter (_elem) ->
      # Case-insensitive search of input vs name.
      return ///#{$('#name-search')[0].value}///i.test _elem.get('name')
    for thang in @processedThangs
      thang.tasks = _.filter thang.attributes.tasks, (_elem) ->
        # Similar case-insensitive search of input vs description (name).
        return ///#{$('#desc-search')[0].value}///i.test _elem.name
    @renderSelectors '#thang-table'

  sortThangs: (a, b) ->
    a.get('name').localeCompare(b.get('name'))

  # Jade helper
  hasIncompleteTasks: (thang) ->
    return thang.tasks and thang.tasks.filter((_elem) -> return not _elem.complete).length > 0
