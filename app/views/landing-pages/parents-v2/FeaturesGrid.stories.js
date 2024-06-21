import FeaturesGrid from './FeaturesGrid.vue'

export default {
  title: 'Parents/FeaturesGrid',
  component: FeaturesGrid,
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { FeaturesGrid },
  template: '<FeaturesGrid v-bind="$props" />',
})

export const Default = Template.bind({})
Default.args = {
}
