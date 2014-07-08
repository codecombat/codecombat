HomeView = require './home_view'
ModalView = require 'views/kinds/ModalView'
modalTemplate = require 'templates/multiplayer_launch_modal'

module.exports = class MultiplayerLaunchView extends HomeView
  afterInsert: ->
    super()
    @openModalView(new MultiplayerLaunchModal())

class MultiplayerLaunchModal extends ModalView
  template: modalTemplate
  id: 'multiplayer-launch-modal'

  hide: ->
    $('#multiplayer-video').attr('src','')
    super()

  onHidden: ->
    $('#multiplayer-video').attr('src','')
    super()
