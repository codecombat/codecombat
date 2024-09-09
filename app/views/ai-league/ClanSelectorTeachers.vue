<script>
import QuestionmarkView from 'app/views/ai-league/QuestionmarkView.vue'
import ClassroomsApi from 'app/core/api/classrooms.js'

export default {
  components: {
    QuestionmarkView
  },
  props: {
    clans: {
      type: Array,
      required: false,
      default: () => ([])
    },

    selected: {
      type: String,
      required: false,
      default: ''
    },

    idOrSlug: {
      type: String,
      required: false,
      default: ''
    },

    label: {
      type: Boolean,
      default: () => true
    },
    disabled: {
      type: Boolean,
      default: () => false
    }
  },
  data () {
    return {
      ozClassrooms: []
    }
  },
  computed: {
    clansSanitized () {
      return this.clans.filter(v => v !== undefined).filter(v => !this.ozClassroomsSlugs.includes(v.slug))
    },
    ozClassroomsSlugs () {
      return this.ozClassrooms.map(c => `autoclan-classroom-${c._id}`)
    }
  },
  async created () {
    try {
      this.ozClassrooms = (await ClassroomsApi.fetchByOwner(me.get('_id'), { callOz: true, project: '_id' }))
    } catch (e) {
      console.error('Error fetching oz classrooms', e)
    }
  }
}
</script>

<template>
  <div class="clan-selector">
    <div class="label-and-link">
      <label for="clans">
        {{ $t('league.view_leaderboards_for_team') }}
      </label>
      <div class="team-container">
        <a
          :href="`/league${idOrSlug ? `/${idOrSlug}` : ''}`"
          target="_blank"
          class="view-team-page"
        >
          {{ $t('teacher_dashboard.view_team_page') }}
        </a>
        <questionmark-view />
      </div>
    </div>
    <select
      id="clans"
      name="clans"
      :disabled="disabled"
      @change="e => $emit('change', e)"
    >
      <option
        value="global"
        :selected="selected === ''"
      >
        {{ $t('league.global_stats') }}
      </option>
      <option
        v-for="clan in clansSanitized"
        :key="clan._id"
        :value="clan._id"
        :selected="selected === clan._id"
      >
        {{ clan.displayName || clan.name }}
      </option>
    </select>
  </div>
</template>

<style lang="scss" scoped>
.clan-selector {
  display: flex;
  flex-direction: row;
  gap: 10px;
}

.label-and-link {
  display: flex;
  flex-direction: column;
}

label {
  white-space: nowrap;
  color: #666;
  margin-bottom: 0;
}

select {
  flex-grow: 1;
  padding: 5px;
}

.view-team-page {
  text-decoration: none;
  color: #007bff;
  font-size: 0.8em;
  text-align: center;
  margin-right: 5px;

  &:hover {
    text-decoration: underline;
  }
}
.team-container {
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: center;
}
</style>