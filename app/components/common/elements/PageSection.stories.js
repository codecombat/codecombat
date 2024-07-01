import PageSection from './PageSection.vue'

export default {
  title: 'Containers/PageSection',
  component: PageSection
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { PageSection },
  template:
    `
    <PageSection v-bind="$props">
       <template v-slot:heading v-if="${'heading' in args}">${args.heading}</template>
       <template v-slot:body v-if="${'body' in args}">${args.body}</template>
       <template v-slot:tail v-if="${'tail' in args}">${args.tail}</template>
    </PageSection>
    `
})

export const Default = Template.bind({})

Default.args = {
  heading: 'Heading',
  body: 'Body',
  tail: 'Tail'
}