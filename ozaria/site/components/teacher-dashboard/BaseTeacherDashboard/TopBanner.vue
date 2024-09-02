<template>
  <div
    v-if="showBanner"
    id="top-banner"
  >
    <mixed-color-label
      text="Try **CodeCombat Junior:** Our new K-5 curriculum, tablet-ready and perfect for all learners. **[https://codecombat.com/teachers/curriculum]Click to start now!**"
    />
  </div>
</template>

<script>
import MixedColorLabel from 'app/components/common/labels/MixedColorLabel'

export default {
  components: {
    'mixed-color-label': MixedColorLabel
  },
  computed: {
    showBanner () {
      const currentDate = new Date()
      const start = new Date('2024-09-05')
      const end = new Date('2024-09-25')
      return currentDate >= start && currentDate <= end
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