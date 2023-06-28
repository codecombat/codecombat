window.moment = require('moment')
const VueMoment = require('vue-moment')
Vue.use(VueMoment.default)

function setUpMoment () {
  const { me } = require('core/auth')
  const setMomentLanguage = function (lang) {
    lang = {
      'zh-HANS': 'zh-cn',
      'zh-HANT': 'zh-tw'
    }[lang] || lang
    return window.moment.locale(lang.toLowerCase())
  }
  // TODO: this relies on moment having all languages baked in, which is a performance hit; should switch to loading the language module we need on demand.
  setMomentLanguage(me.get('preferredLanguage', true))
  return me.on('change:preferredLanguage', me => setMomentLanguage(me.get('preferredLanguage', true)))
}

setUpMoment() // Set up i18n for moment
