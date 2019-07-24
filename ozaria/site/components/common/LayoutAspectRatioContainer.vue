<script>
  export default {
    props: {
      aspectRatio: {
        required: true,
        type: Number
      }
    },

    data () {
      return {
        parentWidth: 0,
        parentHeight: 0
      }
    },

    computed: {
      finalHeight () {
        return Math.min(this.parentWidth / this.aspectRatio, this.parentHeight)
      },

      finalWidth () {
        return this.finalHeight * this.aspectRatio
      }
    },

    mounted () {
      window.addEventListener('resize', this.onResize)
      this.onResize()
      this.$nextTick(() => this.onResize())
    },

    beforeDestroy () {
      window.removeEventListener('resize', this.onResize)
    },

    methods: {
      onResize (e) {
        const parent = this.$refs.el.parentElement
        if (!parent) {
          throw new Error('Element does not have parent')
        }

        const boundingRect = parent.getBoundingClientRect()

        if (boundingRect) {
          this.parentWidth = boundingRect.width
          this.parentHeight = boundingRect.height
        } else {
          this.parentWidth = parent.clientWidth
          this.parentHeight = parent.clientHeight
        }

        const computedStyle = window.getComputedStyle(parent)
        const paddingLeft = parseInt(computedStyle.getPropertyValue('padding-left') || 0, 10)
        const paddingRight = parseInt(computedStyle.getPropertyValue('padding-right') || 0, 10)
        const paddingTop = parseInt(computedStyle.getPropertyValue('padding-top') || 0, 10)
        const paddingBottom = parseInt(computedStyle.getPropertyValue('padding-bottom') || 0, 10)

        this.parentWidth = this.parentWidth - paddingLeft - paddingRight
        this.parentHeight = this.parentHeight - paddingTop - paddingBottom

        this.$emit('resize')
      }
    }
  }
</script>

<template>
  <div
    ref="el"
    :style="{ width: finalWidth + 'px', height: finalHeight + 'px' }"
    class="aspect-ratio-container"
  >
    <slot />
  </div>
</template>

<style lang="sass" scoped>
  .aspect-ratio-container
    position: relative
</style>
