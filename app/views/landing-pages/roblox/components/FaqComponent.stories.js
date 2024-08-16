import FaqComponent from './FaqComponent.vue'

export default {
  title: 'Pages/Roblox/Sections/FaqComponent',
  component: FaqComponent
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { FaqComponent },
  template: '<FaqComponent v-bind="$props" />'
})

export const Default = Template.bind({})
Default.args = {
}
