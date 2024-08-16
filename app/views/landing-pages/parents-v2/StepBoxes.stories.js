import StepBoxes from './StepBoxes.vue'

export default {
  title: 'Parents/StepBoxes',
  component: StepBoxes,
}

const Template = (args, { argTypes }) => ({
  components: { StepBoxes },
  props: Object.keys(argTypes),
  template: `
    <StepBoxes v-bind="$props" />
  `,
})

export const Default = Template.bind({})
Default.args = {
}