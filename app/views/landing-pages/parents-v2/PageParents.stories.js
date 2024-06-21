import PageParents from './PageParents.vue'

export default {
  title: 'Parents/Page',
  component: PageParents,
  argTypes: {
  }
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { PageParents },
  template: `<PageParents v-bind="$props">
  </PageParents>`
})

export const Default = Template.bind({})
Default.args = {
}