ModalView = require 'views/core/ModalView'
template = require 'templates/account/prepaid-redeem-modal'
{me} = require 'core/auth'


module.exports = class PrepaidRedeemModal extends ModalView
  id: 'prepaid-redeem-modal'
  template: template
  closeButton: true

  events:
    'click #redeem' : 'onRedeemClicked'

  constructor: (options) ->
    super options
    @ppc = options.ppc
    hasRedeemed = @ppc.userHasRedeemed(me.get('_id'))
    @redeemedOn = new moment(hasRedeemed).calendar() if hasRedeemed

  getRenderData: ->
    c = super()
    c.ppc = @ppc
    c.redeemedOn = @redeemedOn if @redeemedOn
    c

  onRedeemClicked: ->
    @trigger 'confirm-redeem'
