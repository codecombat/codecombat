/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let initializeTwitter;
module.exports = (initializeTwitter = () => (function(d, s, id) {
  let js = undefined;
  const fjs = d.getElementsByTagName(s)[0];
  const p = (/^http:/.test(d.location) ? 'http' : 'https');
  if (!d.getElementById(id)) {
    js = d.createElement(s);
    js.id = id;
    js.src = p + '://platform.twitter.com/widgets.js';
    fjs.parentNode.insertBefore(js, fjs);
  }
})(document, 'script', 'twitter-wjs'));
