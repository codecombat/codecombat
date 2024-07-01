import YoutubeBox from './YoutubeBox.vue'

export default {
  title: 'Boxes/YoutubeBox',
  component: YoutubeBox
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { YoutubeBox },
  template: '<YoutubeBox v-bind="$props" />'
})

export const Default = Template.bind({})
Default.args = {
  videoId: 'ovCHupmNXjQ'
}

export const Second = Template.bind({})
Second.args = {
  videoId: '7lgzK0y5x8o'
}
export const Third = Template.bind({})
Third.args = {
  videoId: 'Tk41dK9NYKo'
}
