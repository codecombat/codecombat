import PCConRoblox from './PCConRoblox.vue'

export default {
  title: 'Pages/Roblox/Sections/PCConRoblox',
  component: PCConRoblox
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { PCConRoblox },
  template: '<PCConRoblox v-bind="$props" />'
})

export const Default = Template.bind({})
