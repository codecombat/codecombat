<template>
    <div></div>
</template>

<script>
  export default {
    props: {
      backboneView: Function,
      backboneOptions: Object,
      backboneArgs: Array
    },

    data: function () {
      return {
        backboneLoading: false,
        backboneLoadingProgress: 0,

        backboneViewInstance: undefined
      }
    },

    methods: {
      loadBackbone () {
        this.backboneViewInstance = new this.$props.backboneView(
          this.$props.backboneOptions,
          ...this.$props.backboneArgs,
        )

        this.backboneViewInstance.on('loading:show', this.showLoading)
        this.backboneViewInstance.on('loading:hide', this.hideLoading)
        this.backboneViewInstance.on('loading:progress', this.updateLoadingProgress)
      },

      renderBackbone () {
        this.$el.appendChild(this.backboneViewInstance.el)
      },

      cleanupBackbone () {
        this.backboneViewInstance.destroy()

        if (this.backboneView.el) {
          this.$el.removeChild(this.backboneViewInstance.el)
        }
      },

      showLoading: function () {
        this.backboneLoading = true
        this.emitLoadingEvent()
      },

      hideLoading: function () {
        this.backboneLoading = false
        this.emitLoadingEvent()
        console.log("got hide loading")
      },

      updateLoadingProgress: function (progress) {
        this.backboneLoadingProgress = progress;
        this.emitLoadingEvent()
      },

      emitLoadingEvent: function () {
        this.$emit('loading', {
          loading: true,
          progress: this.backboneLoadingProgress
        })
        console.log("emitted loading event")
      }
    },

    created () {
      console.log('created')
      this.loadBackbone()
    },

    mounted () {
      console.log('mounted')
      this.renderBackbone()
    },

    destroyed () {
      console.log('destroyed')
      // this.cleanupBackbone()
    },

    watch: {
      // TODO can you watch all props like this
      $props: function () {
        this.cleanupBackbone()
        this.loadBackbone()
        this.renderBackbone()
      }
    }
  }
</script>
