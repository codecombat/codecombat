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
        <label for="name">Ladder</label>
        <input
          id="name"
          v-model="editableTournament.name"
          type="text"
          class="form-control"
          disabled
        >
        <template v-if="clanId">
          <label for="clan"> Team </label>
          <clan-selector
            :clans="ownedClans"
            :selected="idOrSlug"
            :label="false"
            style="margin-bottom: 40px;"
            @change="e => changeClanSelected(e)"
          />
        </template>
        <label for="description">Description</label>
        <input
          id="description"
          v-model="editableTournament.description"
          type="text"
          class="form-control"
        >
        <label for="startDate">Start Date</label>
        <input
          id="startDate"
          v-model="_startDate"
          type="datetime-local"
          class="form-control"
        >
        <label for="endDate">End Date</label>
        <input
          id="endDate"
          v-model="_endDate"
          type="datetime-local"
          class="form-control"
        >
        <label for="resultsDate">Results Date</label>
        <input
          id="resultsDate"
          v-model="_resultsDate"
          type="datetime-local"
          class="form-control"
        >
      </div>
      <div class="form-group pull-right">
        <span
          v-if="isSuccess"
          class="success-msg"
        >
          Success
        </span>
        <button
          class="btn btn-success btn-lg"
          type="submit"
          :disabled="inProgress"
        >
          Submit
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
        return ''
      }
    }
  },
  data () {
    return {
      editableTournament: {},
      isSuccess: false,
      inProgress: false
    }
  },
  computed: {
    ...mapGetters({
      myClans: 'clans/myClans'
    }),
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
    this.editableTournament = _.clone(this.tournament)
    console.log(this.editableTournament)
  },
  methods: {
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
