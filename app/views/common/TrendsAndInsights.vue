<template>
  <box-panel
    :title="$t('home_v3.trends_insights')"
    :items="trends"
  />
</template>

<script>
import BoxPanel from 'app/components/common/elements/BoxPanel.vue'

export default Vue.extend({
  name: 'TrendsAndInsights',
  components: {
    BoxPanel
  },
  data () {
    return {
      trends: [
        {
          title: this.$t('schools_page.trends_1_title'),
          image: '/images/pages/home-v3/trends/1.webp',
          text: this.$t('schools_page.trends_1_text'),
          link: 'https://blog.codecombat.com/ai-isnt-replacing-coding-its-accelerating-it/',
          linkText: this.$t('schools_page.trends_1_linkText')
        },
        {
          title: this.$t('schools_page.trends_2_title'),
          image: '/images/pages/home-v3/trends/2.webp',
          text: this.$t('schools_page.trends_2_text'),
          link: 'https://codecombat.com/podcast/career-technical-education',
          linkText: this.$t('schools_page.trends_2_linkText')
        }
      ]
    }
  }
})
</script>
