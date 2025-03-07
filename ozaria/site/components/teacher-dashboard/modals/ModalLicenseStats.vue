<script>
import moment from 'moment'
import Modal from '../../common/Modal'
import SecondaryButton from '../common/buttons/SecondaryButton'

import { mapGetters, mapActions } from 'vuex'
export default Vue.extend({
  components: {
    Modal,
    SecondaryButton
  },
  props: ['prepaid'],
  computed: {
    ...mapGetters({
      getName: 'users/getUserNameById',
      getClassName: 'users/getClassroomsByUserId',
    }),
    me () {
      return me
    },
    moment () {
      return moment
    },
    redeemers () {
      return (this.prepaid.redeemers || []).map(redeemer => {
        redeemer.name = this.getName(redeemer.userID)
        return redeemer
      })
    },
    removedRedeemers () {
      return (this.prepaid.removedRedeemers || []).map(removedRedeemer => {
        removedRedeemer.name = this.getName(removedRedeemer.userID)
        return removedRedeemer
      })
    },
    userIds () {
      return [...this.redeemers.map(r => r.userID), ...this.removedRedeemers.map(r => r.userID)]
    },
  },
  methods: {
    ...mapActions({
      fetchName: 'users/fetchUserNamesById',
      fetchClassrooms: 'users/fetchClassroomNamesByUserId',
    }),
    trackEvent (eventName) {
      if (eventName) {
        window.tracker?.trackEvent(eventName, { category: 'Teachers' })
      }
    },
    top2ClassForUser (id) {
      const classrooms = [...(this.getClassName(id) || [])]
      classrooms.sort((a, b) => {
        if (a.ownerID === me.id) {
          return -1
        }
        if (b.ownerID === me.id) {
          return 1
        }
        return 0
      })
      return classrooms.slice(0, 2)
    },
  },
  mounted () {
    this.fetchName(this.userIds)
    this.fetchClassrooms(this.userIds)
  },
})
</script>

<template lang="pug">
  modal(:title="$t('teacher.license_stats')" @close="$emit('close')")
    .license-stats
      .redeemers
        h4.title {{ $t('teacher.redeemers') }}
        .content(v-if="redeemers.length")
          .header
            .name {{ $t('general.name') }}
            .startDate {{ $t('outcomes.start_date') }}
            .endDate {{ $t('outcomes.end_date') }}
            .classrooms {{ $t('general.classrooms') }}
          .user(v-for="user in redeemers")
            .name {{ user.name }}
            .startDate {{ moment(user.date).format('ll') }}
            .endDate {{ moment(prepaid.endDate).format('ll') }}
            .classrooms
              div(v-for='cls in top2ClassForUser(user.userID)')
                a(v-if="cls.ownerID === me.id" :href="'/teachers/classes/' + cls._id") {{ cls.name }}
                span(v-else) {{ cls.name }}
              template(v-if="getClassName(user.userID)?.length > 2") {{ $t('teachers.and_more') }}

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
</template>

<style lang="scss" scoped>
.license-stats {
  min-width: 600px;
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
