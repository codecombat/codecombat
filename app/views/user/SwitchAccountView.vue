<template>
  <div>
    <div
      v-if="!loading"
      class="switch"
    >
      <div class="add-user__head">
        <button
          class="add-user__head__btn btn btn-moon"
          @click="showAddUserForm"
        >
          Add Related User
        </button>
      </div>
      <div
        v-if="addingAccount"
        class="switch__adding"
      >
        Adding account...
      </div>
      <add-user-component
        v-if="showAddForm"
        @onAddSwitchAccount="(b) => onAddSwitchAccount(b)"
      />
      <div
        v-if="accountAdded"
        class="switch__added"
      >
        Account added
      </div>
    </div>
    <div
      v-else
      class="loading"
    >
      {{ $t('common.loading') }}
    </div>
  </div>
</template>

<script>
import AddUserComponent from './switch-account/AddUserComponent'
const usersLib = require('../../core/api/users')
export default {
  name: 'SwitchAccountView',
  components: {
    AddUserComponent
  },
  data () {
    return {
      loading: true,
      relatedUsers: null,
      accountAdded: false,
      addingAccount: false,
      showAddForm: false
    }
  },
  methods: {
    async onAddSwitchAccount (body) {
      console.log('body', body)
      this.addingAccount = true
      console.log('old mee', me.get('related'))
      await usersLib.linkRelatedAccounts(body)
      await me.fetch({ cache: false })
      console.log('mee', me.get('related'))
      this.relatedUsers = me.get('related')
      this.accountAdded = true
      this.addingAccount = false
    },
    showAddUserForm () {
      this.showAddForm = true
    }
  },
  created () {
    // fetch users based on related
    const related = me.get('related')
    if (!related || related.length === 0) {
      this.loading = false
      // return
    }
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/common/button";
.loading {
  text-align: center;
}
.switch {
  font-size: 62.5%;
}
</style>
