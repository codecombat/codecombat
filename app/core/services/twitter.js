// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let initializeTwitter
// eslint-disable-next-line no-unused-vars
module.exports = (initializeTwitter = () => (function (d, s, id) {
  let js
  const fjs = d.getElementsByTagName(s)[0]
  const p = (/^http:/.test(d.location) ? 'http' : 'https')
  if (!d.getElementById(id)) {
    js = d.createElement(s)
    js.id = id
    js.src = p + '://platform.twitter.com/widgets.js'
    fjs.parentNode.insertBefore(js, fjs)
  }
})(document, 'script', 'twitter-wjs'))
