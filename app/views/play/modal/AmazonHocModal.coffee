require('app/styles/play/modal/amazon-hoc-modal.sass')
ModalView = require('views/core/ModalView')
template = require 'templates/play/modal/amazon-hoc-modal'

module.exports = class AmazonHocModal extends ModalView
  template: template
  id: 'amazon-hoc-modal'

  events:
    'click #close-modal': 'hide'
    'mouseup #aws-educate-link': 'onClickAwsEducateLink' # mouseup detects middle click as well
    'mouseup #aws-alexa-link': 'onClickAwsAlexaLink'
    'mouseup #aws-future-eng-link': 'onClickAwsFutureEngLink'
    'click #continue-button': 'onClickContinue'
  
  onClickAwsEducateLink: ->
    window.tracker?.trackEvent 'Click Amazon link', label: 'aws-educate-link'
  
  onClickAwsAlexaLink: ->
    window.tracker?.trackEvent 'Click Amazon link', label: 'aws-alexa-link'
    
  onClickAwsFutureEngLink: ->
    window.tracker?.trackEvent 'Click Amazon link', label: 'aws-future-eng-link'

  onClickContinue: ->
    navigateOptions =
      trigger: true
      replace: true
    navigationEvent = route: '/play/game-dev-hoc?hour_of_code=true', viewArgs: [navigateOptions]
    Backbone.Mediator.publish 'router:navigate', navigationEvent
