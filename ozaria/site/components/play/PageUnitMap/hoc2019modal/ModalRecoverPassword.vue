<script>
const forms = require('core/forms')
const { genericFailure } = require('core/errors')

export default {
  data: () => ({
    loading: false,
    error: false
  }),

  methods: {
    recoverAccount () {
      this.error = false
      forms.clearFormAlerts($('#recover-password-modal'))
      const email = (forms.formToObject($('#recover-password-modal'))).email
      if (!email) {
        return
      }

      const res = $.post('/auth/reset', { email }, this.successfullyRecovered)
      res.fail(jqxhr => {
        setTimeout(() => {
          this.error = true
          this.loading = false
        }, 1000)
      })
      this.loading = true
    },

    successfullyRecovered () {
      setTimeout(() => {
        this.$emit('successfullyRecovered')
      }, 1000)
    }
  }
}
</script>

<template lang="pug">

  #recover-password-modal
    h3(data-i18n="common.sending" v-if="loading") Sending...
    <template v-if="!loading">
      h3(data-i18n="recover.recover_account_title") Recover Account
      .form
        .form-group(:class="error ? 'has-error' : ''")
          .help-block.error-help-block(v-if="error") Email not found
          label.control-label(for="recover-email", data-i18n="general.email") Email
          input#recover-email.input-large.form-control(name="email", type="email" required)
      .modal-footer
        button.btn.btn-block.btn-success#recover-button(data-i18n="recover.send_password" @click="recoverAccount") Send Recovery Password
    </template>

</template>

<style lang="scss" scoped>
#recover-password-modal {
  width: 600px;
}

</style>
