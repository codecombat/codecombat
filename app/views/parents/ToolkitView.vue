<template>
  <div class="toolkit">
    <button-resource-icon
      v-for="resourceHubLink in resources"
      :key="resourceHubLink.name"
      :icon="resourceHubLink.icon"
      :label="resourceHubLink.name"
      :link="resourceHubLink.link"
      :description="resourceHubLink.description"
      :locked="resourceHubLink.locked"
      :from="resourceHubLink.source || 'Resource Hub'"
      :section="sectionSlug"
    />
  </div>
</template>

<script>
import zendeskResourceMixin
  from '../../../ozaria/site/components/teacher-dashboard/BaseResourceHub/mixins/zendeskResourceMixin'
import ButtonResourceIcon
  from '../../../ozaria/site/components/teacher-dashboard/BaseResourceHub/components/ButtonResourceIcon'
export default {
  name: 'ToolkitView',
  props: {
    product: {
      type: String,
      default: 'CodeCombat'
    }
  },
  data () {
    return {
      resources: [],
      sectionSlug: 'faq',
      faqResources: []
    }
  },
  mixins: [
    zendeskResourceMixin
  ],
  components: {
    ButtonResourceIcon
  },
  async created () {
    await this.fetchResources()
  },
  methods: {
    async fetchResources () {
      const res = await this.getZendeskResourcesMap()
      this.faqResources = this.resourceHubLinksHelper(res)('faq')
      this.resources = this.faqResources.filter(r => r.name === 'Frequently Asked Questions')
    }
  },
  watch: {
    product: async function (newVal, oldVal) {
      if (newVal !== oldVal) {
        this.resources = []
        await this.fetchResources()
      }
    }
  },
  computed: {
    relevantCategoryIds () {
      if (this.product === 'Ozaria') {
        return {
          360004950774: 'Ozaria for Educators'
        }
      } else {
        return {
          1500001145602: 'CodeCombat for Educators'
        }
      }
    }
  }
}
</script>

<style scoped lang="scss">
.toolkit {
  padding: 5rem;
  display: flex;
  flex-wrap: wrap;
}
</style>
