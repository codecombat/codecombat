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
      myHeight () {
        return Math.min(this.parentWidth / this.aspectRatio, this.parentHeight)
      },

      myWidth () {
        return this.myHeight * this.aspectRatio
      }
    },

    mounted () {
      window.addEventListener('resize', this.onResize)
      this.onResize()
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

        this.$emit('resize')
      }
    }
  }
</script>

<template>
  <div
    ref="el"
    :style="{ width: myWidth + 'px', height: myHeight + 'px' }"
  >
    <slot />
  </div>
</template>
