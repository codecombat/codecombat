<script>
  const { hexToHSL, hslToHex } = require('core/utils')

  export default Vue.extend({
    data: () => ({
      hex: ''
    }),

    computed: {
      hsl () {
        try {
          if (this.hex.length !== 7 || this.hex[0] !== '#')
            throw new Error('hex needs 7 characters')
          const [hue, saturation, lightness] = hexToHSL(this.hex);
          return { hue, saturation, lightness }
        } catch (_e) {
          return `Don't understand`
        }
      }
    }
  })
</script>

<template>
  <div class="calculator">
    <h2>Hex to HSL Tool</h2>
    <input v-model="hex" placeholder="#ffaa02"/>
    <p>{{ hsl }}</p>
  </div>
</template>

<style>
  .calculator {
    background-color: white;
    padding: 10px;
    float: left;
  }
</style>
