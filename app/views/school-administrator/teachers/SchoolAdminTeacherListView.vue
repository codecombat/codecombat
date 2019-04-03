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
</style>

<template>
    <div>
        <h2>{{ $t('school_administrator.my_teachers') }}</h2>

        <loading-progress :loading-status="loading.teachers">
            <div class="content">
                <ul class="teacher-list" v-for="(teachers, groupName) of groupedTeachers">
                    <li class="group-title">
                        <h4 v-if="groupName !== 'undefined'">{{ groupName }}</h4>
                        <h4 v-else>{{ $t('school_administrator.other') }}</h4>
                    </li>

                    <teacher-row v-for="teacher in teachers" :key="teacher.id" :teacher="teacher" />
                </ul>
            </div>
        </loading-progress>
    </div>
</template>

<script>
  import { mapActions, mapState } from 'vuex'

  import LoadingProgress from 'views/core/LoadingProgress'
  import DashboardTeacherRow from './SchoolAdminTeacherListRow'

  export default {
    components: {
      'loading-progress': LoadingProgress,
      'teacher-row': DashboardTeacherRow
    },

    created() {
      this.fetch()
    },

    computed: Object.assign({},
      mapState('schoolAdministrator', [
        'loading',
        'administratedTeachers'
      ]),

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


    methods: mapActions({
      fetch: 'schoolAdministrator/fetchTeachers'
    }),
  }
</script>
