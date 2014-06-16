module.exports = initializeOlark = ->
  window.olark or ((c) -> #<![CDATA[
    f = window
    d = document
    l = (if f.location.protocol is "https:" then "https:" else "http:")
    z = c.name
    r = "load"
    nt = ->
      s = ->
        a.P r
        f[z] r
        return
      f[z] = ->
        (a.s = a.s or []).push arguments
        return

      a = f[z]._ = {}
      q = c.methods.length
      while q--
        ((n) ->
          f[z][n] = ->
            f[z] "call", n, arguments
            return

          return
        ) c.methods[q]
      a.l = c.loader
      a.i = nt
      a.p = 0: +new Date
      a.P = (u) ->
        a.p[u] = new Date - a.p[0]
        return

      (if f.addEventListener then f.addEventListener(r, s, false) else f.attachEvent("on" + r, s))
      ld = ->
        p = (hd) ->
          hd = "head"
          [
            "<"
            hd
            "></"
            hd
            "><"
            i
            " onl" + "oad=\"var d="
            g
            ";d.getElementsByTagName('head')[0]."
            j
            "(d."
            h
            "('script'))."
            k
            "='"
            l
            "//"
            a.l
            "'"
            "\""
            "></"
            i
            ">"
          ].join ""
        i = "body"
        m = d[i]
        return setTimeout(ld, 100)  unless m
        a.P 1
        j = "appendChild"
        h = "createElement"
        k = "src"
        n = d[h]("div")
        v = n[j](d[h](z))
        b = d[h]("iframe")
        g = "document"
        e = "domain"
        o = undefined
        n.style.display = "none"
        m.insertBefore(n, m.firstChild).id = z
        b.frameBorder = "0"
        b.id = z + "-loader"
        b.src = "javascript:false"  if /MSIE[ ]+6/.test(navigator.userAgent)
        b.allowTransparency = "true"
        v[j] b
        try
          b.contentWindow[g].open()
        catch w
          c[e] = d[e]
          o = "javascript:var d=" + g + ".open();d.domain='" + d.domain + "';"
          b[k] = o + "void(0);"
        try
          t = b.contentWindow[g]
          t.write p()
          t.close()
        catch x
          b[k] = o + "d.write(\"" + p().replace(/"/g, String.fromCharCode(92) + "\"") + "\");d.close();"
        a.P 2
        return

      ld()
      return

    nt()
    return
  )(
    loader: "static.olark.com/jsclient/loader0.js"
    name: "olark"
    methods: [
      "configure"
      "extend"
      "declare"
      "identify"
    ]
  )

  # custom configuration goes here (www.olark.com/documentation) 
  olark.identify "1451-787-10-5544" #]]>

