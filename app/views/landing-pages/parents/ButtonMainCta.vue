<template>
  <div class="container-background">
    <div class="container">
      <div class="row">
        <div class="col-lg-12 text-center">
          <button-main
              href="#"
              @click="$emit('click')"
              :buttonText="buttonText"
          />

        </div>
      </div>

      <div class="row subtext" v-if="subtext">
        <div class="col-lg-12 text-center" v-html="subtext"></div>
      </div>

    </div>
  </div>
</template>

<style scoped>

.subtext {
  margin-top: 15px;
  font-family: 'Work Sans', sans-serif;
  font-size: 16px;
  line-height: 24px;
  font-weight: 300;
  color: #131B25;
}

</style>

<script>
import ButtonMain from '../common/ButtonMain'

export default {
  components: {
    ButtonMain
  },
  props: {
    buttonText: {
      type: String,
      default: 'Schedule a Free Class'
    },
    subtext: {
      type: String,
      default: ''
    }
  }
}
</script>
