import TrustedStandardsSection from './TrustedStandardsSection.vue'

export default {
  title: 'Pages/HackStack/Algebra/TrustedStandardsSection',
  component: TrustedStandardsSection,
}

const Template = (args, { argTypes }) => ({
  components: { TrustedStandardsSection },
  props: Object.keys(argTypes),
  template: '<TrustedStandardsSection v-bind="$props" />',
})

export const Default = Template.bind({})
Default.args = {}
