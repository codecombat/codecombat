<template>
  <modal
    title="Change Password"
    @close="$emit('close')"
  >
    <form
      @submit.prevent="onFormSubmit"
      class="passwd container"
    >
      <div class="form-group">
        <label for="new-password">New Password</label>
        <input
          v-model="newPassword"
          type="password" id="new-password" class="form-control"
        />
      </div>
      <div class="form-group">
        <label for="confirm-new-password">Confirm New Password</label>
        <input
          v-model="newConfirmedPassword"
          type="password" id="confirm-new-password" class="form-control"
        />
      </div>
      <div
        v-if="errMsg"
        class="error form-group"
      >
        {{ errMsg }}
      </div>
      <div
        v-if="successMsg"
        class="success form-group"
      >
        {{ successMsg }}
      </div>
      <div class="form-group">
        <button
          type="submit"
          class="btn btn-success btn-lg pull-right"
        >
          Submit
        </button>
      </div>
    </form>
  </modal>
</template>

<script>
import Modal from '../../components/common/Modal'
export default {
  name: 'ChangePasswordModal',
  components: {
    Modal
  },
  props: {
    userIdToChangePassword: {
      type: String,
      required: true
    }
  },
  data () {
    return {
      newPassword: null,
      newConfirmedPassword: null,
      errMsg: null,
      successMsg: null
    }
  },
  methods: {
    async onFormSubmit () {
      this.errMsg = null
      this.successMsg = null
      if (!this.newPassword || !this.newConfirmedPassword) {
        this.errMsg = 'Required field empty'
        return
      }
      if (this.newPassword !== this.newConfirmedPassword) {
        this.errMsg = 'Passwords dont match'
        return
      }
      try {
        await me.changePassword(this.userIdToChangePassword, this.newPassword)
      } catch (err) {
        console.error('failed to change password', err)
        this.errMsg = err?.msg || err?.responseJSON?.message || err?.responseText || 'Internal Error'
        return
      }
      this.successMsg = 'Success'
    }
  }
}
</script>

<style scoped lang="scss">
.passwd {
  .error {
    font-size: 15px;
    color: red;
  }

  .success {
    font-size: 15px;
    color: green;
  }
}
</style>
