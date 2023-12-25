<script>
import moment from 'moment'
export default Vue.extend({
  data () {
    return {
      show: false,
      when: new Date('2022-10-20 16:00 CDT')
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
          <h3>[WEBINAR] Spooktacular CodeCombat & Ozaria Demo Day</h3>
          <h4>{{ whenDisplay }}</h4>
          <p>
            Please join us for an informative webinar covering curriculum and plaftform features. <a
              href="https://us06web.zoom.us/webinar/register/WN_NU2XXsQORZ-_lkx7rxUplQ"
              target="_blank"
            >Register here</a>.
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
#announcement {
  background-color: #cff2fc;
  border-radius: 10px;
  padding: 20px;
  margin: 20px 80px 40px 80px;
  text-align: center;
}
#announcement h3 {
  font-size: 30px;
}
#announcement h4 {
  margin-bottom: 16px;
}
#announcement p, #announcement ul {
  text-align: left;
}
#announcement p:last-of-type {
  margin-top: 32px;
  text-align: center;
}
</style>
