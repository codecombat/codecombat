ModalView = require 'views/core/ModalView'

category = 'Play GameDev Level'

module.exports = class GameDevVictoryModal extends ModalView
  id: 'game-dev-victory-modal'
  template: require 'templates/play/level/modal/game-dev-victory-modal'
  
  events:
    'click #replay-game-btn': 'onClickReplayButton'
    'click #copy-url-btn': 'onClickCopyURLButton'
    'click #play-more-codecombat-btn': 'onClickPlayMoreCodeCombatButton'
  
  initialize: ({@shareURL}) ->

  onClickReplayButton: ->
    @trigger 'replay'

  onClickCopyURLButton: ->
    @$('#copy-url-input').val(@shareURL).select()
    @tryCopy()
    window.tracker?.trackEvent('Copy URL', { category })

  onClickPlayMoreCodeCombatButton: ->
    window.tracker?.trackEvent('Play More CodeCombat', { category })
