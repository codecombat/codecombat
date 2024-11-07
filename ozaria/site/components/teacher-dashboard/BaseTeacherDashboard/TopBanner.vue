<template>
  <div
    v-if="showBanner"
    id="top-banner"
  >
    <mixed-color-label
      text="Try **AI HackStack:** The easiest and safest path to AI literacy, empowering students to create—whether it’s games, art, writing, code, or more. **[/hackstack]Click to start now!**"
      @link-clicked="handleLinkClicked"
    />
  </div>
</template>

<script>
import MixedColorLabel from 'app/components/common/labels/MixedColorLabel'
import trackable from 'app/components/mixins/trackable.js'

const storageKey = 'teacher-dashboard-ai-hackstack-top-banner'

export default {
  components: {
    'mixed-color-label': MixedColorLabel,
  },
  mixins: [trackable],
  computed: {
    showBanner () {
      if (localStorage.getItem(storageKey) === 'clicked') {
        return false
      }
      const currentDate = new Date()
      const start = new Date('2024-11-07')
      const end = new Date('2024-11-30')
      return currentDate >= start && currentDate <= end
    },
  },
  methods: {
    handleLinkClicked () {
      this.trackEvent('AI Hackstack banner clicked', { category: 'Teachers' })
      localStorage.setItem(storageKey, 'clicked')
    },
  },
}
</script>

<style scoped lang="scss">
@import "app/styles/component_variables.scss";

#top-banner {
    background: $teal-light-2;
    padding: 10px 0px;
    text-align: center;
    font-size: 18px;
    font-style: normal;
    line-height: 20px;
    ::v-deep {
        .mixed-color-label__highlight {
            color: var(--color-dark-grey);
            font-weight: bold;
        }
    }
}
</style>