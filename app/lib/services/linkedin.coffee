module.exports = initializeLinkedIn = ->
  window.linkedInAsyncInit = ->
    #console.log 'Linkedin async init success!'
    Backbone.Mediator.publish 'auth:linkedin-api-loaded', {}

  linkedInSnippet =
    ''

  $('head').append(linkedInSnippet)
