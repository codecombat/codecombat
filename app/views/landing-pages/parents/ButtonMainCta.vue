<template>
  <div class="container-background">
    <div class="container">
      <div class="row">
        <div class="col-lg-12 text-center">
          <button-main
            href="#"
            :button-text="buttonText"
            @click="$emit('click')"
          />
        </div>
      </div>

      <div
        v-if="subtext"
        class="row subtext"
      >
        <div
          class="col-lg-12 text-center"
          v-html="subtext"
        />
      </div>
    </div>
  </div>
</template>

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
