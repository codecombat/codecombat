import ToolsList from './ToolsList.vue'

export default {
  title: 'Pages/Home/ToolsList',
  component: ToolsList
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { ToolsList },
  template: '<tools-list v-bind="$props" />'
})

export const Default = Template.bind({})
Default.args = {
}
