CocoView = require 'views/core/CocoView'

module.exports = class ProgressView extends CocoView
  
  id: 'progress-view'
  className: 'modal-content'
  template: require 'templates/play/level/modal/progress-view'

  events:
    'click #done-btn': 'onClickDoneButton'
    'click #next-level-btn': 'onClickNextLevelButton'

  initialize: (options) ->
    @level = options.level
    @course = options.course
    @nextLevel = options.nextLevel
    @campaign = options.campaign
    @levelSessions = options.levelSessions

  onClickDoneButton: ->
    @trigger 'done'

  onClickNextLevelButton: ->
    @trigger 'next-level'