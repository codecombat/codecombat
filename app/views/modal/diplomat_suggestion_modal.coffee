View = require 'views/kinds/ModalView'
template = require 'templates/modal/diplomat_suggestion'
{me} = require('lib/auth')
forms = require('lib/forms')

module.exports = class DiplomatSuggestionView extends View
  id: "diplomat-suggestion-modal"
  template: template

  events:
    "click #subscribe-button": "subscribeAsDiplomat"

  subscribeAsDiplomat: ->
    me.setEmailSubscription 'diplomatNews', true
    me.patch()
    $("#email_translator").prop("checked", 1)
    @hide()
    return
