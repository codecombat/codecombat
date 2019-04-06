<template>
    <loading-progress :loading-status="[ backboneLoading ]" :always-render="true">
        <backbone-view-harness
                :backbone-view="backboneViewInstance"
                :backbone-options="{ vue: true, readOnly: true }"
                :backbone-args="[ $route.params.classroomId ]"

                v-on:loading="backboneLoadingEvent"
        ></backbone-view-harness>
    </loading-progress>
</template>

<script>
  import TeacherClassView from 'views/courses/TeacherClassView'
  import LoadingProgress from 'views/core/LoadingProgress'
  import BackboneViewHarness from 'views/common/BackboneViewHarness'

  export default {
    components: {
      LoadingProgress,
      BackboneViewHarness
    },

    data: function () {
      return {
        backboneLoading: false,
        backboneViewInstance: TeacherClassView
      }
    },

    methods: {
      backboneLoadingEvent (event) {
        this.backboneLoading = event.loading
      }
    },
  }
</script>
