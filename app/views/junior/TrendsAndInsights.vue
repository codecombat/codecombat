<script>
import TrendsAndInsights from 'app/views/common/TrendsAndInsights.vue'

export default {
  name: 'JuniorTrendsAndInsights',
  extends: TrendsAndInsights,
  data () {
    return {
      trends: [
        {
          title: this.$t('junior_page.trends_1_title'),
          image: '/images/pages/junior/jwebinar.webp',
          text: this.$t('junior_page.trends_1_text'),
          link: 'https://drive.google.com/file/d/1r6EFUEnyBleilMPcwQgZEcuVeqUluwkn/view',
          linkText: this.$t('junior_page.trends_1_linkText')
        },
        {
          title: this.$t('junior_page.trends_2_title'),
          image: '/images/pages/junior/jblog.webp',
          text: this.$t('junior_page.trends_2_text'),
          link: 'https://blog.codecombat.com/codecombat-junior-a-new-dynamic-approach-to-k-5-coding/',
          linkText: this.$t('junior_page.trends_2_linkText')
        }
      ]
    }
  }
}
</script>
