// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// eslint-disable-next-line no-unused-vars
let initializeFilepicker
// eslint-disable-next-line no-unused-vars
module.exports = (initializeFilepicker = () => (function (a) {
  if (window.filepicker) { return }
  const b = a.createElement('script')
  b.type = 'text/javascript'
  b.async = !0
  b.src = ((a.location.protocol === 'https:' ? 'https:' : 'http:')) + '//api.filepicker.io/v1/filepicker.js'
  const c = a.getElementsByTagName('script')[0]
  c.parentNode.insertBefore(b, c)
  const d = {}
  d._queue = []
  const e = 'pick,pickMultiple,pickAndStore,read,write,writeUrl,export,convert,store,storeUrl,remove,stat,setKey,constructWidget,makeDropPane'.split(',')
  const f = (a, b) => function () {
    b.push([
      a,
      arguments
    ])
  }

  let g = 0

  while (g < e.length) {
    d[e[g]] = f(e[g], d._queue)
    g++
  }
  d.setKey('AvlkNoldcTOU4PvKi2Xm7z')
  window.filepicker = d
})(document))
