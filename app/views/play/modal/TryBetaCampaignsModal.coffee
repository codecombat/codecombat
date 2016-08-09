ModalView = require 'views/core/ModalView'

module.exports = class TryBetaCampaignsModal extends ModalView
  id: 'try-beta-campaigns-modal'
  template: require 'templates/play/modal/try-beta-campaigns-modal'

  events:
    'click .yes-btn': 'onClickYes'
    'click .no-btn': 'onClickNo'

  initialize: (options) ->
    @displayText = options.displayText ? prompt: 'Try new levels under development?', yes: 'yes', no: 'no'
    @yesRoute = options.yesRoute
    @noRoute = options.noRoute

  onClickYes: (e) -> @navToRoute @yesRoute

  onClickNo: (e) -> @navToRoute @noRoute

  navToRoute: (route) ->
    return @hide() unless route
    Backbone.Mediator.publish 'router:navigate', {route}
