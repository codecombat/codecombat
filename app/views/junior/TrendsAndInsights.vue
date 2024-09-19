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
          link: 'https://codecombat.com/podcast/career-technical-education',
          linkText: this.$t('junior_page.trends_1_linkText')
        },
        {
          title: this.$t('junior_page.trends_2_title'),
          image: '/images/pages/junior/jblog.webp',
          text: this.$t('junior_page.trends_2_text'),
          link: 'https://blog.codecombat.com/ai-isnt-replacing-coding-its-accelerating-it/',
          linkText: this.$t('junior_page.trends_2_linkText')
        }
      ]
    }
  }
}
</script>
