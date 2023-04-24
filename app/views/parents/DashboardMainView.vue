<template>
  <div class="parent-container">
    <sidebar-component
      :children="children"
      :default-tab="viewName"
      @onAddAnotherChild="onAddAnotherChildClicked"
      @onTabChange="onTabChange"
      @onSelectedChildrenChange="onSelectedChildrenChange"
    />
    <header-component
      @onSelectedProductChange="onSelectedProductChange"
      :child="selectedChildren"
    />
    <student-progress-view
      v-if="selectedView === 'dashboard' || selectedView === 'progress'"
      :product="selectedProduct"
      :child="selectedChildren"
    />
    <student-summary-view
      v-if="selectedView === 'summary'"
      :child="selectedChildren"
    />
    <div
      v-if="selectedView === 'add-another-child'"
      class="create-child"
    >
      <create-child-account-component
        @onChildAccountSubmit="onChildAccountSubmit"
      />
    </div>
    <toolkit-view
      v-if="selectedView === 'toolkit'"
      :product="selectedProduct"
    />
  </div>
</template>

<script>
import SidebarComponent from './SidebarComponent'
import HeaderComponent from './HeaderComponent'
import StudentProgressView from './StudentProgressView'
import StudentSummaryView from './StudentSummaryView'
import CreateChildAccountComponent from './signup/CreateChildAccountComponent'
import ToolkitView from './ToolkitView'
import createChildAccountMixin from './mixins/createChildAccountMixin'

export default {
  name: 'DashboardMainView',
  props: {
    viewName: {
      type: String,
      default: 'dashboard'
    }
  },
  data () {
    return {
      children: [],
      selectedView: this.viewName,
      selectedProduct: null,
      selectedChildrenId: null
    }
  },
  mixins: [
    createChildAccountMixin
  ],
  components: {
    StudentSummaryView,
    SidebarComponent,
    HeaderComponent,
    StudentProgressView,
    CreateChildAccountComponent,
    ToolkitView
  },
  async created () {
    const resp = await me.getRelatedAccounts()
    const relatedAccounts = resp.data || []
    this.children = relatedAccounts.filter(r => r.relation === 'children')
    this.selectedChildrenId = this.children.length > 0 ? this.children[0].userId : null
  },
  methods: {
    onAddAnotherChildClicked () {
      this.selectedView = 'add-another-child'
    },
    onChildAccountSubmit (data) {
      this.onChildAccountSubmitHelper(data)
    },
    onSelectedProductChange (data) {
      this.selectedProduct = data
    },
    onTabChange (data) {
      this.selectedView = data
    },
    onSelectedChildrenChange (data) {
      this.selectedChildrenId = data
    }
  },
  computed: {
    selectedChildren () {
      return this.children?.find(c => c.userId === this.selectedChildrenId)
    }
  }
}
</script>

<style scoped lang="scss">
.parent-container {
  font-size: 62.5%; // 10px/16px = 62.5% -> 1rem = 10px
  font-family: Work Sans, "Open Sans", sans-serif;

  display: grid;
  grid-template-columns: [sidebar-start] 20rem [sidebar-end main-content-start] repeat(6, [main-start] 1fr [main-end]) [main-content-end];
  //grid-template-rows: minmax(30rem, min-content);
  //grid-template-rows: 1fr 3fr;
  grid-template-rows: repeat(2, minmax(min-content, max-content));
}

.create-child {
  grid-column: main-start 2 / main-start 6;

  margin: 2rem;
}
</style>
