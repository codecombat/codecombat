<template>
  <div
    class="toolkit"
  >
    <div class="toolkit__header">
      <span class="toolkit__header__text toolkit__bold">
        Welcome to the Parent Toolkit!
      </span>
      <span class="toolkit__header__text">
        Don’t hesitate to contact us if you have any questions.
      </span>
      <a
        href="mailto:support@codecombat.com"
        class="yellow-btn-black-text toolkit__contact"
      >
        Contact Us
      </a>
    </div>
    <loading-bar
      :loading="loading"
    />
    <div class="resources">
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
  </div>
</template>

<script>
import zendeskResourceMixin
  from '../../../ozaria/site/components/teacher-dashboard/BaseResourceHub/mixins/zendeskResourceMixin'
import ButtonResourceIcon
  from '../../../ozaria/site/components/teacher-dashboard/BaseResourceHub/components/ButtonResourceIcon'
import LoadingBar from '../../../ozaria/site/components/common/LoadingBar'
export default {
  name: 'ToolkitView',
  components: {
    ButtonResourceIcon,
    LoadingBar
  },
  mixins: [
    zendeskResourceMixin
  ],
  props: {
    product: {
      type: String,
      default: 'codecombat'
    }
  },
  data () {
    return {
      resources: [],
      sectionSlug: 'faq',
      faqResources: [],
      loading: true
    }
  },
  computed: {
    relevantCategoryIds () {
      if (this.product === 'ozaria') {
        return {
          360004950774: 'Ozaria for Educators'
        }
      } else {
        return {
          1500001145602: 'CodeCombat for Educators'
        }
      }
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
  async created () {
    await this.fetchResources()
    this.loading = false
  },
  methods: {
    async fetchResources () {
      const res = await this.getZendeskResourcesMap()
      this.faqResources = this.resourceHubLinksHelper(res)('faq')
      const zendeskRes = this.faqResources.filter(r => r.name === 'Frequently Asked Questions')
      const resourceHubRes = await this.getResourceHubResources()
      const parentRes = resourceHubRes.filter(r => (r.roles || []).includes('parent-home'))
      this.resources = [...zendeskRes, ...parentRes]
    }
  }
}
</script>

<style scoped lang="scss">
@import "css-mixins/variables";
@import "css-mixins/common.scss";

.toolkit {
  grid-column: main-content-start/main-content-end;

  .resources {
    display: flex;
    padding: 3rem;
  }

  &__header {
    background: $color-blue-1;
    padding: 2rem;

    &__text {
      color: $color-white;
      font-feature-settings: 'clig' off, 'liga' off;
      font-size: 2rem;
      font-weight: 400;
      line-height: 3rem;
      letter-spacing: 0.444px;
    }
  }

  &__bold {
    font-weight: 600;
  }

  &__contact {
    text-decoration: none;
    padding: 1rem 3.5rem;
  }
}
</style>
