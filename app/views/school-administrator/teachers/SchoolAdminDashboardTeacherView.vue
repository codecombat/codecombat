<style scoped>
    .title {
        margin-bottom: 8px;
    }
</style>

<template>
    <h3 v-if="!coursesLoaded || teacherLoading || classroomsLoading || courseInstancesLoading || levelSessionsLoading">
        {{ $t('common.loading') }}
    </h3>

    <div v-else>
        <!-- TODO apply i18n to possessive -->
        <h4 class="title">{{ teacher.firstName }} {{ teacher.lastName }}'s {{ $t('school_administrator.classes') }}</h4>

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
      this.fetchTeacherClassrooms(this.$route.params.id)
      this.fetchCourseInstances(this.$route.params.id)

      // TODO fetch level sessions for classrooms
      // TODO make level session loading flag based off of all classroom loading states
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
        activeClassrooms: s => s.classrooms.active
      }),

      mapState('courseInstances', {
        courseInstancesLoading: s => s.loading.classrooms,
      }),

      mapState('levelSessions', {
        levelSessionsLoading: s => s.loading.sessions,
        levelSessions: 'levelSessions'
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
