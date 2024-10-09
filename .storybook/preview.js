/** @type { import('@storybook/vue').Preview } */

import fetch from 'node-fetch';
const VTooltip = require('v-tooltip')


export const parameters = {
  actions: { argTypesRegex: "^on[A-Z].*" },
  controls: {
    matchers: {
      color: /(background|color)$/i,
      date: /Date$/i,
    },
  },
}

const i18next = require('i18next')
const jqueryI18next = require('jquery-i18next')
const AIPostProcessor = require('app/lib/i18n/AIPostProcessor')
const resources = {
  en: require('app/locale/en'),
  ar: require('app/locale/ar'),
  az: require('app/locale/az'),
  bg: require('app/locale/bg'),
  ca: require('app/locale/ca'),
  cs: require('app/locale/cs'),
  da: require('app/locale/da'),
  de: require('app/locale/de-DE'),
  el: require('app/locale/el'),
  es: require('app/locale/es-ES'),
  et: require('app/locale/et'),
  fa: require('app/locale/fa'),
  fi: require('app/locale/fi'),
  fr: require('app/locale/fr'),
  gl: require('app/locale/gl'),
  he: require('app/locale/he'),
  hi: require('app/locale/hi'),
  hr: require('app/locale/hr'),
  hu: require('app/locale/hu'),
  id: require('app/locale/id'),
  it: require('app/locale/it'),
  ja: require('app/locale/ja'),
  kk: require('app/locale/kk'),
  ko: require('app/locale/ko'),
  lt: require('app/locale/lt'),
  lv: require('app/locale/lv'),
  mi: require('app/locale/mi'),
  mk: require('app/locale/mk-MK'),
  mn: require('app/locale/mn'),
  ms: require('app/locale/ms'),
  my: require('app/locale/my'),
  nb: require('app/locale/nb'),
  nl: require('app/locale/nl'),
  nn: require('app/locale/nn'),
  pl: require('app/locale/pl'),
  pt: require('app/locale/pt-PT'),
  ro: require('app/locale/ro'),
  ru: require('app/locale/ru'),
  sk: require('app/locale/sk'),
  sl: require('app/locale/sl'),
  sr: require('app/locale/sr'),
  sv: require('app/locale/sv'),
  th: require('app/locale/th'),
  tr: require('app/locale/tr'),
  uk: require('app/locale/uk'),
  ur: require('app/locale/ur'),
  uz: require('app/locale/uz'),
  vi: require('app/locale/vi'),
  'zh-HANS': require('app/locale/zh-HANS'),
  'zh-HANT': require('app/locale/zh-HANT'),
  'zh-WUU-HANS': require('app/locale/zh-WUU-HANS'),
  'zh-WUU-HANT': require('app/locale/zh-WUU-HANT'),
  'es-419': require('app/locale/es-419'),
  'de-AT': require('app/locale/de-AT'),
  'de-CH': require('app/locale/de-CH'),
  'nl-BE': require('app/locale/nl-BE'),
  'pt-BR': require('app/locale/pt-BR'),
  'pt-PT': require('app/locale/pt-PT'),
  'en-GB': require('app/locale/en-GB'),
  'en-US': require('app/locale/en-US'),
  'rot13': require('app/locale/rot13'),
  'haw': require('app/locale/haw'),
};

export const globalTypes = {
  product: {
    name: 'Product',
    description: 'Product selection',
    defaultValue: 'codecombat',
    toolbar: {
      icon: 'circlehollow',
      items: ['codecombat', 'ozaria'],
      dynamicTitle: true
    },
  },
  langs: {
    name: 'Lang',
    defaultValue: 'en',
    toolbar: {
      icon: 'globe',
      items: Object.entries(resources).map(([key, value]) => {
        return {
          value: key,
          title: value.nativeDescription,
        }
      }),
    },
  },
  theme: {
    name: 'Theme',
    description: 'Global theme for components',
    defaultValue: 'blue-theme',
    toolbar: {
      icon: 'paintbrush',
      items: [
        { value: 'blue-theme', title: 'Blue' },
        { value: 'teal-theme', title: 'Teal' },
      ],
      dynamicTitle: true
    },
  },
  style: {
    name: 'Style',
    description: 'Global style',
    defaultValue: 'style-flat',
    toolbar: {
      icon: 'paintbrush',
      items: [
        { value: 'style-flat', title: 'style-flat' },
        { value: '', title: 'none' },
      ],
      dynamicTitle: true
    },
  }
};

global.$ = window.$ = global.jQuery = window.jQuery = require('jquery');

import '../app/app.sass'

import './styles.js'

import(/* webpackChunkName: "UsFont" */ 'app/styles/common/fontUS.sass');

let i18nextInstance, globalLang
window.i18n = (i18nextInstance = i18next.default.createInstance({
  lng: 'en',
  fallbackLng: 'en',
  resources,
  interpolation: { prefix: '__', suffix: '__' },
  debug: true
}))

i18nextInstance.use(new AIPostProcessor()).init({
  postProcess: ['AIPostProcessor']
})
// eslint-disable-next-line no-proto
i18nextInstance.services.languageUtils.__proto__.formatLanguageCode = code => code // Hack so that it doesn't turn zh-HANS into zh-Hans

jqueryI18next.init(i18nextInstance, $, {
  tName: 't', // --> appends $.t = i18next.t
  i18nName: 'i18n', // --> appends $.i18n = i18next
  handleName: 'i18n', // --> appends $(selector).i18n(opts)
  selectorAttr: 'data-i18n', // selector for translating elements
  targetAttr: 'i18n-target', // data-() attribute to grab target element to translate (if different than itself)
  optionsAttr: 'i18n-options', // data-() attribute that contains options, will load/set if useOptionsAttr = true
  useOptionsAttr: true, // see optionsAttr
  parseDefaultValueFromContent: true
}
                  ) // parses default values from content ele.val or ele.text

import Vue from 'vue'
import { i18n } from 'core/utils'
import _ from 'lodash'

window.Vue = Vue

window.me = {
  get() {
    return 'test value'
  },
  getSubscriptionLevel() {
    return 'free'
  }
}

window._ = _
window._.string = require('underscore.string')

window.moment = require('moment')

const VueI18Next = {
  install (Vue, options) {
    /*  determine options  */

    let opts = {}
    Vue.util.extend(opts, options)

    /*  expose a global API method  */

    Vue.t = function (key, options) {
      opts = {}
      let lng = globalLang || 'en'
      if ((typeof lng === 'string') && (lng !== '')) {
        opts.lng = lng
      }
      Vue.util.extend(opts, options)
      return $.i18n.t(key, opts)
    }

    /*  expose a local API method  */

    Vue.prototype.$t = function (key, options) {
      opts = {}
      let lng = globalLang || 'en'
      console.log('translations', globalLang, lng)
      if ((typeof lng === 'string') && (lng !== '')) {
        opts.lng = lng
      }
      const ns = this.$options.i18nextNamespace
      if ((typeof ns === 'string') && (ns !== '')) {
        opts.ns = ns
      }
      Vue.util.extend(opts, options)
      return $.i18n.t(key, opts)
    }

    Vue.prototype.$dbt = function (source, key, options) {
      if (options == null) { options = {} }
      return i18n(source, key, options.language, options.fallback)
    }
  }
}
Vue.use(VueI18Next)
Vue.use(VTooltip.default)


const { $themePath } = require('app/core/initialize-themes')
Vue.prototype.$themePath = $themePath

import api from 'core/api'


export const decorators = [
  (() => {
    let oldContext = null;

    return (storyFn, context) => {

      api.trialRequests = {getOwn: () => Promise.resolve({ data: 'mockedData' })};

      const theme = context.globals.theme;
      const style = context.globals.style;
      const lang = context.globals.langs;
      $.i18n.changeLanguage(lang, (err, t) => {
        if (err) return console.log('something went wrong loading', err);
        globalLang = lang
      })

      // If the product has changed, fetch the new product
      if (!oldContext || oldContext.globals.product !== context.globals.product) {
        fetch(`/product-update?product=${context.globals.product}`);
      }

      document.body.classList.remove(
        'blue-theme', 'teal-theme', 'dark-theme',
        'style-flat'
      );
      document.body.classList.add(theme);

      if (style) {
        document.body.classList.add(style);
      }

      oldContext = context;

      return storyFn();
    };
  })(),
];