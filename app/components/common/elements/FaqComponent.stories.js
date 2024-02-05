import FaqComponent from './FaqComponent.vue'

export default {
  title: 'Containers/FaqComponent',
  component: FaqComponent
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { FaqComponent },
  template: '<FaqComponent v-bind="$props" />'
})

export const Default = Template.bind({})
Default.args = {
  faqItems: [
    {
      question: 'Is there an age requirement?',
      answer: 'Participants must be aged 13-17 and be able to provide legal documentation to travel.'
    },
    {
      question: 'Can I travel with my child?',
      answer: 'Some parents do choose to travel, however the activities, events, travel and accommodations are only provided for students.'
    },
    {
      question: 'How much experience do you need to participate?',
      answer: 'A basic understanding of programming in any language is all that a student must know. Since we are grouping them into teams of varying experience levels we expect those with more experience to support those with less.'
    }
  ]
}
