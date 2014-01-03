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
    currentSubscriptions = me.get("emailSubscriptions")
    me.set("emailSubscriptions", currentSubscriptions.concat ["translator"]) if "translator" not in currentSubscriptions
    me.save()
    $("#email_translator").attr("checked", 1)
    @hide()
    return
