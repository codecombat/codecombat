<template lang="pug">
  .container.text-center
    template(v-if="verifyStatus === 'pending'")
      span(data-i18n="account.verifying_email")
        | Verifying your email address...
    template(v-else-if="verifyStatus === 'success'")
      .alert.alert-success.center-block
        .glyphicon.glyphicon-ok-circle.m-r-1
        span(data-i18n="account.successfully_verified")
          | You've successfully confirmed your Trial Class! Looking forward to seeing you in class! We'll send you the email with the course link soon.
    template(v-else-if="verifyStatus === 'error'")
      .alert.alert-danger.center-block
        .glyphicon.glyphicon-remove-circle.m-r-1
        span(data-i18n="account.verify_error")
          | Something went wrong when confirming your Trial Class. Please try again later.
    template(v-else)
      div
        | This really shouldn't happen
      div {{ verifyStatus }}
</template>

<script>
import { confirmBooking } from '../../core/api/online-classes'
export default {
  name: 'TrialClassConfirm',
  props: {
    token: {
      type: String,
      required: true
    },
    eventId: {
      type: String,
      required: true
    }
  },
  data () {
    return {
      verifyStatus: 'unkown'
    }
  },
  mounted () {
    this.confirmClass()
  },
  methods: {
    confirmClass () {
      this.verifyStatus = 'pending'
      console.log('confirm:', this.token, this.eventId)
      const eventId = this.eventId
      const code = this.token
      confirmBooking({ eventId, code })
        .then(() => {
          this.verifyStatus = 'success'
        })
        .catch(() => {
          this.verifyStatus = 'error'
        })
    }
  }
}

</script>

<style scoped>
</style>