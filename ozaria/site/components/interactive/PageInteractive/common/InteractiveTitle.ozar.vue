<script>
  import { mapGetters } from 'vuex'

  import { internationalizeConfig } from '../../../../common/ozariaUtils'
  import FontScaler from '../../../common/FontScaler'

  export default {
    components: {
      FontScaler
    },

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
            <div>
                <font-scaler>
                    {{ localizedInteractive.promptText }}
                </font-scaler>
            </div>
        </div>
</template>

<style scoped>
  .title-container {
    padding: 15px 30px 15px 30px;

    height: 100px;
    max-height: 100px;
    width: 100%;

    display: flex;
    align-items: center;
    justify-content: center;

    background-image: linear-gradient(0deg, #6D8392 0%, #131B25 100%);
    border: 4px solid #18E6BD;

    color: #FFF;
    font-family: 'WorkSans-SemiBold', 'Works Sans', 'Open Sans', sans-serif;
    font-size: 1.4vw;
    letter-spacing: 0.82px;
  }
</style>
