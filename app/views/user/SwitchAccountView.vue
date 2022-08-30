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
          {{ $t('related_accounts.add_related_user') }}
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
      this.inProgress = $.t('related_accounts.adding')
      this.isComplete = false
      this.errMsg = null
      try {
        await me.linkRelatedAccount(body)
      } catch (err) {
        this.errMsg = err?.msg || err?.message || err?.responseText || err || $.t('common.internal_error')
        this.inProgress = false
        return
      }
      await me.fetch({ cache: false })
      this.relatedUsers = me.get('related')
      await this.fetchRelatedUsers()
      this.isComplete = $.t('related_accounts.added')
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
      const text = `Switching to ${email} account..`
      const type = 'success'
      noty({ text, type, timeout: 5000, killer: true })
      setTimeout(() => {
        window.location.reload()
      }, 3000)
    },
    async onRemoveUser ({ userId }) {
      this.inProgress = $.t('related_accounts.removing')
      this.isComplete = false
      await me.removeRelatedAccount(userId)
      await me.fetch({ cache: false })
      this.relatedUsers = me.get('related')
      await this.fetchRelatedUsers()
      this.inProgress = false
    },
    async onSendVerifyEmail ({ userId, email }) {
      await usersLib.sendVerifyEmail({ userId, email })
      this.confirmEmailSentFor = email
    }
  },
  async created () {
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
  margin-bottom: 2rem;

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
