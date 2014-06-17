module.exports = initializeLinkedIn = ->
  window.linkedInAsyncInit = ->
    Backbone.Mediator.publish 'linkedin-loaded'

  linkedInSnippet =
    '<script type="text/javascript" async src="http://platform.linkedin.com/in.js">
      api_key: 75v8mv4ictvmx6
      onLoad: linkedInAsyncInit
      authorize: true
    </script>'

  $('head').append(linkedInSnippet)
