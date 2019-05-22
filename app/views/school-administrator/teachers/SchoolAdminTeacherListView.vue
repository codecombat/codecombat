<script>
  import { mapActions, mapState } from 'vuex'

  import LoadingProgress from 'views/core/LoadingProgress'
  import DashboardTeacherRow from './SchoolAdminTeacherListRow'

  export default {
    components: {
      'loading-progress': LoadingProgress,
      'teacher-row': DashboardTeacherRow
    },

    computed: Object.assign(
      {},
      mapState('schoolAdministrator', {
        teachersLoading: s => s.loading.teachers,
        administratedTeachers: s => s.administratedTeachers || []
      }),

      {
        groupedTeachers: function () {
          const groupedTeachers = {}

          for (const teacher of this.administratedTeachers) {
            const trialRequest = teacher._trialRequest || {}

            groupedTeachers[trialRequest.organization] = groupedTeachers[trialRequest.organization] || []
            groupedTeachers[trialRequest.organization].push(teacher)
          }

          return Object.freeze(groupedTeachers)
        }
      }
    ),

    created () {
      this.fetch()
    },

    methods: mapActions({
      fetch: 'schoolAdministrator/fetchTeachers'
    })
  }
</script>

<style scoped>
    .teacher-list {
        margin: 0;
        margin-top: 15px;

        padding: 0;

        list-style: none;
    }

    .teacher-list .group-title {
        margin-bottom: 15px;
    }

    .school-admin-details {
        margin-top: 35px;

        text-align: center;

        font-size: 13px;
        color: #BBB;
        line-height: 20px;
    }

    .no-teachers {
        padding: 50px;
        text-align: center;
    }
</style>

<template>
  <div>
    <h3>{{ $t('school_administrator.my_teachers') }}</h3>

    <loading-progress :loading-status="teachersLoading">
      <div class="content">
        <ul
          v-for="(teachers, groupName) of groupedTeachers"
          :key="groupName"
          class="teacher-list"
        >
          <li class="group-title">
            <h4 v-if="groupName">
              {{ groupName }}
            </h4>
            <h4 v-else>
              {{ $t('school_administrator.other') }}
            </h4>
          </li>

          <teacher-row
            v-for="teacher in teachers"
            :key="teacher.id"
            :teacher="teacher"
          />
        </ul>

        <div
          v-if="administratedTeachers.length === 0"
          class="no-teachers"
        >
          {{ $t('school_administrator.no_teachers') }}
        </div>
      </div>

      <div class="school-admin-details">
        {{ $t('school_administrator.add_additional_teacher') }}

        <p />

        {{ $t('school_administrator.license_stat_description') }} <br>
        {{ $t('school_administrator.students_stat_description') }} <br>
        {{ $t('school_administrator.active_students_stat_description') }} <br>
        {{ $t('school_administrator.project_stat_description') }}
      </div>
    </loading-progress>
  </div>
</template>
