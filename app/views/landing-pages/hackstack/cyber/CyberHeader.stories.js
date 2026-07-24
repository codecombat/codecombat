import CyberHeader from './CyberHeader.vue'

export default {
  title: 'Pages/HackStack/Cyber/Header',
  component: CyberHeader,
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { CyberHeader },
  template: '<CyberHeader v-bind="$props" />',
})

export const Default = Template.bind({})
Default.args = {}
