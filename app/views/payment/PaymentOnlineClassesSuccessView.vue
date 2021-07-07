<template>
  <div class="container-fluid" id="success-view">
    <div class="container">
      <div class="head text-center">
        <h2 class="head-text">Congratulations</h2>
        <h2 class="head-text">Your student's coding adventure awaits</h2>
      </div>
      <div v-if="selectedPlan && numStudents" class="section">
        You are confirmed for {{selectedPlan}} for {{numStudents}} {{ numStudents > 1 ? 'students' : 'student' }}
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
export default {
  name: "PaymentOnlineClassesSuccessView",
  data() {
    return {
      numStudents: null,
      selectedPlan: null,
    };
  },
  created() {
    const search = window.location.search;
    const params = new URLSearchParams(search)
    this.selectedPlan = decodeURI(params.get('selectedPlan'))
    this.numStudents = params.get('numStudents')
  }
}
</script>

<style scoped lang="sass">
#success-view
  font-family: "Work Sans",sans-serif

  .head
    padding-bottom: 15px

    .head-text
      font-weight: bold

  .section
    padding: 10px 12%
</style>
