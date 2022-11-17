<template>
  <modal
    title="Create/Edit Tournament"
    @close="$emit('close')"
  >
    <form
      class="edit-tournament-form"
      @submit.prevent="onFormSubmit"
    >
      <div class="form-group">
        <label for="name">
          {{ $t('courses.arena') }}
        </label>
        <input
          id="name"
          v-model="editableTournament.name"
          type="text"
          class="form-control"
          disabled
        >
        <template v-if="clanId">
          <!-- TODO i18n -->
          <label for="clan"> Team </label>
          <span class="small text-navy">Team is required to create a tournament</span>
          <clan-selector
            :clans="ownedClans"
            :selected="selectedClanId"
            :label="false"
            :disabled="tournament.editing === 'edit'"
            @change="e => changeClanSelected(e)"
          />
        </template>
        <label for="startDate">
          {{ $t('tournament.start_date_time') }}
        </label>
        <span class="small text-navy"> {{ `(${timeZone})` + $t('tournament.start_date_description') }}</span>
        <input
          id="startDate"
          v-model="_startDate"
          type="datetime-local"
          class="form-control"
          :disabled="disableEdit"
        >
        <label for="endDate">
          {{ $t('tournament.end_date_time') }}
        </label>
        <span class="small text-navy">{{ `(${timeZone})` + $t('tournament.end_date_description') }}</span>
        <input
          id="endDate"
          v-model="_endDate"
          type="datetime-local"
          class="form-control"
          :disabled="disableEdit"
        >
        <label for="resultsDate">
          {{ $t('tournament.results_date_time') }}
        </label>
        <span class="small text-navy">{{ `(${timeZone})` + $t('tournament.results_date_description') }}</span>
        <input
          id="resultsDate"
          v-model="_resultsDate"
          type="datetime-local"
          class="form-control"
          :disabled="!me.isAdmin()"
        >
      </div>
      <div class="form-group pull-right">
        <span
          v-if="isSuccess"
          class="success-msg"
        >
          {{ $t('teacher.success') }}
        </span>
        <button
          class="btn btn-success btn-lg"
          type="submit"
          :disabled="inProgress || disableEdit"
        >
          {{ $t('common.submit') }}
        </button>
      </div>
    </form>
  </modal>
</template>

<script>
import _ from 'lodash'
import moment from 'moment'
import { mapGetters } from 'vuex'

import { postTournament, putTournament } from '../../../core/api/tournaments'

import Modal from '../../../components/common/Modal'
import ClanSelector from '../../landing-pages/league/components/ClanSelector.vue'

const OneDay = 86400000

const HTML5_FMT_DATETIME_LOCAL = 'YYYY-MM-DDTHH:mm' // moment 1.20+ do have this string but we use 1.19 :joy:

export default {
  name: 'EditTournamentModal',
  components: {
    Modal, ClanSelector
  },
  props: {
    tournament: {
      type: Object,
      default () {
        return {}
      }
    },
    clanId: {
      type: String,
      default () {
        return 'global'
      }
    }
  },
  data () {
    return {
      editableTournament: {},
      selectedClanId: 'global',
      isSuccess: false,
      inProgress: false
    }
  },
  computed: {
    ...mapGetters({
      myClans: 'clans/myClans'
    }),
    timeZone () {
      if (features?.chinaInfra) return '北京时间'
      return 'PT'
    },
    me () {
      return me
    },
    isNick () {
      return me.get('_id') === '512ef4805a67a8c507000001'
    },
    disableEdit () {
      if (this.selectedClanId === 'global') {
        // nick can create global-tournament
        return !this.isNick
      }
      // admin can create/edit any tournaments
      // normal teacher can only create/edit their own tournaments
      return !this.ownedClanById(this.selectedClanId) && !me.isAdmin()
    },
    ownedClans () {
      return this.myClans.filter(c => c?.ownerID === me.get('_id'))
    },
    _startDate: {
      get () {
        return moment(this.editableTournament.startDate).format(HTML5_FMT_DATETIME_LOCAL)
      },
      set (val) {
        this.editableTournament.startDate = new Date(val).toISOString()
      }
    },
    _endDate: {
      get () {
        return moment(this.editableTournament.endDate).format(HTML5_FMT_DATETIME_LOCAL)
      },
      set (val) {
        this.editableTournament.endDate = new Date(val).toISOString()

        this.editableTournament.resultsDate = new Date(new Date(val).getTime() + OneDay * 2).toISOString()
      }
    },
    _resultsDate: {
      get () {
        return moment(this.editableTournament.resultsDate).format(HTML5_FMT_DATETIME_LOCAL)
      },
      set (val) {
        this.editableTournament.resultsDate = new Date(val).toISOString()
      }
    }
  },
  mounted () {
    this.selectedClanId = this.tournament.clan
    this.editableTournament = _.clone(this.tournament)
    console.log(this.editableTournament)
  },
  methods: {
    ownedClanById (id) {
      return _.find(this.ownedClans, c => c?._id === id)
    },
    changeClanSelected (e) {
      this.selectedClanId = e.target.value
      this.editableTournament.clan = e.target.value
    },
    async onFormSubmit () {
      this.inProgress = true
      this.isSuccess = false
      console.log(this.editableTournament)
      try {
        if (this.editableTournament.editing === 'new') {
          await postTournament(this.editableTournament)
        } else if (this.editableTournament.editing === 'edit') {
          await putTournament(this.editableTournament)
        }

        this.isSuccess = true
      } catch (err) {
        console.error('tournament submit err', err)
        noty({ text: 'Failed to contact server, please reach out to support@codecombat.com', type: 'error', timeout: 5000, layout: 'topCenter' })
      }
      this.inProgress = false

      this.$emit('submit')
    }
  }
}
</script>

<style scoped lang="scss">
.edit-tournament-form {
  text-align: initial;
  padding: 2rem;
  width: 800px;
}

::v-deep .title {
  padding-top: 10px;
}

.success-msg {
  font-size: 1.6rem;
  color: #0B6125;
  display: inline-block;
  margin-right: 1rem;
}
</style>
