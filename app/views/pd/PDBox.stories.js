import PDBox from './PDBox.vue'

export default {
  title: 'Pages/PD/Box',
  component: PDBox,
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { PDBox },
  template: '<PDBox v-bind="$props" />',
})

export const Primary = Template.bind({})
Primary.args = {
  image: '/images/pages/pd/algorithms.webp'
}
