<script>
  import { mapGetters } from 'vuex'

  import { internationalizeConfig } from '../../../../common/ozariaUtils'

  export default {
    props: {
      interactive: {
        type: Object,
        required: true
      }
    },

    computed: {
      ...mapGetters({
        userLocale: 'me/preferredLocale'
      }),

      localizedInteractive () {
        return internationalizeConfig(this.interactive, this.userLocale)
      }
    }
  }
</script>

<template>
  <div class="title-container">
    {{ localizedInteractive.promptText }}
  </div>
</template>

<style scoped>
  .title-container {
    padding: 30px;

    width: 100%;

    border: 1px solid black;

    text-align: center;

    font-size: 30px;
    line-height: 30px;
  }
</style>
