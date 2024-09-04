<template>
  <div
    v-if="showBanner"
    id="top-banner"
  >
    <mixed-color-label
      text="Try **CodeCombat Junior:** Our new K-5 curriculum, tablet-ready and perfect for all learners. **[https://codecombat.com/teachers/curriculum]Click to start now!**"
      @link-clicked="handleLinkClicked"
    />
  </div>
</template>

<script>
import MixedColorLabel from 'app/components/common/labels/MixedColorLabel'
import trackable from 'app/components/mixins/trackable.js'

const storageKey = 'teacher-dashboard-coco-jr-top-banner'

export default {
  components: {
    'mixed-color-label': MixedColorLabel
  },
  mixins: [trackable],
  computed: {
    showBanner () {
      if (localStorage.getItem(storageKey) === 'clicked') {
        return false
      }
      const currentDate = new Date()
      const start = new Date('2024-09-05')
      const end = new Date('2024-09-25')
      return currentDate >= start && currentDate <= end
    }
  },
  methods: {
    handleLinkClicked () {
      this.trackEvent('Coco JR banner clicked', { category: 'Teachers' })
      localStorage.setItem(storageKey, 'clicked')
    }
  }
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