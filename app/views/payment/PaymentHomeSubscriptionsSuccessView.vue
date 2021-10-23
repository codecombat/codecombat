<template>
  <div class="container-fluid" id="home-sub-success-view">
    <div class="container">
      <div class="head text-center">
        <h2 class="success-text">Congratulations, Payment Successful!!!</h2>
        <h3 class="processed">Your Premium access is being processed...</h3>
      </div>
      <div class="section">
        As a next step, we will grant you a premium access which typically takes around <b>2-5 minutes</b> after the payment has been successful.
      </div>
      <div class="section">
        You will also <b>receive an email</b> once premium access has been granted. Please <b>refresh</b> the page once you get the email to access premium levels and buy hero, pets or gear.
      </div>
      <div class="section">
        Thank you for choosing CodeCombat and you can always reach us with any questions at <a href="mailto:support@codecombat.com">support@codecombat.com</a>
      </div>
    </div>
  </div>
</template>

<script>
const paymentUtils = require('app/lib/paymentUtils')
export default {
  name: "PaymentHomeSubscriptionsSuccessView",
  created() {
    if (!paymentUtils.hasTemporaryPremiumAccess() && !me.hasSubscription())
      paymentUtils.setTemporaryPremiumAccess()
  }
}
</script>

<style scoped lang="sass">
.section
  padding: 10px 12%
.success-text
  color: green
.processed
  color: grey
</style>
