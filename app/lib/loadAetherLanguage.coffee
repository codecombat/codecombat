loadScript = (url, cb) ->
  script = document.createElement('script')
  script.src = url
  if cb
    script.addEventListener('load', cb, false)
  document.head.appendChild(script)

loadAetherLanguage = (language) -> new Promise (accept, reject) ->
  if language in ['javascript', 'python', 'coffeescript', 'lua', 'java']
    loadScript(window.javascriptsPath + "app/vendor/aether-#{language}.js", accept)
  else
    reject(new Error("Can't load language '#{language}'"))

module.exports = loadAetherLanguage
