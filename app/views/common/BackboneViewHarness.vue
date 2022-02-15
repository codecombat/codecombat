<template>
    <div></div>
</template>

<script>
  /**
   * Note a known limitation of this harness is that it does not support swapping out the following props
   * after initial render:
   *   - backboneView
   *   - backboneOptions
   *   - backboneArgs
   *
   * In order to change these you must unmount and remount the component.
   */
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
        this.backboneViewInstance.render()
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
      },

      updateLoadingProgress: function (progress) {
        this.backboneLoadingProgress = progress;
        this.emitLoadingEvent()
      },

      emitLoadingEvent: function () {
        this.$emit('loading', {
          loading: this.backboneLoading,
          progress: this.backboneLoadingProgress
        })
      }
    },

    created () {
      this.loadBackbone()
    },

    mounted () {
      this.renderBackbone()
    },

    destroyed () {
      this.cleanupBackbone()
    },
  }
</script>
