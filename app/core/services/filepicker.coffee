module.exports = initializeFilepicker = ->
  ((a) ->
    return if window.filepicker
    b = a.createElement('script')
    b.type = 'text/javascript'
    b.async = not 0
    b.src = ((if 'https:' is a.location.protocol then 'https:' else 'http:')) + '//api.filepicker.io/v1/filepicker.js'
    c = a.getElementsByTagName('script')[0]
    c.parentNode.insertBefore b, c
    d = {}
    d._queue = []
    e = 'pick,pickMultiple,pickAndStore,read,write,writeUrl,export,convert,store,storeUrl,remove,stat,setKey,constructWidget,makeDropPane'.split(',')
    f = (a, b) ->
      ->
        b.push [
          a
          arguments
        ]
        return

    g = 0

    while g < e.length
      d[e[g]] = f(e[g], d._queue)
      g++
    d.setKey('AvlkNoldcTOU4PvKi2Xm7z')
    window.filepicker = d
    return
  ) document
