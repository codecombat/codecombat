<template>
  <div class="students-stats">
    <user-search
      :role="'student'"
      :user-list="students"
      :value="selectedStudent.name"
      :placeholder="'Search for a student...'"
      @select="selectStudent"
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
        v-for="(item, index) in filteredStudents"
        :key="`table-row-${index}`"
        class="table-row"
        :class="{even: index % 2 === 0}"
      >
        <div class="item">
          {{ memberNames[item._id]?.name }}
        </div>
        <div
          v-for="k in statsKeys"
          :key="`table-row-${index}-${k}`"
          class="item"
        >
          {{ memberInfos[item._id]?.[k] }}
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
  name: 'StudentsStats',
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
      selectedStudent: {}
    }
  },
  computed: {
    ...mapGetters({
      memberIds: 'events/allMemberIds',
      memberNames: 'events/memberNames'
    }),
    statsTitles () {
      return ['Student Name', 'Start Date', 'Total Lessons', 'Attend hours', 'Lessons left', 'End Date']
    },
    statsKeys () {
      // name comes from other object so not set here
      return ['start', 'total', 'attend', 'left', 'end']
    },
    students () {
      return this.memberIds.map(m => ({
        _id: m
      }))
    },
    filteredStudents () {
      if (this.selectedStudent._id) {
        return this.students.filter(s => s._id === this.selectedStudent._id)
      }
      return this.students
    },
    memberInfos () {
      if (this.memberIds.length === 0) {
        return {}
      }
      const members = this.memberIds.reduce((m, id) => {
        m[id] = {}
        return m
      }, {})
      this.events.forEach(e => {
        e.members.forEach(m => {
          members[m.userId].total = (members[m.userId].total || 0) + m.count
        })
        e.instances.forEach(i => {
          const instanceHours = Math.round((new Date(i.endDate) - new Date(i.startDate)) * 2 / 3600000) / 2
          i.members.forEach(m => {
            if (m.attendance) {
              members[m.userId].attend = (members[m.userId].attend || 0) + instanceHours
              if (members[m.userId].start) {
                members[m.userId].start = members[m.userId].start.isBefore(i.startDate) ? members[m.userId].start : moment(i.startDate)
              } else {
                members[m.userId].start = moment(i.startDate)
              }
            }
          })
        })
      })
      Object.keys(members).forEach(id => {
        if (members[id].start) {
          members[id].left = members[id].total - members[id].attend
          members[id].end = members[id].start.clone().add(members[id].left, 'weeks').format('ll')
          members[id].start = members[id].start.format('ll')
        } else {
          members[id].start = 'Not Start'
          members[id].left = members[id].total
          members[id].attend = 0
          members[id].end = 'Maybe ' + moment().add(members[id].left, 'weeks').format('ll')
        }
      })
      return members
    }
  },
  watch: {
    memberIds () {
      this.getMemberNames()
    }
  },
  mounted () {
    this.getMemberNames()
  },
  methods: {
    ...mapActions({
      getMemberNames: 'events/fetchMemberNames'
    }),
    clearSearch () {
      this.selectedStudent = {}
    },
    selectStudent (u) {
      this.selectedStudent = u
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
