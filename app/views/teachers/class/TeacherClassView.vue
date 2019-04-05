<template>
    <loading-progress :loading-status="[ backboneLoadProgress ]" :always-render="true">
        <breadcrumbs v-if="!loading" v-bind:links="links"></breadcrumbs>
        <backbone-view-harness
                :backbone-view="backboneViewInstance"
                :backbone-options="{ vue: true, readOnly: true }"
                :backbone-args="[ $route.params.classroomId ]"

                v-on:loading="backboneLoadingEvent"
        ></backbone-view-harness>
    </loading-progress>
</template>

<script>
  import { mapState } from 'vuex'
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
          text: this.classroomName()
        }]
      }
    },

    methods: {
      backboneLoadingEvent (event) {
        if (event.loading) {
          this.backboneLoadProgress = event.progress
        } else {
          this.backboneLoadProgress = 100
        }
      },
      classroomName: function () {
        console.log('trying to get classroomName:')
        console.log(this.$route.params.classroomId)
        const classroom = new Classroom(this.$route.params.classroomId)
        console.log(classroom)
        console.log(classroom.get('name'))
        return classroom.get('name')
      }
    },

    computed: Object.assign({},
      mapState('schoolAdministrator', [
        'administratedTeachers'
      ]),

      {
        teacherName: () => {
          console.log('inside teacherName now!')
          console.log(this.administratedTeachers)
          const teacher = this.administratedTeachers.find(t => t.id === this.$route.teacherId)
          console.log(teacher)
          return teacher.firstName ? `${teacher.firstName} ${teacher.lastName}` : teacher.name
        }
      }
    ),
  }
</script>
