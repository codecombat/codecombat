import ModuleStructureSection from './ModuleStructureSection.vue'

export default {
  title: 'Pages/HackStack/Algebra/ModuleStructureSection',
  component: ModuleStructureSection,
}

const Template = (args, { argTypes }) => ({
  components: { ModuleStructureSection },
  props: Object.keys(argTypes),
  template: '<ModuleStructureSection v-bind="$props" />',
})

export const Default = Template.bind({})
Default.args = {}
