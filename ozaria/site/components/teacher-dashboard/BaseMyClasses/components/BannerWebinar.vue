<script>
  import moment from 'moment'

  export default Vue.extend({
    data () {
      return {
        show: false
      }
    },

    created () {
      this.show = moment().isBefore('2020-11-17 16:30-05:00')
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
          <h3>{{ $t('banner_webinar.heading') }}</h3>
          <h4>{{ $t('banner_webinar.time') }}</h4>

          <p v-html="$t('banner_webinar.abstract')" />

          <ul>
            <li>{{ $t('banner_webinar.bullet_1') }}</li>
            <li>{{ $t('banner_webinar.bullet_2') }}</li>
            <li>{{ $t('banner_webinar.bullet_3') }}</li>
          </ul>

          <p v-html="$t('banner_webinar.learn_more')" />
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
