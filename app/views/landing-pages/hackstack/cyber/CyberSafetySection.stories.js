import CyberSafetySection from './CyberSafetySection.vue'

export default {
  title: 'Pages/HackStack/Cyber/SafetySection',
  component: CyberSafetySection,
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { CyberSafetySection },
  template: '<CyberSafetySection v-bind="$props" />',
})

export const Default = Template.bind({})
Default.args = {}
