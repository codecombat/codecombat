<script>
export default Vue.extend({
  data() {
    return {
      show: false,
      when: new Date('2021-05-26 13:00 PDT')
    }
  },
  created () {
    this.show = new Date() < new Date(this.when.getTime() + 60 * 60 * 1000)
    this.whenDisplay = moment(this.when).calendar(null, {sameElse: 'ddd MMM D, LT'})
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
          <h3>[WEBINAR] Lessons Learned from Distance Learning</h3>
          <h4>{{ whenDisplay }}</h4>
          <p>Please join us for an informative webinar about the mindsets, tools, and strategies that educators have learned during distance learning and leverage those ideas to come up with a framework for next year. <a href="https://bit.ly/2SMpy97" target="_blank">Register here</a>.</p>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
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
