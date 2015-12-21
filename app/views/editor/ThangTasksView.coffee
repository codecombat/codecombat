RootView = require 'views/core/RootView'
template = require 'templates/editor/thangTasksView'
ThangType = require 'models/ThangType'
CocoCollection = require 'collections/CocoCollection'

module.exports = class ThangTasksView extends RootView
  template: template
  id: 'thang-tasks-view'
  events:
    'input input': 'searchUpdate'
    'change input': 'searchUpdate'

  constructor: (options) ->
    super options
    @thangs = new CocoCollection([],
      url: '/db/thang.type?project=name,tasks,slug'
      model: ThangType
      comparator: @sortThangs
    )
    @lastLoad = (new Date()).getTime()
    @listenTo(@thangs, 'sync', @onThangsLoaded)
    @supermodel.loadCollection(@thangs, 'thangs')

  searchUpdate: ->
    if not @lastLoad? or (new Date()).getTime() - @lastLoad > 60 * 1000 * 1 # Update only after a minute from last update.
      @thangs.fetch()
      @listenTo(@thangs, 'sync', @onThangsLoaded)
      @supermodel.loadCollection(@thangs, 'thangs')
      @lastLoad = (new Date()).getTime()
    else
      @onThangsLoaded()
      
  onThangsLoaded: ->
    @processedThangs = @thangs.filter (_elem) ->
      # Case-insensitive search of input vs name.
      return ///#{$('#nameSearch')[0].value}///i.test _elem.get('name')
    for thang in @processedThangs
      thang.tasks = _.filter thang.attributes.tasks, (_elem) ->
        # Similar case-insensitive search of input vs description (name).
        return ///#{$('#descSearch')[0].value}///i.test _elem.name
    @renderSelectors '#thangTable'

  sortThangs: (a, b) ->
    a.get('name').localeCompare(b.get('name'))

  # Jade helper
  hasIncompleteTasks: (thang) ->
    return thang.tasks and thang.tasks.filter((_elem) -> return not _elem.complete).length > 0