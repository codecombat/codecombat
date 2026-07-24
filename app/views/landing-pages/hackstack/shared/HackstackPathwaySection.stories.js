import CTAButton from 'app/components/common/buttons/CTAButton.vue'
import HackstackPathwaySection from './HackstackPathwaySection.vue'

export default {
  title: 'Pages/HackStack/Shared/PathwaySection',
  component: HackstackPathwaySection,
  parameters: {
    layout: 'fullscreen',
  },
}

const Template = (args, { argTypes }) => ({
  components: { CTAButton, HackstackPathwaySection },
  props: Object.keys(argTypes),
  template: `
    <HackstackPathwaySection v-bind="$props">
      <template #cta>
        <CTAButton>Try it now</CTAButton>
        <p style="color: white; margin: 0;">Preview curriculum</p>
      </template>
      <template #tail>
        <CTAButton>View standards</CTAButton>
      </template>
    </HackstackPathwaySection>
  `,
})

export const Algebra = Template.bind({})
Algebra.args = {
  variant: 'algebra',
  title: 'Lesson Flow',
  items: [
    {
      key: 'step-1',
      label: 'Step 1',
      title: 'Learn',
      description: 'Build core knowledge.',
      tagText: 'Traditional',
      tagType: 'traditional',
      imageSrc: '/images/pages/hackstack/algebra/lesson-flow-step-1.png',
    },
    {
      key: 'step-2',
      label: 'Step 2',
      title: 'Practice',
      description: 'Apply knowledge with AI.',
      tagText: 'AI + Traditional',
      tagType: 'ai-traditional',
      imageSrc: '/images/pages/hackstack/algebra/lesson-flow-step-2.png',
    },
  ],
}

export const Cyber = Template.bind({})
Cyber.args = {
  variant: 'cyber',
  title: 'Learning Pathways',
  items: [
    {
      key: 'module-1',
      label: 'Module 1',
      title: 'Foundations',
      description: 'Build cybersecurity fundamentals.',
      tagText: 'Cybersecurity',
      imageSrc: '/images/pages/hackstack/cyber/module-1.jpg',
      iconSrc: '/images/pages/hackstack/cyber/module-icon-1.png',
    },
    {
      key: 'module-2',
      label: 'Module 2',
      title: 'Networks',
      description: 'Explore secure network design.',
      tagText: 'Networking',
      imageSrc: '/images/pages/hackstack/cyber/module-2.jpg',
      iconSrc: '/images/pages/hackstack/cyber/module-icon-2.png',
    },
  ],
}
