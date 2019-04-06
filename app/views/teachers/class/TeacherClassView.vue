<template>
    <loading-progress :loading-status="[ backboneLoadProgress ]" :always-render="true">
        <breadcrumbs v-if="!loading" :links="links"></breadcrumbs>
        <backbone-view-harness
                :backbone-view="backboneViewInstance"
                :backbone-options="{ vue: true, readOnly: true }"
                :backbone-args="[ $route.params.classroomId ]"

                v-on:loading="backboneLoadingEvent"
        ></backbone-view-harness>
    </loading-progress>
</template>

<script>
  import { mapActions, mapState } from 'vuex'
  import TeacherClassView from 'views/courses/TeacherClassView'
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
        backboneViewInstance: TeacherClassView,
        links: [{
          href: '/school-administrator',
          i18n: 'school_administrator.my_teachers'
        }, {
          href: `/school-administrator/teachers/${this.$route.teacherId}`,
          text: this.teacherName
        }, {
          text: this.classroom.name
        }]
      }
    },

    methods: Object.assign({},
      mapActions({
        fetchClassroomForId: 'classrooms/fetchClassroomsForId'
      }),
      {
        backboneLoadingEvent (event) {
          if (event.loading) {
            this.backboneLoadProgress = event.progress
          } else {
            this.backboneLoadProgress = 100
          }
        },
        showLoading: function () {
          this.loading = true
        },

        hideLoading: function () {
          this.loading = false
        },

        updateLoadingProgress: function (progress) {
          this.progress = progress
        },

        initialize: function () {
          this.fetchClassroomForId(this.$route.params.classroomId)
          this.fetchTeacherForId(this.$route.params.teacherId)
        }
      }
    ),

    computed: Object.assign({},
      mapState('classrooms', {
        // TODO: Improve loading in this file
        // classroomLoading: function (state) {
        //   return state.loading.byClassroom(this.$route.params.classroomId)
        // },
        classroom: function (state) {
          return state.classrooms.byClassroom(this.$route.params.classroomId)
        },
      }),
      // mapState('schoolAdministrator', {
      //   teacherLoading: function (state) {
      //     return state.loading.byTeacher(this.$route.params.teacherId)
      //   },
      //   teacherForId: function (state) {
      //     return state.teacher
      //   }
      // })
    ),

    created() {
      this.initialize()
    },

    updated() {
      this.initialize()
    }
  }
</script>
