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
import { PAGE_TITLES, COMPONENT_NAMES } from '../../common/constants'
import { mapMutations } from 'vuex'
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
  watch: {
    product: {
      handler () {
        // when product changes, set the default selected tab to guide
        this.selectedTab = 'guide'
      },
    },
  },
  mounted () {
    this.setTeacherId(me.get('_id'))
    this.setPageTitle(PAGE_TITLES[COMPONENT_NAMES.CURRICULUM_GUIDE])
  },
  methods: {
    ...mapMutations({
      setTeacherId: 'teacherDashboard/setTeacherId',
      setPageTitle: 'teacherDashboard/setPageTitle',
    }),
    onSelectedTabChange (tab) {
      this.selectedTab = tab
    },
  },
}
</script>

<style lang="scss" scoped>
</style>
