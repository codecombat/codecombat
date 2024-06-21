import ProgressBar from './ProgressBar.vue'

export default {
  title: 'ProgressBar',
  component: ProgressBar
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { ProgressBar },
  template: `
<ProgressBar v-bind="$props">
  <template  v-slot:dot-label-0]>
    <div class="text-center">0</div>
  </template>
  <template  v-slot:dot-label-1]>
    <div class="text-center">5k</div>
  </template>
  <template  v-slot:dot-label-2]>
    <div class="text-center">10k</div>
  </template>
</ProgressBar>
`
})

export const Default = Template.bind({})
Default.args = {
  progress: 0.3,
  dots: 3
}
