<template>
  <div>
    <div class="container confirm">
      <div
        v-if="wrongAccount"
        class="confirm__wrong"
      >
        {{ $t('related_accounts.wrong_account') }}
      </div>
      <form
        v-else
        @submit.prevent="onFormSubmit"
      >
        <div
          v-if="requestingConfirmUser"
          class="form-group row confirm__info"
        >
          {{ $t('related_accounts.link_account') }} {{ requestingConfirmUser.email }}
        </div>
        <div class="form-group row">
          <input
            v-model="code"
            type="text"
            class="confirm__input"
            placeholder="Enter Confirmation Code"
          >
        </div>
        <div class="form-group row confirm__submit">
          <button
            type="submit"
            class="btn btn-success"
          >
            {{ $t('play.confirm') }}
          </button>
        </div>
        <div class="form-group row">
          <div
            v-if="error"
            class="confirm__error"
          >
            {{ error }}
          </div>
          <div
            v-if="success"
            class="confirm__success"
          >
            {{ $t('related_accounts.link_successful_redirect') }}....
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
const usersLib = require('../../core/api/users')
export default {
  name: 'SwitchAccountConfirmationView',
  props: {
    confirmingUserId: {
      type: String,
      required: true
    },
    requestingConfirmUserId: {
      type: String,
      required: true
    },
    confirmCode: {
      type: String,
      default: ''
    }
  },
  data () {
    return {
      code: this.confirmCode,
      wrongAccount: false,
      requestingConfirmUser: null,
      error: null,
      success: false
    }
  },
  async created () {
    if (me.get('_id') !== this.confirmingUserId) {
      this.wrongAccount = true
      return
    }
    this.requestingConfirmUser = await this.getUserInfo(this.requestingConfirmUserId)
  },
  methods: {
    async onFormSubmit () {
      this.error = null
      this.success = false
      if (!this.code) {
        this.error = 'No code entered'
        return
      }
      const body = {
        code: this.code
      }
      try {
        await usersLib.verifyRelatedAccount({ userAskingToRelateId: this.requestingConfirmUserId, body })
      } catch (err) {
        this.error = err?.message || err || 'Error occurred'
        return
      }
      this.success = true
      setTimeout(() => {
        window.location.href = '/users/switch-account'
      }, 2000)
    },
    async getUserInfo (userId) {
      const resp = await usersLib.getRelatedAccount({ userId })
      return resp.user
    }
  }
}
</script>

<style scoped lang="scss">
.confirm {
  font-size: 62.5%;

  padding-left: 15%;
  padding-right: 15%;
  &__wrong {
    text-align: center;
    font-size: 1.8rem;
    color: #ff0000;
  }

  &__input {
    width: 80%;
  }

  &__info {
    font-size: 1.8rem;
  }

  &__error {
    color: #ff0000;
    font-size: 1.8rem;
  }

  &__success {
    color: #0B6125;
    font-size: 1.8rem;
  }
}
</style>
