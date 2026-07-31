import HackstackFaq from './HackstackFaq.vue'

export default {
  title: 'Pages/HackStack/Shared/Faq',
  component: HackstackFaq,
  parameters: {
    layout: 'fullscreen',
  },
}

const Template = (args, { argTypes }) => ({
  components: { HackstackFaq },
  props: Object.keys(argTypes),
  template: '<HackstackFaq v-bind="$props" />',
})

export const Default = Template.bind({})
Default.args = {
  title: 'Frequently Asked Questions',
  faqItems: [
    {
      question: 'What is HackStack?',
      answer: 'HackStack helps students learn with AI.',
    },
    {
      question: 'What can students build?',
      answer: [
        'Interactive projects',
        'Creative simulations',
      ],
    },
  ],
  seeMoreText: 'See more questions',
}
