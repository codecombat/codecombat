<style scope>

</style>

<template>
    <h3 v-if="teacherLoading || classroomsLoading">{{ $t('common.loading') }}</h3>
    <div v-else>
        <!-- TODO apply i18n to possessive -->
        <h4>{{ teacher.firstName }} {{ teacher.lastName }}'s {{ $t('school_administrator.classes') }}</h4>
    </div>
</template>

<script>
  import { mapActions, mapState } from 'vuex'

  export default {
    created() {
      this.fetchCourses()
      this.fetchTeacher(this.$route.params.id)
      this.fetchTeacherClassrooms(this.$route.params.id)
      this.fetchCourseInstances(this.$route.params.id)
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
        classroomsLoading: s => s.loading.classrooms,
        teachers: 'teachers'
      }),

      mapState('courseInstances', {
        classroomsLoading: s => s.loading.classrooms,
        teachers: 'teachers'
      }),
    ),

    methods: mapActions({
      fetchTeacher: 'schoolAdministrator/fetchTeacher',
      fetchTeacherClassrooms: 'classrooms/fetchClassroomsForTeacher',
      fetchCourses: 'courses/fetch',
      fetchCourseInstances: 'courseInstances/fetchCourseInstancesForTeacher'
    }),
  }
</script>
