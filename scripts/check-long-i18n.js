const en = require('../app/locale/en.js').translation
const locale = require('../app/locale/locale')

function checkLang (lang) {
  if (lang === 'en') {
    return
  }
  const language = require(`../app/locale/${lang}.js`).translation
  Object.keys(en).forEach(key => {
    if (!language[key]) {
      // console.log(`Missing key: ${key}`)
      return
    }
    Object.keys(en[key]).forEach(subKey => {
      if (!language[key][subKey]) {
        // console.log(`Missing key: ${key}.${subKey}`)
        return
      }
      const enLength = en[key][subKey].length
      const langLength = language[key][subKey].replace('[AI_TRANSLATION]', '').length
      if (langLength - enLength > 20 && langLength > enLength * 2) {
        console.log(`${lang} Too long:  ${key}.${subKey} - ${langLength} vs ${enLength}`)
      }
    })
  })
}

function main () {
  Object.keys(locale).forEach(lang => {
    checkLang(lang)
  })
}

main()
