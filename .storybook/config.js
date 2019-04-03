import { configure } from '@storybook/vue';

// set the global Vue for using it in the vue components
import Vue from 'vue'
window.Vue = Vue

// automatically import all files ending in *.stories.js
const req = require.context('../stories', true, /\.stories\.js$/);
function loadStories() {
  req.keys().forEach(filename => req(filename));
}

configure(loadStories, module);
