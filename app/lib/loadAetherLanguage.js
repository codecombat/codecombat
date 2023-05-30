// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// Programmatically constructs a script tag on the page calling the callback
// once the script has loaded.
const loadScript = function(url, cb) {
  const script = document.createElement('script');
  script.src = url;
  if (cb) {
    script.addEventListener('load', cb, false);
  }
  return document.head.appendChild(script);
};

const loadEsper = () => new Promise(function(accept, reject) {
  if (window.esper) {
    return accept();
  }
  try {
    eval("'use strict'; let test = WeakMap && (class Test { *gen(a=7) { yield yield * () => true ; } });");
    //console.log("Modern javascript detected, aw yeah!");
    return loadScript("/javascripts/esper.modern.js", accept);
  } catch (e) {
    //console.log("Legacy javascript detected, falling back...", e.message);
    return loadScript("/javascripts/esper.js", accept);
  }
});

/*
  Loads the language plugin for a chosen language.
  Should be called after esper is loaded.

  Ensures that modern plugins are loaded on modern browsers.
*/
const loadAetherLanguage = language => new Promise((accept, reject) => loadEsper().then(function() {

  // Javascript is built into Esper.
  if (['javascript'].includes(language)) {
    return accept();
  }

  if (['python', 'coffeescript', 'lua', 'java', 'cpp'].includes(language)) {
    try {
      eval("'use strict'; let test = WeakMap && (class Test { *gen(a=7) { yield yield * () => true ; } });");
      //console.log("Modern plugin chosen for: '#{language}'")
      //loadScript(window.javascriptsPath + "app/vendor/aether-#{language}.modern.js", accept)
      // Workers don't know how to load from window.javascriptsPath, which would offer better cache invalidation, but no point in double load on non-hash-cached version
      return loadScript(`/javascripts/app/vendor/aether-${language}.modern.js`, accept);
    } catch (e) {
      //console.log("Falling back on legacy language plugin for: '#{language}'")
      //loadScript(window.javascriptsPath + "app/vendor/aether-#{language}.js", accept)
      return loadScript(`/javascripts/app/vendor/aether-${language}.js`, accept);
    }
  } else {
    return reject(new Error(`Can't load language '${language}'`));
  }
}));

module.exports = loadAetherLanguage;
