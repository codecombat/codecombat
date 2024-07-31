import LoadingSpinner from './LoadingSpinner.vue'

export default {
  title: 'Elements/LoadingSpinner',
  component: LoadingSpinner,
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { LoadingSpinner },
  template: '<LoadingSpinner v-bind="$props" />'
})

export const Default = Template.bind({})
Default.args = {

}
