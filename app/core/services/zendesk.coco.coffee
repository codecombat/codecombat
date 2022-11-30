loadZendesk = _.once () ->
  return new Promise (accept, reject) ->
    onLoad = ->
      zE('messenger', 'close')
      window.cocoZeLoaded = true
      accept()

    onError = (e) ->
      console.error 'Zendesk failed to initialize:', e
      reject()

    if window.cocoZeLoaded
      return accept()
    zendeskElement = document.createElement('script')
    zendeskElement.id ="ze-snippet"
    zendeskElement.type = 'text/javascript'
    zendeskElement.async = true
    zendeskElement.onerror = onError
    zendeskElement.onload = onLoad
    zendeskElement.src = 'https://static.zdassets.com/ekr/snippet.js?key=ed461a46-91a6-430a-a09c-73c364e02ffe'
    script = document.getElementsByTagName('script')[0]
    script.parentNode.insertBefore(zendeskElement, script)

openZendesk = ->
  try
    zE('messenger', 'open')
  catch e
    console.error('Error trying to open Zendesk widget: ', e)
    return false
  return true

module.exports = {
  loadZendesk
  openZendesk
}
