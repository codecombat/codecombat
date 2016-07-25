ModalView = require 'views/core/ModalView'

module.exports = class GameDevVictoryModal extends ModalView
  id: 'game-dev-victory-modal'
  template: require 'templates/play/level/modal/game-dev-victory-modal'
  
  events:
    'click #replay-game-btn': 'onClickReplayButton'
    'click #copy-url-btn': 'onClickCopyURLButton'
  
  initialize: ({@shareURL}) ->

  onClickReplayButton: ->
    @trigger 'replay'

  onClickCopyURLButton: ->
    @$('#copy-url-input').val(@shareURL).select()
    @tryCopy()
