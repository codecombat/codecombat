{backboneFailure, genericFailure} = require 'lib/errors'
View = require 'views/kinds/RootView'
template = require 'templates/admin'

module.exports = class AdminView extends View
  id: "admin-view"
  template: template

  events:
    'click #enter-espionage-mode': 'enterEspionageMode'
    'click #increment-button': 'incrementUserAttribute'

  enterEspionageMode: ->
    userEmail = $("#user-email").val().toLowerCase()
    username = $("#user-username").val().toLowerCase()

    postData =
      usernameLower: username
      emailLower: userEmail

    $.ajax
      type: "POST",
      url: "/auth/spy"
      data: postData
      success: @espionageSuccess
      error: @espionageFailure

  espionageSuccess: (model) ->
    window.location.reload()

  espionageFailure: (jqxhr, status,error)->
    console.log "There was an error entering espionage mode: #{error}"

  incrementUserAttribute: (e) ->
    val = $('#increment-field').val()
    me.set(val, me.get(val) + 1)
    me.save()
