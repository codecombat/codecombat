/** @type { import('@storybook/vue').Preview } */

import fetch from 'node-fetch';

export const parameters = {
  actions: { argTypesRegex: "^on[A-Z].*" },
  controls: {
    matchers: {
      color: /(background|color)$/i,
      date: /Date$/i,
    },
  },
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
  },
};

global.$ = window.$ = global.jQuery = window.jQuery = require('jquery');

import '../app/app.sass'

import('app/styles/common/fontUS.sass');

import './container.scss'

import Vue from 'vue'


// TODO: make i18n work for all languages & add language selector to toolbar
import i18next from 'i18next';
i18next.init({
  lng: 'en',
  debug: true,
  resources: {
    en: require('app/locale/en')
  }
});
Vue.prototype.$t = (...args) => {
  return i18next.t(...args)
}

const { $themePath } = require('app/core/initialize-themes')
Vue.prototype.$themePath = $themePath

export const decorators = [
  (() => {
    let oldContext = null;

    return (storyFn, context) => {

      const theme = context.globals.theme;
      const style = context.globals.style;

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