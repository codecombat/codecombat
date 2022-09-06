<script>
const moment = require('moment')
export default Vue.extend({
  name: 'LicenseStatsModal',
  props: ['hide', 'loading', 'redeemers', 'removedRedeemers'],
  computed: {
    moment () {
      return moment
    }
  }
})

</script>

<template lang="pug">
#modal-base-flat
  .modal-header
    .loading(v-if="loading") {{ 'loading...' }}
    .loaded(v-else) {{ Stats }}
  .modal-body(v-if="!loading")
    .redeemers(v-if="redeemers.length")
      .title {{ 'Redeemers' }}
      .content
        .user(v-for="user in redeemers")
          .name {{ user.name }}
          .startDate {{ moment(user.date).format('ll') }}
    .removedRedeemers(v-if="removedRedeemers.length")
      .title {{ 'RemovedRedeemers' }}
      .content
        .user(v-for="user in redeemers")
          .name {{ user.name }}
          .startDate {{ moment(user.startDate).format('ll') }}
          .endDate {{ moment(user.endDate).format('ll') }}

</template>

<style scoped lang="scss">

#modal-base-flat {
  background: #F4FAFF;
  box-shadow: 2px 2px 2px 2px #777;
}

.user {
  display: flex;

  .name, .startDate, .endDate {
    flex-basis: 10em;
  }
}

</style>