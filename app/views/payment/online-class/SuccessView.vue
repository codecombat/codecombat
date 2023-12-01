<template>
  <div
    id="online-classes-success-view"
    class="container-fluid"
  >
    <div class="container">
      <div class="head text-center">
        <h2 class="head-text">
          Congratulations
        </h2>
        <h2 class="head-text">
          Your student's coding adventure awaits
        </h2>
      </div>
      <div
        v-if="selectedPlan && numStudents"
        class="section"
      >
        You are confirmed for {{ selectedPlan }} for {{ numStudents }} {{ numStudents > 1 ? 'students' : 'student' }}
      </div>
      <div class="section">
        As a next step you can expect one of our remote learning advisors to reach out to confirm details for your next class session including more about your teacher. This typically happens within the first 24 hrs after signup.
      </div>
      <div class="section">
        Thank you for choosing CodeCombat and you can always reach us with any questions at <a href="mailto:classes@codecombat.com">classes@codecombat.com</a>
      </div>
    </div>
  </div>
</template>

<script>
import { getTrackingData, setTrackedPremiumPurchase, hasTrackedPremiumAccess } from 'app/lib/paymentUtils'
export default {
  name: 'PaymentOnlineClassesSuccessView',
  data () {
    return {
      numStudents: null,
      selectedPlan: null
    }
  },
  created () {
    const query = this.$route.query
    this.selectedPlan = query.selectedPlan
    this.numStudents = query.numStudents
    const paymentTrackingData = getTrackingData({
      amount: query.amount,
      duration: query.duration
    })
    if (!hasTrackedPremiumAccess()) {
      window.tracker.trackEvent('Online classes purchase success', { selectedPlan: this.selectedPlan, numStudents: this.numStudents, ...paymentTrackingData })
      setTrackedPremiumPurchase()
    }
  }
}
</script>

<style scoped lang="sass">
#online-classes-success-view
  font-family: "Work Sans",sans-serif

  .head
    padding-bottom: 15px

    .head-text
      font-weight: bold

  .section
    padding: 10px 12%
</style>
