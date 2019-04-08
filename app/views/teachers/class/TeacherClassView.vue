<template>
    <loading-progress :loading-status="[ backboneLoadProgress ]" :always-render="true">
        <breadcrumbs :links="links"></breadcrumbs>
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
          // TODO: Replace this silliness
        }, {}, {}]
      }
    },

    computed: Object.assign({},
      mapState('users', {
        // teacherLoading: function (state) {
        //   console.log('trying for teacherId')
        //   console.log(this.$route.params.teacherId)
        //   return state.loading.byId[this.$route.params.teacherId]
        // },
        teacher: function (state) {
          console.log('trying for teacherId')
          console.log(this.$route.params.teacherId)
          return state.users.byId[this.$route.params.teacherId]
        }
      }),
      mapState('classrooms', {
        // classroomLoading: function (state) {
        //   console.log('trying for classroomId')
        //   console.log(this.$route.params.classroomId)
        //   return state.loading.byClassroom[this.$route.params.classroomId]
        // },
        classroom: function (state) {
          console.log('trying for classroomId')
          console.log(this.$route.params.classroomId)
          return state.classrooms.byClassroom[this.$route.params.classroomId]
        },
      })
    ),

    methods: Object.assign({},
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
    ),

    created() {
      console.log('in created trying for teacherId:')
      console.log(this.$route.params.teacherId)
      console.log('in created trying for classroomId:')
      console.log(this.$route.params.classroomId)
      this.fetchUserById(this.$route.params.teacherId)
      this.fetchClassroomForId(this.$route.params.classroomId)
    },

    // TODO: Does not work
    updated() {
      if (!this.links) {
        if (this.teacher) {
          this.links[1] = {
            href: `/school-administrator/teachers/${this.$route.teacherId}`,
            text: this.teacher.firstName ? `${this.teacher.firstName} ${this.teacher.lastName}` : this.teacher.name
          }
        }
        if (this.classroom) {
          this.links[2] = {
            text: this.classroom.name
          }
        }
      }
    }
  }
</script>
