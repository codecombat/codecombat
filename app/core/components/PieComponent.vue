<!--Src: https://www.npmjs.com/package/vue-pie-chart-->
<template>
  <svg :viewBox=viewBox>
    <circle
        cx=0
        cy=0
        r=1
        stroke="transparent"
        :stroke-width="strokeWidth / 5"
    />
    <path
        v-if=!circle
        :d=path
        :stroke=color
        :stroke-width="strokeWidth / 5"
        :opacity=opacity
    />
    <circle
        v-if=circle
        cx=0
        cy=0
        r=1
        :stroke=color
        :stroke-width="strokeWidth / 5"
        :opacity=opacity
    />
    <circle
      v-if=!circle
      cx=0
      cy=0
      :r="(width / 2) - 0.1"
      :stroke=color
      :stroke-width="0.2"
      :opacity=opacity
    />
  </svg>
</template>

<script>
  module.exports = Vue.extend({
    name: 'pie-chart',
    props: {
      ratio: Number,
      percent: {
        type: Number,
        default: 42
      },
      strokeWidth: {
        type: Number,
        default: 1,
        validator: (v) => v > 0 && v <= 10
      },
      color: {
        type: String,
        default: '#40a070'
      },
      opacity: {
        type: Number,
        default: 0.7
      }
    },
    computed: {
      width: function () {
        return 2 + this.strokeWidth / 5
      },
      viewBox: function () {
        let c = 1 + this.strokeWidth / 10
        let w = this.width
        return `${-c} ${-c} ${w} ${w}`
      },
      circle: function () {
        return this._ratio % 1 === 0
      },
      _ratio: function () {
        let r = this.percent / 100
        return isFinite(this.ratio) ? this.ratio : r
      },
      arc: function () {
        let r = this._ratio  // short hand
        let deg = 2 * Math.PI * r
        let x = 1 * Math.sin(deg)
        let y = -1 * Math.cos(deg)
        let negative = r < 0
        let large = 0
        // 0 ccw, 1 clock-wise
        let rotation = negative ? 0 : 1
        if (negative && x > 0) {
          large = 1
        } else if (!negative && x < 0) {
          large = 1
        }
        return `A 1 1 0 ${large} ${rotation} ${x} ${y}`
      },
      path: function () {
        return `M 0 -1 ${this.arc}`
      }
    },
  })

  function ratioOK (val) {
    return
  }
</script>

<style scoped>
  svg path, svg circle {
    fill: transparent;
  }
</style>
