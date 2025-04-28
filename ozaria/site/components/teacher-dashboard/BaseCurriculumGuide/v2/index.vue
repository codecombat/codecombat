<template>
  <div class="guide">
    <header-component
      :product="product"
      :default-tab="selectedTab"
      @onSelectedTabChange="onSelectedTabChange"
    />
    <explore-component
      v-if="selectedTab === 'explore'"
      :product="product"
    />
  </div>
</template>

<script>
import HeaderComponent from './components/HeaderComponent.vue'
import ExploreComponent from './components/ExploreComponent.vue'
export default {
  name: 'BaseCurriculumGuideV2',
  components: {
    HeaderComponent,
    ExploreComponent,
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
.guide {

}
</style>
