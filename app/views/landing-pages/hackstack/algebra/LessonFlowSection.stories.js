import LessonFlowSection from './LessonFlowSection.vue'

export default {
  title: 'Pages/HackStack/Algebra/LessonFlowSection',
  component: LessonFlowSection,
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { LessonFlowSection },
  template: '<LessonFlowSection v-bind="$props" />',
})

export const Default = Template.bind({})
Default.args = {}
