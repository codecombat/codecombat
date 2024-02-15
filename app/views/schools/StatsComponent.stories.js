import StatsComponent from './StatsComponent.vue'

export default {
  title: 'Pages/Schools/StatsComponent',
  component: StatsComponent
}

const Template = (args) => ({
  components: { StatsComponent },
  template: '<stats-component v-bind="args" />'
})

export const Default = Template.bind({})
Default.args = {}
