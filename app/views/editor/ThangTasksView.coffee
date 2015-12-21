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
    @listenTo(@thangs, 'sync', @onColLoaded)
    @supermodel.loadCollection(@thangs, 'thangs')

  searchUpdate: ->
    if !@lastLoad? or (new Date()).getTime() - @lastLoad > 60 * 1000 * 1 # Update only after a minute from last update.
      @thangs.fetch()
      @listenTo(@thangs, 'sync', @onColLoaded)
      @supermodel.loadCollection(@thangs, 'thangs')
      @lastLoad = (new Date()).getTime()
    else
      @onColLoaded()
    
  onColLoaded: ->
    @processedThangs = @thangs.filter((_elem) -> 
      return _elem.get('name').toLowerCase().indexOf($('#nameSearch')[0].value.toLowerCase()) isnt -1
    )
    for thang in @processedThangs
      thang.tasks = _.filter(thang.attributes.tasks, (_elem) ->
        return _elem.name.toLowerCase().indexOf($('#descSearch')[0].value.toLowerCase()) isnt -1
      )
    newContent = $(template({me:me, view:@}))
    @$el.find('#taskTable').replaceWith($(newContent[1]).find('#taskTable'))

  sortThangs: (a, b) ->
    a.get('name').localeCompare(b.get('name'))