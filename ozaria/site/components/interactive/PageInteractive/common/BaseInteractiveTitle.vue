<script>
  import { i18n } from 'app/core/utils'

  export default {
    props: {
      interactive: {
        type: Object,
        required: true
      }
    },

    computed: {
      interactiveTitle () {
        return i18n(this.interactive, 'promptText')
      }
    }
  }
</script>

<template>
  <div class="title-container">
    {{ interactiveTitle }}
  </div>
</template>

<style scoped>
  .title-container {
    padding: 30px;
    margin-bottom: 20px;

    width: 100%;

    border: 1px solid black;

    text-align: center;

    font-size: 30px;
    line-height: 30px;
  }
</style>
