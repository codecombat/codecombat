import CommunityLoves from './CommunityLoves.vue'

export default {
  title: 'Pages/Roblox/Sections/CommunityLoves',
  component: CommunityLoves
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { CommunityLoves },
  template: '<CommunityLoves v-bind="$props" />'
})

export const Default = Template.bind({})
