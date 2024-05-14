<template>
  <page-template>
    <create-parent-account-component
      v-if="currentView === 'create-parent-account'"
      :initial-data="parentAccountData"
      :error-msg="errorMsg"
      @onParentAccountSubmit="onParentAccountSubmit"
    />
    <create-child-account-component
      v-if="currentView === 'create-child-account'"
      :initial-data="childAccountData"
      @backButtonClicked="onBackButtonClicked"
      @onChildAccountSubmit="onChildAccountSubmit"
      @existingAccountLinked="onExistingAccountLink"
    />
  </page-template>
</template>

<script>
import PageTemplate from './PageTemplate'
import CreateParentAccountComponent from './signup/CreateParentAccountComponent'
import CreateChildAccountComponent from './signup/CreateChildAccountComponent'
import createChildAccountMixin from './mixins/createChildAccountMixin'
const User = require('../../models/User')

export default {
  name: 'SignupView',
  components: {
    PageTemplate,
    CreateParentAccountComponent,
    CreateChildAccountComponent
  },
  mixins: [
    createChildAccountMixin
  ],
  data () {
    return {
      currentView: 'create-parent-account',
      parentAccountData: null,
      childAccountData: null,
      errorMsg: null
    }
  },
  methods: {
    async onParentAccountSubmit (data) {
      this.parentAccountData = data
      const { exists } = await User.checkEmailExists(data.email)
      if (exists) {
        this.errorMsg = 'Account with email already exists'
        return
      }
      // TODO: validate like in BasicInfoView with schema
      if (!data.password || data.password.length < 8) {
        this.errorMsg = 'Password should be atleast 8 characters'
        return
      }
      this.currentView = 'create-child-account'
    },
    async onChildAccountSubmit (data) {
      this.childAccountData = data
      await this.onChildAccountSubmitHelper(data)
    },
    async onExistingAccountLink (data) {
      await this.onChildAccountSubmitHelper(null, { existingAccount: data })
    },
    onBackButtonClicked (data) {
      this.currentView = 'create-parent-account'
      this.childAccountData = data
    }
  }
}
</script>

<style scoped lang="scss">
</style>
