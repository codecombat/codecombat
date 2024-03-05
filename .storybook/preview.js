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
    },
  },
};

global.$ = window.$ = global.jQuery = window.jQuery = require('jquery');

import '../app/app.sass'

import(/* webpackChunkName: "UsFont" */ 'app/styles/common/fontUS.sass');

export const decorators = [
  (storyFn, context) => {
    // Set the CSS variable
    fetch(`/product-update?product=${context.globals.product}`);
    return storyFn();
  },
];