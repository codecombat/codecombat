<template>
  <div class="parent-container">
    <sidebar-component
      :children="children"
      :default-tab="selectedView"
      @onAddAnotherChild="onAddAnotherChildClicked"
      @onSelectedChildrenChange="onSelectedChildrenChange"
      :child-id="selectedChildrenId"
    />
    <header-component
      @onSelectedProductChange="onSelectedProductChange"
      :child="selectedChildren"
      :is-online-class-paid-user="isPaidOnlineClassUser()"
    />
    <student-progress-view
      v-if="selectedView === 'dashboard' || selectedView === 'progress'"
      :product="selectedProduct"
      :child="selectedChildren"
      :is-paid-user="isPaidOnlineClassUser()"
    />
    <student-summary-view
      v-else-if="selectedView === 'summary'"
      :child="selectedChildren"
      :is-paid-online-class-user="isPaidOnlineClassUser()"
    />
    <div
      v-else-if="selectedView === 'add-another-child'"
      class="create-child"
    >
      <create-child-account-component
        @onChildAccountSubmit="onChildAccountSubmit"
        @existingAccountLinked="onExistingAccountLink"
        :hide-back-button="true"
      />
    </div>
    <toolkit-view
      v-else-if="selectedView === 'toolkit'"
      :product="selectedProduct"
    />
    <div
      v-else
      class="unknown"
    >
      Page Not Found
    </div>
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
      default: 'add-another-child'
    },
    childId: {
      type: String,
      default: ''
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
  watch: {
    viewName: function (newVal, oldVal) {
      if (newVal !== oldVal) this.selectedView = newVal
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
    if (!me.isParentHome()) {
      window.location.href = '/'
      return
    }
    const resp = await me.getRelatedAccounts()
    const relatedAccounts = resp.data || []
    this.children = relatedAccounts.filter(r => r.relation === 'children')
    const verifiedChildren = this.children.filter(c => c.verified)
    const lastChild = () => verifiedChildren.length > 0 ? verifiedChildren[verifiedChildren.length - 1].userId : null
    if (this.childId) {
      const childExists = this.children.find(c => c.userId === this.childId)
      if (childExists && childExists.verified) {
        this.selectedChildrenId = this.childId
      } else if (childExists) {
        noty({
          type: 'error',
          text: `${childExists.name} children account not verified`,
          layout: 'center',
          timeout: 5000
        })
        this.selectedChildrenId = lastChild()
      } else {
        this.selectedChildrenId = lastChild()
      }
    } else {
      this.selectedChildrenId = lastChild()
    }
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
    onSelectedChildrenChange (data) {
      // this.$router.push({
      //   name: 'ParentDashboard',
      //   params: {
      //     childId: data,
      //     viewName: this.viewName
      //   }
      // })
      // router.push doesn't seem to trigger route change
      window.location.href = `/parents/${this.viewName}/${data}`
    },
    async onExistingAccountLink (data) {
      await this.onChildAccountSubmitHelper(null, { existingAccount: data })
    },
    isPaidOnlineClassUser () {
      return me.isPaidOnlineClassUser()
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

.unknown {
  font-size: 2rem;
  text-align: center;
}
</style>
