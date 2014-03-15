{backboneFailure, genericFailure} = require 'lib/errors'
View = require 'views/kinds/RootView'
template = require 'templates/admin'
storage = require 'lib/storage'

module.exports = class AdminView extends View
  id: "admin-view"
  template: template
  
  events:
    'click #enter-espionage-mode': 'enterEspionageMode'
    
  enterEspionageMode: ->
    userEmail = $("#user-email").val().toLowerCase()
    username = $("#user-username").val().toLowerCase()
    
    userIdentifier = userEmail || username
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
    storage.save('whoami',model)
    window.location.reload()

  espionageFailure: (jqxhr, status,error)->
    console.log "There was an error entering espionage mode: #{error}"
    
    
