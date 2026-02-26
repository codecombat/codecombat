import CurriculumPathSection from './CurriculumPathSection.vue'

export default {
  title: 'Pages/HackStack/Algebra/CurriculumPathSection',
  component: CurriculumPathSection,
  parameters: {
    layout: 'fullscreen',
  },
  argTypes: {
    showCta: {
      control: 'boolean',
      description: 'Show/hide the CTA button and subtitle (mirrors me.isAnonymous() === false in production)',
    },
  },
}

const Template = (args, { argTypes }) => ({
  components: { CurriculumPathSection },
  props: Object.keys(argTypes),
  template: '<CurriculumPathSection v-bind="$props" />',
})

export const WithCta = Template.bind({})
WithCta.args = { showCta: true }

export const WithoutCta = Template.bind({})
WithoutCta.args = { showCta: false }
