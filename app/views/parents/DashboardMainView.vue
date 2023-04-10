<template>
  <div class="parent-container">
    <sidebar-component
      :children="children"
      @onAddAnotherChild="onAddAnotherChildClicked"
    />
    <header-component />
    <student-progress-view
      v-if="selectedView === 'dashboard'"
    />
    <student-summary-view
      v-if="selectedView === 'summary'"
    />
    <div
      v-if="selectedView === 'add-another-child'"
      class="create-child"
    >
      <create-child-account-component
        @onChildAccountSubmit="onChildAccountSubmit"
      />
    </div>
  </div>
</template>

<script>
import SidebarComponent from './SidebarComponent'
import HeaderComponent from './HeaderComponent'
import StudentProgressView from './StudentProgressView'
import StudentSummaryView from './StudentSummaryView'
import CreateChildAccountComponent from './signup/CreateChildAccountComponent'
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
      selectedView: this.viewName
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
    CreateChildAccountComponent
  },
  async created () {
    const resp = await me.getRelatedAccounts()
    const relatedAccounts = resp.data || []
    this.children = relatedAccounts.filter(r => r.relation === 'children')
  },
  methods: {
    onAddAnotherChildClicked () {
      this.selectedView = 'add-another-child'
    },
    onChildAccountSubmit (data) {
      this.onChildAccountSubmitHelper(data)
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
