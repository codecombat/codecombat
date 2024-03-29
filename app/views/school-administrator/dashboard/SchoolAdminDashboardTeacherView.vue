<style scoped>
    .title {
        margin-bottom: 20px;
   }
</style>

<template>
    <loading-progress :loading-status="loadingStatuses">
        <div v-if="!loading">
            <breadcrumbs :links="breadcrumbs"></breadcrumbs>
            <!-- TODO apply i18n to possessive -->
            <h3 class="title">
              {{ broadName(teacher) }}'s {{ $t('courses.classes') }}
              <a class="pull-right" :href="`/outcomes-report/teacher/${teacherId}`" target="_blank">{{ $t('outcomes.view_outcomes_report') }}</a>
            </h3>

            <div class="teacher-class-list">
                <teacher-class-list :activeClassrooms="activeClassrooms"></teacher-class-list>
            </div>
        </div>
    </loading-progress>
</template>

<script>
import { mapActions, mapState } from 'vuex'

import LoadingProgress from 'app/views/core/LoadingProgress'
import TeacherClassListView from 'app/views/teachers/classes/TeacherClassListView'
import Breadcrumbs from '../../common/BreadcrumbComponent'
import User from '../../../models/User'

export default {
    components: {
      'teacher-class-list': TeacherClassListView,
      'loading-progress': LoadingProgress,
      Breadcrumbs
    },

    created() {
      this.fetchCourses()
      this.fetchTeacher(this.$route.params.teacherId)
      this.fetchClassroomsForTeacher({ teacherId: this.$route.params.teacherId })
      this.fetchCourseInstancesForTeacher(this.$route.params.teacherId)
    },

    computed: Object.assign({
        teacherId() {
          return this.$route.params.teacherId
        },
      },
      mapState('courses', {
        coursesLoaded: 'loaded'
      }),

      mapState('users', {
        teacherLoading: function (s) {
          return s.loading.byId[this.$route.params.teacherId]
        },

        teacher: function (s) {
          return s.users.byId[this.$route.params.teacherId]
        }
      }),

      mapState('classrooms', {
        classroomsLoading: function (s) {
          return s.loading.byTeacher[this.$route.params.teacherId]
        },

        classroomsForTeacher: function (s) {
          return s.classrooms.byTeacher[this.$route.params.teacherId] || {}
        },

        activeClassrooms: function () {
          return this.classroomsForTeacher.active || []
        }
      }),

      mapState('courseInstances', {
        courseInstancesLoading: function (s) {
          return s.loading.byTeacher[this.$route.params.teacherId]
        }
      }),

      {
        loadingStatuses: function () {
            return [ !this.coursesLoaded, this.teacherLoading, this.classroomsLoading, this.courseInstancesLoading ]
        },

        loading: function () {
          return this.loadingStatuses.reduce((r, i) => r || i, false)
        },

        breadcrumbs: function () {
          return [{
            href: '/school-administrator',
            i18n: 'school_administrator.my_teachers'
          }, {
            text: User.broadName(this.teacher)
          }]
        }
      }
    ),

    methods: {
      broadName: User.broadName,
      ...mapActions({
        fetchCourses: 'courses/fetch',
        fetchTeacher: 'users/fetchUserById',
        fetchClassroomsForTeacher: 'classrooms/fetchClassroomsForTeacher',
        fetchCourseInstancesForTeacher: 'courseInstances/fetchCourseInstancesForTeacher'
      })
    },
  }
</script>
