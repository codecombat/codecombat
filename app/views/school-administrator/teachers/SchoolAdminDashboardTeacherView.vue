<style scoped>
    .title {
        margin-bottom: 20px;
   }
</style>

<template>
    <h3 v-if="!coursesLoaded || teacherLoading || classroomsLoading || courseInstancesLoading">
        {{ $t('common.loading') }}
    </h3>

    <div v-else>
        <!-- TODO apply i18n to possessive -->
        <h3 class="title">{{ teacher.firstName }} {{ teacher.lastName }}'s {{ $t('courses.classes') }}</h3>

        <div class="teacher-class-list">
            <teacher-class-list :activeClassrooms="activeClassrooms"></teacher-class-list>
        </div>
    </div>
</template>

<script>
  import { mapActions, mapState } from 'vuex'

  import TeacherClassListView from 'app/views/teachers/classes/TeacherClassListView'

  export default {
    components: {
      'teacher-class-list': TeacherClassListView
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

        activeClassrooms: function (s) {
          return s.classrooms.byTeacher[this.$route.params.id].active
        }
      }),

      mapState('courseInstances', {
        courseInstancesLoading: function (s) {
          return s.loading.byTeacher[this.$route.params.id]
        }
      }),
    ),

    methods: mapActions({
      fetchCourses: 'courses/fetch',
      fetchTeacher: 'schoolAdministrator/fetchTeacher',
      fetchClassroomsForTeacher: 'classrooms/fetchClassroomsForTeacher',
      fetchCourseInstancesForTeacher: 'courseInstances/fetchCourseInstancesForTeacher'
    }),
  }
</script>
