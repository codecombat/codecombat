LevelThangEditView = require 'views/editor/level/thangs/LevelThangEditView'
template = require 'app/templates/editor/level/thang/key-thang-tab-view'

module.exports = class KeyThangTabView extends LevelThangEditView
  id: null
  className: 'key-thang-tab-view tab-pane'
  template: template

  constructor: (options) ->
    super options
    @id = options.id
    @interval = setInterval @reportChanges, 750

  destroy: ->
    clearInterval @interval
    super()
