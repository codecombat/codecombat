<script>
const moment = require('moment')
export default Vue.extend({
  name: 'LicenseStatsModal',
  props: ['hide', 'loading', 'redeemers', 'removedRedeemers', 'prepaid'],
  computed: {
    moment () {
      return moment
    }
  }
})

</script>

<template lang="pug">
#modal-base-flat
  .modal-content.style-flat
    span.glyphicon.glyphicon-remove.button.close(data-dismiss="modal")
    h3.modal-header.text-center {{ $t('teacher.license_stats') }}
    .modal-body
      .loading.text-center(v-if="!loading.finished") {{ $t('common.loading') }}
      .stats(v-else)
        .redeemers
          h4.title {{ $t('teacher.redeemers') }}
          .content(v-if="redeemers.length")
            .header
              .name {{ $t('general.name') }}
              .startDate {{ $t('outcomes.start_date') }}
              .endDate {{ $t('outcomes.end_date') }}
            .user(v-for="user in redeemers")
              .name {{ user.name }}
              .startDate {{ moment(user.date).format('ll') }}
              .endDate {{ moment(prepaid.get('endDate')).format('ll') }}
          .content(v-else)
            .header {{ $t('common.empty_results') }}
        .removedRedeemers
          h4.title {{ $t('teacher.removed_redeemers') }}
          .content(v-if="removedRedeemers.length")
            .header
              .name {{ $t('general.name') }}
              .startDate {{ $t('outcomes.start_date') }}
              .endDate {{ $t('outcomes.end_date') }}
            .user(v-for="user in removedRedeemers")
              .name {{ user.name }}
              .startDate {{ moment(user.startDate).format('ll') }}
              .endDate {{ moment(user.endDate).format('ll') }}
          .content(v-else)
            .header {{ $t('common.empty_results') }}
      .text-center.footer-text
        button.btn.btn-lg.btn-navy-alt(data-dismiss="modal")
          span.m-l-3.m-r-3
            | {{ $t("general.close_window") }}

</template>

<style scoped lang="scss">
#modal-base-flat {
  background: white;
  box-shadow: 0 3px 9px rgb(0 0 0 / 50%);
  font-size: 20px;
}

.stats {
  min-height: 400px;
  margin-bottom: 20px;

  .removedRedeemers {
    margin-top: 50px;
  }
  .user, .header {
    display: flex;

    .name, .startDate, .endDate {
      flex-basis: 10em;
    }
  }

  .header {
    font-weight: 800;
  }
  .user {
    &:nth-child(2n+1) {
      background-color: #ebebeb;
    }
    &:nth-child(2n) {
      background-color: #f5f5f5;
    }
  }
}
</style>
