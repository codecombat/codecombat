import CyberPathwaysSection from './CyberPathwaysSection.vue'

export default {
  title: 'Pages/HackStack/Cyber/PathwaysSection',
  component: CyberPathwaysSection,
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { CyberPathwaysSection },
  template: '<CyberPathwaysSection v-bind="$props" />',
})

export const Default = Template.bind({})
Default.args = {}
