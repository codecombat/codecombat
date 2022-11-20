<script>
export default Vue.extend({
  data () {
    return {
      show: false,
      when: new Date('2022-12-01 14:00 PST')
    }
  },
  created () {
    this.show = new Date() < new Date(this.when.getTime() + 60 * 60 * 1000)
    this.whenDisplay = moment(this.when).calendar(null, { sameElse: 'ddd MMM D, LT' })
  }
})
</script>

<template>
  <div
      v-if="show"
      class="container"
  >
    <div class="row">
      <div class="col-xs-12">
        <div id="announcement">
          <p>
            Join us on {{ whenDisplay }} for our Hour of Code Walkthrough! Our team will take you through the latest
            activities and show you how you can best use them in your classroom.<br>
            <a href="https://us06web.zoom.us/webinar/register/WN_-KLRylhdRqaYB_qZ9IrzUw" target="_blank">
              Register here!
            </a>
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
#announcement p {
  margin: 14px;
  text-align: center;
}
</style>
