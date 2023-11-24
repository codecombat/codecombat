// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// eslint-disable-next-line promise/param-names
const loadZendesk = _.once(() => new Promise(function (accept, reject) {
  const onLoad = function () {
    // zE is the global variable created by the script. We never want the floating button to show, so we:
    // 1: Hide it right away
    // 2: Bind showing it to opening it
    // 3: Bind closing it to hiding it
    zE('webWidget', 'hide')
    zE('webWidget:on', 'userEvent', function (event) {
      if (event.action === 'Contact Form Shown') {
        return zE('webWidget', 'open')
      }
    })
    zE('webWidget:on', 'close', () => zE('webWidget', 'hide'))
    zE('webWidget', 'updateSettings', {
      webWidget: {
        offset: { horizontal: '100px', vertical: '20px' }
      }
    })
    return accept()
  }

  const onError = function (e) {
    console.error('Zendesk failed to initialize:', e)
    return reject(new Error('Zendesk failed to initialize'))
  }

  const zendeskElement = document.createElement('script')
  zendeskElement.id = 'ze-snippet'
  zendeskElement.type = 'text/javascript'
  zendeskElement.async = true
  zendeskElement.onerror = onError
  zendeskElement.onload = onLoad
  zendeskElement.src = 'https://static.zdassets.com/ekr/snippet.js?key=ed461a46-91a6-430a-a09c-73c364e02ffe'
  const script = document.getElementsByTagName('script')[0]
  return script.parentNode.insertBefore(zendeskElement, script)
}))

const openZendesk = function () {
  const prefillOptions = {}
  if (me.get('email')) { prefillOptions.email = { value: me.get('email') } }
  if (me.get('firstName')) { prefillOptions.name = { value: me.broadName() } }

  try {
    if (_.size(prefillOptions)) {
      zE('webWidget', 'prefill', prefillOptions)
    }
    zE('webWidget', 'open')
    zE('webWidget', 'show')
  } catch (e) {
    console.error('Error trying to open Zendesk widget: ', e)
    return false
  }
  return true
}

module.exports = {
  loadZendesk,
  openZendesk
}
