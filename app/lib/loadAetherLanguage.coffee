# Programmatically constructs a script tag on the page calling the callback
# once the script has loaded.
loadScript = (url, cb) ->
  script = document.createElement('script')
  script.src = url
  if cb
    script.addEventListener('load', cb, false)
  document.head.appendChild(script)

###
  Loads the language plugin for a chosen language.
  Should be called after esper is loaded.

  Ensures that modern plugins are loaded on modern browsers.
###
loadAetherLanguage = (language) -> new Promise (accept, reject) ->
  # Javascript is build into esper.
  if language in ['javascript']
    return accept()

  if language in ['python', 'coffeescript', 'lua', 'java']
    try
      eval("'use strict'; let test = WeakMap && (class Test { *gen(a=7) { yield yield * () => true ; } });")
      console.log("Modern plugin chosen for: '#{language}'")
      loadScript(window.javascriptsPath + "app/vendor/aether-#{language}.modern.js", accept)
    catch e
      console.log("Falling back on legacy language plugin for: '#{language}'")
      loadScript(window.javascriptsPath + "app/vendor/aether-#{language}.js", accept)
  else
    reject(new Error("Can't load language '#{language}'"))

module.exports = loadAetherLanguage
