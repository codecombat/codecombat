<template>
  <loading-progress
    :loading-status="[ backboneLoadProgress ]"
    :always-render="true"
  >
    <breadcrumbs
      v-if="!breadcrumbsLoading"
      :links="breadcrumbs"
    />

    <backbone-view-harness
      :backbone-view="backboneViewInstance"
      :backbone-options="{ renderOnlyContent: true, readOnly: true }"
      :backbone-args="[ $route.params.classroomId, $route.params.studentId ]"
      @loading="backboneLoadingEvent"
    />
  </loading-progress>
</template>

<script>
  import { mapActions, mapState } from 'vuex'
  import TeacherStudentView from 'views/teachers/TeacherStudentView'
  import LoadingProgress from 'views/core/LoadingProgress'
  import BackboneViewHarness from 'views/common/BackboneViewHarness'
  import Breadcrumbs from '../../common/BreadcrumbComponent'

  export default {
    components: {
      LoadingProgress,
      BackboneViewHarness,
      Breadcrumbs
    },

    data: function () {
      return {
        backboneLoadProgress: 100,
        backboneViewInstance: TeacherStudentView
      }
    },

    computed: Object.assign(
      {},
      mapState('users', {
        teacherLoading: function (state) {
          return state.loading.byId[this.$route.params.teacherId]
        },
        teacher: function (state) {
          return state.users.byId[this.$route.params.teacherId]
        },
        studentLoading: function (state) {
          return state.loading.byId[this.$route.params.studentId]
        },
        student: function (state) {
          return state.users.byId[this.$route.params.studentId]
        }
      }),
      mapState('classrooms', {
        classroomLoading: function (state) {
          return state.loading.byClassroom[this.$route.params.classroomId]
        },
        classroom: function (state) {
          return state.classrooms.byClassroom[this.$route.params.classroomId]
        }
      }),
      {
        breadcrumbs: function () {
          return [{
            href: '/school-administrator',
            i18n: 'school_administrator.my_teachers'
          }, {
            href: `/school-administrator/teacher/${this.$route.params.teacherId}`,
            text: this.teacher.firstName ? `${this.teacher.firstName} ${this.teacher.lastName}` : this.teacher.name
          }, {
            href: `/school-administrator/teacher/${this.$route.params.teacherId}/classroom/${this.$route.params.classroomId}`,
            text: this.classroom.name
          }, {
            text: this.student.firstName ? `${this.student.firstName} ${this.student.lastName}` : this.student.name
          }]
        },

        breadcrumbsLoading: function () {
          return (this.teacherLoading || this.classroomLoading || this.studentLoading)
        }
      }
    ),

    created () {
      this.fetchUserById(this.$route.params.teacherId)
      this.fetchUserById(this.$route.params.studentId)
      this.fetchClassroomForId(this.$route.params.classroomId)
    },

    methods: Object.assign(
      {},
      mapActions({
        fetchUserById: 'users/fetchUserById',
        fetchClassroomForId: 'classrooms/fetchClassroomForId'
      }),
      {
        backboneLoadingEvent (event) {
          if (event.loading) {
            this.backboneLoadProgress = event.progress
          } else {
            this.backboneLoadProgress = 100
          }
        },
        updateLoadingProgress: function (progress) {
          this.progress = progress
        }
      }
    )
  }
</script>
