<template>
  <div>
    <div
      v-if="!loading"
      class="switch"
    >
      <related-user-component
        :related="relatedUsersData"
        :confirm-email-sent-for="confirmEmailSentFor"
        class="center-cmpt container"
        @switchUser="(data) => onSwitchUser(data)"
        @removeUser="(data) => onRemoveUser(data)"
        @sendVerifyEmail="(data) => onSendVerifyEmail(data)"
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
        v-if="inProgress"
        class="switch__adding switch__progress"
      >
        {{ inProgress }}...
      </div>
      <div
        v-if="isComplete"
        class="switch__added switch__progress"
      >
        {{ isComplete }}
      </div>
      <div
        v-if="errMsg"
        class="switch__error switch__progress"
      >
        {{ errMsg }}
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
      isComplete: false,
      inProgress: false,
      showAddForm: false,
      confirmEmailSentFor: '',
      errMsg: null
    }
  },
  methods: {
    async onAddSwitchAccount (body) {
      console.log('body', body)
      this.inProgress = 'Adding'
      this.isComplete = false
      this.errMsg = null
      console.log('old mee', me.get('related'))
      try {
        await usersLib.linkRelatedAccounts(body)
      } catch (err) {
        this.errMsg = err?.msg || err?.message || err || 'Internal Error'
        this.inProgress = false
        return
      }
      await me.fetch({ cache: false })
      console.log('mee', me.get('related'))
      this.relatedUsers = me.get('related')
      await this.fetchRelatedUsers()
      this.isComplete = 'Account Added'
      this.inProgress = false
      this.showAddForm = false
    },
    showAddUserForm () {
      this.showAddForm = true
      this.isComplete = false
    },
    async fetchRelatedUsers () {
      const promiseArr = this.relatedUsers?.map((r) => {
        return usersLib.getRelatedAccount({ userId: r.userId })
      })
      if (promiseArr?.length) {
        const resp = await Promise.all(promiseArr)
        this.relatedUsersData = resp?.map((r, index) => {
          const rel = this.relatedUsers[index]
          return { ...rel, ...r.user }
        })
      } else {
        this.relatedUsersData = []
      }
    },
    async onSwitchUser ({ email }) {
      await me.spy(email)
      window.location.reload()
    },
    async onRemoveUser ({ userId }) {
      this.inProgress = 'Removing'
      this.isComplete = false
      await me.removeRelatedAccount(userId)
      await me.fetch({ cache: false })
      this.relatedUsers = me.get('related')
      console.log('remove', this.relatedUsers)
      await this.fetchRelatedUsers()
      this.inProgress = false
    },
    async onSendVerifyEmail ({ userId, email }) {
      await usersLib.sendVerifyEmail({ userId, email })
      this.confirmEmailSentFor = email
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

    margin-top: 1rem;
  }

  &__progress {
    text-align: center;
    font-size: 1.8rem;

    margin-top: 5px;
  }

  &__added {
    color: #73A839;
  }

  &__adding {
    color: #808080;
  }

  &__error {
    color: #ff0000;
  }
}

.center-cmpt {
  padding-left: 5%;
  padding-right: 5%;
}
</style>
