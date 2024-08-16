import AccessGuidebook from './AccessGuidebook.vue'

export default {
  title: 'Pages/Roblox/Sections/AccessGuidebook',
  component: AccessGuidebook
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { AccessGuidebook },
  template: '<AccessGuidebook v-bind="$props" />'
})

export const Default = Template.bind({})
