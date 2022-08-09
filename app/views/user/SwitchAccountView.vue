<template>
  <div>
    <div
      v-if="!loading"
      class="switch"
    >
      <related-user-component
        :related="relatedUsersData"
        class="center-cmpt container"
      />
      <div class="switch__head">
        <button
          class="add-user__head__btn btn btn-moon"
          @click="showAddUserForm"
        >
          Add Related User
        </button>
      </div>
      <div
        v-if="showAddForm"
        class="center-cmpt container"
      >
        <add-user-component
          @onAddSwitchAccount="(b) => onAddSwitchAccount(b)"
        />
      </div>
      <div
        v-if="addingAccount"
        class="switch__adding"
      >
        Adding account...
      </div>
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
import RelatedUserComponent from './switch-account/RelatedUserComponent'
const usersLib = require('../../core/api/users')
export default {
  name: 'SwitchAccountView',
  components: {
    AddUserComponent,
    RelatedUserComponent
  },
  data () {
    return {
      loading: true,
      relatedUsers: null,
      relatedUsersData: null,
      accountAdded: false,
      addingAccount: false,
      showAddForm: false
    }
  },
  methods: {
    async onAddSwitchAccount (body) {
      console.log('body', body)
      this.addingAccount = true
      this.accountAdded = false
      console.log('old mee', me.get('related'))
      await usersLib.linkRelatedAccounts(body)
      await me.fetch({ cache: false })
      console.log('mee', me.get('related'))
      this.relatedUsers = me.get('related')
      await this.fetchRelatedUsers()
      this.accountAdded = true
      this.addingAccount = false
      this.showAddForm = false
    },
    showAddUserForm () {
      this.showAddForm = true
    },
    async fetchRelatedUsers () {
      const promiseArr = this.relatedUsers?.map((r) => {
        return usersLib.getRelatedAccount({ userId: r.userId })
      })
      if (promiseArr?.length) {
        const resp = await Promise.all(promiseArr)
        console.log('resp', resp)
        this.relatedUsersData = resp?.map((r, index) => {
          const rel = this.relatedUsers[index]
          return { ...rel, ...r.user }
        })
      }
    }
  },
  async created () {
    // fetch users based on related
    const related = me.get('related')
    if (!related || related.length === 0) {
      this.loading = false
      return
    }
    this.relatedUsers = related
    await this.fetchRelatedUsers()
    this.loading = false
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

  &__head {
    text-align: center;
  }

  &__added {
    text-align: center;
    font-size: 1.8rem;
    color: #73A839;
  }

  &__adding {
    text-align: center;
    color: #808080;
    font-size: 1.6rem;
  }
}

.center-cmpt {
  padding-left: 15%;
  padding-right: 15%;
}
</style>
