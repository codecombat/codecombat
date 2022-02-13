require('app/styles/play/level/modal/game-dev-victory-modal.sass')
ModalView = require 'views/core/ModalView'

category = 'Play GameDev Level'

module.exports = class GameDevVictoryModal extends ModalView
  id: 'game-dev-victory-modal'
  template: require 'templates/play/level/modal/game-dev-victory-modal'
  
  events:
    'click #replay-game-btn': 'onClickReplayButton'
    'click #copy-url-btn': 'onClickCopyURLButton'
    'click #play-more-codecombat-btn': 'onClickPlayMoreCodeCombatButton'
  
  initialize: ({@shareURL, @eventProperties, @victoryMessage}) ->

  getVictoryMessage: ->
    @victoryMessage ? "You beat the game!"

  onClickReplayButton: ->
    @trigger 'replay'

  onClickCopyURLButton: ->
    @$('#copy-url-input').val(@shareURL).select()
    @tryCopy()
    window.tracker?.trackEvent('Play GameDev Victory Modal - Copy URL', @eventProperties, ['Mixpanel'])

  onClickPlayMoreCodeCombatButton: ->
    window.tracker?.trackEvent('Play GameDev Victory Modal - Click Play More CodeCombat', @eventProperties, ['Mixpanel'])
