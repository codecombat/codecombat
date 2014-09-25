ModalView = require 'views/kinds/ModalView'
template = require 'templates/play/modal/play-achievements-modal'
CocoCollection = require 'collections/CocoCollection'
Achievement = require 'models/Achievement'
#AchievementView = require 'views/game-menu/AchievementView'

module.exports = class PlayAchievementsModal extends ModalView
  className: 'modal fade play-modal'
  template: template
  modalWidthPercent: 90
  id: 'play-achievements-modal'
  #instant: true

  #events:
  #  'change input.select': 'onSelectionChanged'

  constructor: (options) ->
    super options
    #@achievements = new CocoCollection([], {model: Achievement})
    #@achievements.url = '/db/thang.type?view=achievements&project=name,description,components,original,rasterIcon'
    #@supermodel.loadCollection(@achievements, 'achievements')

  getRenderData: (context={}) ->
    context = super(context)
    #context.achievements = @achievements.models
    context

  afterRender: ->
    super()
    return unless @supermodel.finished()
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'game-menu-open', volume: 1

  onHidden: ->
    super()
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'game-menu-close', volume: 1
