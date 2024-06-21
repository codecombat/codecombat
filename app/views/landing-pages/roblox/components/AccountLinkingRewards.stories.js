import AccountLinkingRewards from './AccountLinkingRewards.vue'

export default {
  title: 'Pages/Roblox/Sections/AccountLinkingRewards',
  component: AccountLinkingRewards
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { AccountLinkingRewards },
  template: '<AccountLinkingRewards v-bind="$props" />'
})

export const Default = Template.bind({})
Default.args = {
}
