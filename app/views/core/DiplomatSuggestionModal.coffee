ModalView = require 'views/core/ModalView'
template = require 'templates/core/diplomat-suggestion'
{me} = require 'core/auth'
forms = require 'core/forms'

module.exports = class DiplomatSuggestionModal extends ModalView
  id: 'diplomat-suggestion-modal'
  template: template

  events:
    'click #subscribe-button': 'subscribeAsDiplomat'

  subscribeAsDiplomat: ->
    me.setEmailSubscription 'diplomatNews', true
    me.patch()
    $('#email_translator').prop('checked', 1)
    @hide()
    return
