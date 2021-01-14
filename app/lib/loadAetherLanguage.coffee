# Programmatically constructs a script tag on the page calling the callback
# once the script has loaded.
loadScript = (url, cb) ->
  script = document.createElement('script')
  script.src = url
  if cb
    script.addEventListener('load', cb, false)
  document.head.appendChild(script)

loadEsper = -> new Promise (accept, reject) ->
  if window.esper
    return accept()
  try
    eval("'use strict'; let test = WeakMap && (class Test { *gen(a=7) { yield yield * () => true ; } });")
    #console.log("Modern javascript detected, aw yeah!");
    loadScript("/javascripts/esper.modern.js", accept)
  catch e
    #console.log("Legacy javascript detected, falling back...", e.message);
    loadScript("/javascripts/esper.js", accept)

###
  Loads the language plugin for a chosen language.
  Should be called after esper is loaded.

  Ensures that modern plugins are loaded on modern browsers.
###
loadAetherLanguage = (language) -> new Promise (accept, reject) ->
  loadEsper().then ->

    # Javascript is built into Esper.
    if language in ['javascript']
      return accept()

    if language in ['python', 'coffeescript', 'lua', 'java', 'cpp']
      try
        eval("'use strict'; let test = WeakMap && (class Test { *gen(a=7) { yield yield * () => true ; } });")
        #console.log("Modern plugin chosen for: '#{language}'")
        #loadScript(window.javascriptsPath + "app/vendor/aether-#{language}.modern.js", accept)
        # Workers don't know how to load from window.javascriptsPath, which would offer better cache invalidation, but no point in double load on non-hash-cached version
        loadScript("/javascripts/app/vendor/aether-#{language}.modern.js", accept)
      catch e
        #console.log("Falling back on legacy language plugin for: '#{language}'")
        #loadScript(window.javascriptsPath + "app/vendor/aether-#{language}.js", accept)
        loadScript("/javascripts/app/vendor/aether-#{language}.js", accept)
    else
      reject(new Error("Can't load language '#{language}'"))

module.exports = loadAetherLanguage
