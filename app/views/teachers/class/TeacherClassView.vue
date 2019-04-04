<template>
    <loading-progress :loading="loading" :progress="progress">
        <backbone-view v-if="!loading" :backbone-view="backboneViewInstance"></backbone-view>
    </loading-progress>
</template>

<script>
  import TeacherClassView from 'app/views/courses/TeacherClassView'
  import LoadingProgress from '../../core/LoadingProgress'

  const BackboneView = {
    props: {
      backboneView: Object
    },

    render: function () {},

    mounted() {
      this.$props.backboneView.render()
      this.$el.parentElement.appendChild(this.$props.backboneView.el)
    },
  }

  export default {
    components: {
      LoadingProgress,
      BackboneView
    },

    data: function () {
      return {
        loading: false,
        progress: 0,

        backboneViewInstance: new TeacherClassView(
          { vue: true, readOnly: true },
          this.$route.params.classroomId
        )
      }
    },

    methods: {
      showLoading: function () {
        this.loading = true
      },

      hideLoading: function () {
        this.loading = false
      },

      updateLoadingProgress: function (progress) {
        this.progress = progress
      }
    },

    created() {
      this.backboneViewInstance.on('loading:show', this.showLoading)
      this.backboneViewInstance.on('loading:hide', this.hideLoading)
      this.backboneViewInstance.on('loading:progress', this.updateLoadingProgress)
    },

    beforeDestroy() {
      this.backboneViewInstance.destroy()
    }
  }
</script>
