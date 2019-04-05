<style scoped>
    .title {
        margin-bottom: 20px;
   }

</style>

<template>
    <loading-progress :loading-status="loadingStatuses">
        <div v-if="!loading">
            <!-- TODO apply i18n to possessive -->
            <h3 class="title">{{ teacher.firstName }} {{ teacher.lastName }}'s {{ $t('courses.classes') }}</h3>

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

  export default {
    components: {
      'teacher-class-list': TeacherClassListView,
      'loading-progress': LoadingProgress
    },

    created() {
      this.fetchCourses()
      this.fetchTeacher(this.$route.params.id)
      this.fetchClassroomsForTeacher(this.$route.params.id)
      this.fetchCourseInstancesForTeacher(this.$route.params.id)
    },

    computed: Object.assign({},
      mapState('courses', {
        coursesLoaded: 'loaded'
      }),

      mapState('schoolAdministrator', {
        teacherLoading: s => s.loading.teacher,
        teacher: 'teacher'
      }),

      mapState('classrooms', {
        classroomsLoading: function (s) {
          return s.loading.byTeacher[this.$route.params.id]
        },

        classroomsForTeacher: function (s) {
          return s.classrooms.byTeacher[this.$route.params.id] || {}
        },

        activeClassrooms: function () {
          return this.classroomsForTeacher.active || []
        }
      }),

      mapState('courseInstances', {
        courseInstancesLoading: function (s) {
          return s.loading.byTeacher[this.$route.params.id]
        }
      }),

      {
        loadingStatuses: function () {
            return [ !this.coursesLoaded, this.teacherLoading, this.classroomsLoading, this.courseInstancesLoading ]
        },

        loading: function () {
          return this.loadingStatuses.reduce((r, i) => r || i, false)
        }
      }
    ),

    methods: mapActions({
      fetchCourses: 'courses/fetch',
      fetchTeacher: 'schoolAdministrator/fetchTeacher',
      fetchClassroomsForTeacher: 'classrooms/fetchClassroomsForTeacher',
      fetchCourseInstancesForTeacher: 'courseInstances/fetchCourseInstancesForTeacher'
    }),
  }
</script>
