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
  title: 'Example box title',
  blurb: 'Example box blurb text goes here. This is a short description of the box contents. It should be a few sentences long.',
  image: '/images/pages/pd/algorithms.webp'
}
