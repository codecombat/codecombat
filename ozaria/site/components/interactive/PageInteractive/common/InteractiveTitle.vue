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
    padding: 15px 30px 15px 30px;

    height: 100px;
    width: 100%;

    display: flex;
    align-items: center;
    justify-content: center;

    background: url('/images/ozaria/interactives/prompt_background.png');
    background-size: cover;

    color: #1FBAB4;
    font-family: 'Works Sans', 'Open Sans', sans-serif;
    font-size: 24px;
    letter-spacing: 0.48px;
    line-height: 30px;
  }
</style>
