<template>
  <div class="teachers-stats">
    <div class="month-select form-group">
      <label for="month">Select a Month:</label>
      <select
        v-model="month"
        class="form-control"
        name="month"
      >
        <option
          v-for="(m, index) in MONTHS"
          :key="m"
          :value="index"
        >
          {{ m }}
        </option>
      </select>
    </div>
    <user-search
      :role="'teacher'"
      :user-list="teachers"
      :value="selectedTeacher.name"
      :placeholder="'Search for a teacher...'"
      @select="selectTeacher"
      @clear-search="clearSearch"
    />
    <div class="table">
      <div class="table-title">
        <div
          v-for="t in statsTitles"
          :key="`table-title-${t}`"
          class="item"
        >
          {{ t }}
        </div>
      </div>
      <div
        v-for="(item, index) in filteredTeachers"
        :key="`table-row-${index}`"
        class="table-row"
        :class="{even: index % 2 === 0}"
      >
        <div class="item">
          {{ teacherNames[item._id] }}
        </div>
        <div
          v-for="k in statsKeys"
          :key="`table-row-${index}-${k}`"
          class="item"
        >
          {{ memberInfos[item._id]?.[k] || 0 }}
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex'
import moment from 'moment'
import UserSearch from './UserSearchComponent'
export default {
  name: 'TeachersStats',
  components: {
    UserSearch
  },
  props: {
    events: {
      type: Array,
      default: () => []
    }
  },
  data () {
    return {
      selectedTeacher: {},
      month: 0
    }
  },
  computed: {
    ...mapGetters({
      teacherIds: 'events/allTeacherIds',
      teacherNames: 'events/teacherNames'
    }),
    statsTitles () {
      return ['Teacher Name', 'Attend Lessons']
    },
    statsKeys () {
      // name comes from other object so not set here
      return ['attend']
    },
    teachers () {
      return this.teacherIds.map(m => ({
        _id: m
      }))
    },
    filteredTeachers () {
      if (this.selectedTeacher._id) {
        return this.teachers.filter(s => s._id === this.selectedTeacher._id)
      }
      return this.teachers
    },
    memberInfos () {
      console.log('get new memberinfos')
      if (this.teacherIds.length === 0) {
        return {}
      }
      const members = this.teacherIds.reduce((m, id) => {
        m[id] = {}
        return m
      }, {})
      const date = new Date()
      const firstDay = new Date(date.getFullYear(), this.month, 1)
      const lastDay = new Date(date.getFullYear(), this.month + 1, 0)
      this.events.forEach(e => {
        e.instances.forEach(i => {
          console.log('instance', i, firstDay, lastDay)
          if (new Date(i.startDate) < firstDay || new Date(i.startDate) > lastDay) {
            return
          }
          const instanceHours = Math.round((new Date(i.endDate) - new Date(i.startDate)) * 2 / 3600000) / 2
          members[i.owner].attend = (members[i.owner].attend || 0) + instanceHours
        })
      })
      return members
    },
    MONTHS () {
      return [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ]
    }
  },
  watch: {
    month () {
      this.$emit('month-change', this.month)
    }
  },
  mounted () {
    this.month = moment().month() - 1
  },
  methods: {
    clearSearch () {
      this.selectedTeacher = {}
    },
    selectTeacher (u) {
      this.selectedTeacher = u
    }
  }
}
</script>

<style lang="scss" scoped>
.table{
  border: 2px solid #379B8D;
  background-color: white;

  .table-title {
    display: flex;
    background: linear-gradient(90deg, #4C6AC7 0%, #476fb1 100%);
    color: white;
    height: 50px;
  }

  .table-row {
    display: flex;
    height: 50px;
  }
  .item {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 200px;
  }
  .even {
    background-color: rgba(116, 198, 223, 0.2);
  }
}
</style>
