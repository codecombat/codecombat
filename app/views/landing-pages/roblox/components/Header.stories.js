import Header from './Header.vue'

export default {
  title: 'Pages/Roblox/Sections/Header',
  component: Header
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { Header },
  template: '<Header v-bind="$props" />'
})

export const Default = Template.bind({})
Default.args = {
}
