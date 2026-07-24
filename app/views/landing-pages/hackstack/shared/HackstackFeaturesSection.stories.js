import HackstackFeaturesSection from './HackstackFeaturesSection.vue'

export default {
  title: 'Pages/HackStack/Shared/FeaturesSection',
  component: HackstackFeaturesSection,
  parameters: {
    layout: 'fullscreen',
  },
}

const Template = (args, { argTypes }) => ({
  components: { HackstackFeaturesSection },
  props: Object.keys(argTypes),
  template: '<HackstackFeaturesSection v-bind="$props" />',
})

export const Algebra = Template.bind({})
Algebra.args = {
  variant: 'algebra',
  title: 'Core Features',
  features: [
    {
      key: 'foundations',
      image: '/images/pages/hackstack/ai-foundations.png',
      title: 'AI Foundations',
    },
    {
      key: 'evaluate',
      image: '/images/pages/hackstack/ai-evaluate.png',
      title: 'Evaluate',
    },
    {
      key: 'modelling',
      image: '/images/pages/hackstack/ai-modelling.png',
      title: 'Model',
    },
  ],
}

export const Cyber = Template.bind({})
Cyber.args = {
  variant: 'cyber',
  title: 'Core Features',
  features: [
    {
      key: 'certification',
      image: '/images/pages/hackstack/cyber/pillar-certification.png',
      title: 'Certification aligned',
      description: 'Build career-ready skills.',
    },
    {
      key: 'writing',
      image: '/images/pages/hackstack/cyber/pillar-writing.png',
      title: 'Learn by doing',
      description: 'Practice with realistic scenarios.',
    },
    {
      key: 'delivery',
      image: '/images/pages/hackstack/cyber/pillar-delivery.png',
      title: 'Teacher ready',
      description: 'Use a complete classroom pathway.',
    },
  ],
}
