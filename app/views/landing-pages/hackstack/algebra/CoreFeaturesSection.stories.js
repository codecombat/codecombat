import CoreFeaturesSection from './CoreFeaturesSection.vue'

export default {
  title: 'Pages/HackStack/Algebra/CoreFeaturesSection',
  component: CoreFeaturesSection,
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { CoreFeaturesSection },
  template: '<CoreFeaturesSection v-bind="$props" />',
})

export const Default = Template.bind({})
Default.args = {}
