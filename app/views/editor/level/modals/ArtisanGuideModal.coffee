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

  initialize: (options) ->
    @level = options.level
    @options = 
      level:@level.get('name')
      levelSlug:@level.get('slug')

  levelSubmit: ->
    @playSound 'menu-button-click'
    forms.clearFormAlerts @$el
    results = forms.formToObject @$el
    res = tv4.validateMultiple results, contactSchema
    return forms.applyErrorsToForm @$el, res.errors unless res.valid
    contactMessage = {message:"""User Name: #{results.creditName}
      Level: <a href="http://codecombat.com/editor/level/#{@options.levelSlug}">#{@options.level}</a>
      Purpose: #{results.levelPurpose}
      Inspiration: #{results.levelInspiration}
      Location: #{results.levelLocation}"""}
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

  hasOwnership: ->
    if @level.getOwner() is me.id
      return true
    return false