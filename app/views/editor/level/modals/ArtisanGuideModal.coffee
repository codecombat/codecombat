ModalView = require 'views/core/ModalView'
template = require 'templates/editor/level/modal/artisan-guide-modal'

forms = require 'core/forms'
{sendContactMessage} = require 'core/contact'

contactSchema =
  additionalProperties: false
  required: ['creditName', 'levelPurpose', 'levelInspiration', 'levelLocation']
  properties:
    creditName:
      type: 'string'
    levelPurpose:
      type: 'string'
    levelInspiration:
      type: 'string'
    levelLocation:
      type: 'string'

module.exports = class ArtisanGuideModal extends ModalView
  id: 'artisan-guide-modal'
  template: template
  events:
    'click #level-submit': 'levelSubmit'

  constructor: (options) ->
    super options
    @level = options.level
    @options = level: @level.get 'name'
    @render()

  getRenderData: ->
    c = super()
    c.creator = @level.get 'creator'
    c.meID = me.id
    c

  levelSubmit: ->
    @playSound 'menu-button-click'
    forms.clearFormAlerts @$el
    contactMessage = forms.formToObject @$el
    res = tv4.validateMultiple contactMessage, contactSchema
    return forms.applyErrorsToForm @$el, res.errors unless res.valid
    @populateBrowserData contactMessage
    contactMessage = _.merge contactMessage, @options
    contactMessage.country = me.get('country')
    sendContactMessage contactMessage, @$el
    $.post "/db/user/#{me.id}/track/contact_codecombat"

  populateBrowserData: (context) ->
    if $.browser
      context.browser = "#{$.browser.platform} #{$.browser.name} #{$.browser.versionNumber}"
    context.screenSize = "#{screen?.width ? $(window).width()} x #{screen?.height ? $(window).height()}"
    context.screenshotURL = @screenshotURL
