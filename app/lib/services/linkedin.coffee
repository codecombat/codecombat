module.exports = initializeLinkedIn = ->
  window.linkedInAsyncInit = ->
    console.log 'Linkedin async init success!'
    Backbone.Mediator.publish 'linkedin-loaded'

  linkedInSnippet =
    ''

  $('head').append(linkedInSnippet)
