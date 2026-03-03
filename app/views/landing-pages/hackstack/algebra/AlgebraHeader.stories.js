import AlgebraHeader from './AlgebraHeader.vue'

export default {
  title: 'Pages/HackStack/Algebra/Header',
  component: AlgebraHeader,
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { AlgebraHeader },
  template: '<AlgebraHeader v-bind="$props" />',
})

export const Default = Template.bind({})
Default.args = {}
