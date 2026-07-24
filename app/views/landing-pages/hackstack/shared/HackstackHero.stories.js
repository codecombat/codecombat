import CTAButton from 'app/components/common/buttons/CTAButton.vue'
import HackstackHero from './HackstackHero.vue'

export default {
  title: 'Pages/HackStack/Shared/Hero',
  component: HackstackHero,
  parameters: {
    layout: 'fullscreen',
  },
}

const Template = (args, { argTypes }) => ({
  components: { CTAButton, HackstackHero },
  props: Object.keys(argTypes),
  template: `
    <HackstackHero v-bind="$props">
      <template #actions>
        <CTAButton>Get Solution</CTAButton>
        <CTAButton>Explore</CTAButton>
      </template>
    </HackstackHero>
  `,
})

export const Algebra = Template.bind({})
Algebra.args = {
  variant: 'algebra',
  title: 'AI Algebra',
  poweredByLabel: 'Powered By',
  logoSrc: '/images/pages/hackstack/hackstack-banner-black.png',
  logoAlt: 'AI Hackstack',
  description: 'Standards-aligned algebra curriculum powered by AI.',
}

export const Cyber = Template.bind({})
Cyber.args = {
  variant: 'cyber',
  title: 'Cybersecurity',
  poweredByLabel: 'Powered By',
  logoSrc: '/images/pages/hackstack/cyber/hackstack-logo.png',
  logoAlt: 'AI HackStack',
  description: 'Career-ready cybersecurity learning.',
  badges: [
    {
      src: '/images/pages/hackstack/cyber/comptia-security-plus.png',
      alt: 'CompTIA Security+',
    },
    {
      src: '/images/pages/hackstack/cyber/ap-collegeboard.jpg',
      alt: 'AP College Board',
    },
  ],
  alignmentText: 'Aligned to industry standards',
  mediaSrc: '/images/pages/hackstack/cyber/hero-simulation.png',
  mediaAlt: 'IT Help Desk Simulation',
}
