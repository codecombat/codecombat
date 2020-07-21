<template>
</template>

<script>
  /**
   * Note a known limitation of this harness is that it does not support swapping out the following props
   * after initial render:
   *   - modalView
   *   - modalOptions
   *   - modalArgs
   *
   * In order to change these you must unmount and remount the component.
   */
  export default {
    inject: ['openLegacyModal', 'legacyModalClosed'],

    props: {
      modalView: Function,

      modalOptions: {
        type: Object,
        default: () => ({}),
      },

      modalArgs: {
        type: Array,
        default: () => ([]),
      },

      open: {
        type: Boolean,
        default: true
      }
    },

    data: function () {
      return {
        modalLoading: false,
        modalLoadingProgress: 0,

        modalViewInstance: undefined
      }
    },

    methods: {
      loadModal () {
        if (this.modalViewInstance) {
          return
        }

        this.modalViewInstance = new this.$props.modalView(
          this.$props.modalOptions,
          ...this.$props.modalArgs,
        )

        this.modalViewInstance.on('shown', this.emitShownEvent)
        this.modalViewInstance.on('loading:show', this.showLoadingEvent)
        this.modalViewInstance.on('loading:hide', this.hideLoadingEvent)
        this.modalViewInstance.on('loading:progress', this.updateLoadingProgressEvent)
        this.modalViewInstance.on('hide', this.modalHideEvent)
        this.modalViewInstance.on('hidden', this.modalHideEvent)
      },

      openModal () {
        this.loadModal()
        this.openLegacyModal(this.modalViewInstance)
      },

      closeModal() {
        if (!this.modalViewInstance) {
          return
        }

        const viewInstance = this.modalViewInstance

        this.cleanupModal()
        viewInstance.destroy()
      },

      cleanupModal () {
        this.modalViewInstance.off('shown', this.emitShownEvent)
        this.modalViewInstance.off('loading:show', this.showLoadingEvent)
        this.modalViewInstance.off('loading:hide', this.hideLoadingEvent)
        this.modalViewInstance.off('loading:progress', this.updateLoadingProgressEvent)
        this.modalViewInstance.off('hide', this.modalHideEvent)
        this.modalViewInstance.off('hidden', this.modalHideEvent)

        this.modalViewInstance = undefined
      },

      showLoadingEvent: function () {
        this.modalLoading = true
        this.emitLoadingEvent()
      },

      hideLoadingEvent: function () {
        this.modalLoading = false
        this.emitLoadingEvent()
      },

      updateLoadingProgressEvent: function (progress) {
        this.modalLoadingProgress = progress;
        this.emitLoadingEvent()
      },

      emitLoadingEvent: function () {
        this.$emit('loading', {
          loading: this.modalLoading,
          progress: this.modalLoadingProgress
        })
      },

      modalHideEvent: function () {
        this.$emit('close')
        this.cleanupModal()
      },

      emitShownEvent: function () {
        this.$emit('shown')
      }
    },

    created () {
      if (this.open) {
        this.loadModal()
      }
    },

    mounted () {
      if (this.open) {
        this.openModal()
      }
    },

    destroyed () {
      this.closeModal()
    },

    watch: {
      open: function (newValue, oldValue) {
        if (newValue !== oldValue) {
          if (newValue) {
            this.openModal()
          } else {
            this.closeModal()
          }
        }
      },
    }
  }
</script>
