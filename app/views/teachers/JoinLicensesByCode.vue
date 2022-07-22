<script>
  const fetchJson = require('../../core/api/fetch-json')
  export default {
    data () {
      return {
        state: 'loading',
        result: {}
      }
    },
    methods: {
      post () {
        fetchJson('/db/prepaids/-/join-by-code', {
          method: 'POST',
          json: this.$route.query
        }).then((res) => {
          let state = 'success'
          for(let code in res) {
            if(!res[code] || typeof res[code] == 'string') {
              state = 'partly-failed'
              break
            }
          }
          this.result = res
          this.state = state

          if(state == 'success') {
            setTimeout(() => {
              application.router.navigate('/teachers/licenses', {trigger: true})
            }), 3000
          }
        })
      }
    }
    mounted () {
      if(this.$route.query.codes) {
        this.post()
      } else {
        application.router.navigate('/teachers/licenses', {trigger: true})
      }
    }
  }
</script>

<template lang="pug">
  div
    .progress.progress-striped.active(v-if="state === 'loading'")
      .progress-bar(style="width: 100%")
    .alert.alert-success(v-if="state === 'success'") Licenses have been Activated Successfully!
    .alert.alert-failed(v-if="state === 'partly-failed'")
      .status(v-for="(res, code) in result")
        .code {{ code }}:
        .status {{ res }}
</template>

<style scoped>
</style>