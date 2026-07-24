import CyberFeaturesSection from './CyberFeaturesSection.vue'

export default {
  title: 'Pages/HackStack/Cyber/FeaturesSection',
  component: CyberFeaturesSection,
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { CyberFeaturesSection },
  template: '<CyberFeaturesSection v-bind="$props" />',
})

export const Default = Template.bind({})
Default.args = {}
