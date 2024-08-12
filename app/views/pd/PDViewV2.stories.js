import PDViewV2 from './PDViewV2.vue'

export default {
  title: 'Pages/PD',
  component: PDViewV2,
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { PDViewV2 },
  template: '<PDViewV2 v-bind="$props" />',
})

export const Default = Template.bind({})
Default.args = {}
