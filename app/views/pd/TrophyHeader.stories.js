import TrophyHeader from './TrophyHeader.vue'

export default {
  title: 'Pages/PD/TrophyHeader',
  component: TrophyHeader,
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { TrophyHeader },
  template: '<TrophyHeader v-bind="$props" />',
})

export const Primary = Template.bind({})
Primary.args = {}
