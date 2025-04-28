<template>
  <div class="curr-guide">
    <header-component
      :product="product"
      :default-tab="selectedTab"
      @onSelectedTabChange="onSelectedTabChange"
    />
    <explore-component
      v-if="selectedTab === 'explore'"
      :product="product"
    />
    <guide-content-component
      v-if="selectedTab === 'guide'"
      :product="product"
    />
  </div>
</template>

<script>
import HeaderComponent from './components/HeaderComponent.vue'
import ExploreComponent from './components/ExploreComponent.vue'
import GuideContentComponent from './components/GuideContentComponent.vue'
export default {
  name: 'BaseCurriculumGuideV2',
  components: {
    HeaderComponent,
    ExploreComponent,
    GuideContentComponent,
  },
  props: {
    product: {
      type: String,
      required: true,
    },
  },
  data () {
    return {
      selectedTab: 'guide',
    }
  },
  methods: {
    onSelectedTabChange (tab) {
      this.selectedTab = tab
    },
  },
}
</script>

<style lang="scss" scoped>
</style>
