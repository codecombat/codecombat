<template lang="pug">
  .container
    .row
      .col-xs-12
        h1
          span API Dashboard - {{clientName}}

        <ApiData viewport="full"></ApiData>
</template>

<script>
  import { mapActions, mapState, mapGetters } from 'vuex'
  import ApiData from './ApiData'
  module.exports = Vue.extend({
    components: {
      ApiData
    },
    computed: {
      ...mapState('apiClient', {
        clientName: function (s) {
          return me.get('name').replace(/[0-9]*$/g, '')
        }
      }),
      ...mapGetters(
        'me', [
          'isAnonymous',
          'isAPIClient'
        ]
      ),
    },
    created() {
      if(!this.isAPIClient) {
        window.location.href = '/'
      }
    }
  })
</script>

<style lang="scss" scoped>
</style>
