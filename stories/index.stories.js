/* eslint-disable react/react-in-jsx-scope, react/no-this-in-sfc */
import { storiesOf } from '@storybook/vue'
import { action } from '@storybook/addon-actions'
import { linkTo } from '@storybook/addon-links'

import MyButton from './MyButton'
import Welcome from './Welcome'
import PieChart from '../app/core/components/PieComponent.vue'

storiesOf('Welcome', module).add('to Storybook', () => ({
  components: { Welcome },
  template: '<welcome :showApp="action" />',
  methods: { action: linkTo('Button') }
}))

storiesOf('Button', module)
  .add('with text', () => ({
    components: { MyButton },
    template: '<my-button @click="action">Hello Button</my-button>',
    methods: { action: action('clicked') }
  }))
  .add('with some emoji', () => ({
    components: { MyButton },
    template: '<my-button @click="action">😀 😎 👍 💯</my-button>',
    methods: { action: action('clicked') }
  }))

storiesOf('PieComponent', module)
  .add('default', () => ({
    components: { PieChart },
    // To pass a number you must use `v-bind:` or `:`.
    template: `<pie-chart></pie-chart>`
  }))
  .add('with a ratio', () => ({
    components: { PieChart },
    template: `<pie-chart
      :ratio="0.90"
      :stroke-width="10"
      :border-stroke-width="0.2"
      color="#FE7F9C"
      :opacity="1"
    ></pie-chart>`
  }))
  .add('with a percentage', () => ({
    components: { PieChart },
    template: `<pie-chart
      :percent="2"
      :stroke-width="10"
      :border-stroke-width="0.2"
      color="#20572B"
      :opacity="1"
    ></pie-chart>`
  }))
