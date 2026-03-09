import PageHackstackAlgebra from './PageHackstackAlgebra.vue'

export default {
  title: 'Pages/HackStack/Algebra/Page',
  component: PageHackstackAlgebra,
  parameters: {
    layout: 'fullscreen',
  },
}

const Template = (args, { argTypes }) => ({
  components: { PageHackstackAlgebra },
  props: Object.keys(argTypes),
  template: '<PageHackstackAlgebra v-bind="$props" />',
})

export const Default = Template.bind({})
Default.args = {}
