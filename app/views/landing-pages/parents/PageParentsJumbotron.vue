<script>
import ButtonScheduleFreeClass from './ButtonScheduleFreeClass'

export default {
  components: {
    ButtonScheduleFreeClass
  },

  methods: {
    onCtaClick () {
      this.$emit('cta-clicked')
    }
  }
}
</script>

<template>
  <div class="top-jumbotron">
    <div class="row">
      <div class="col-lg-12">
        <h1>Live Online Coding Classes</h1>
        <h1>Your Child Will Love</h1>
      </div>
    </div>
    <div class="row">
      <div class="col-lg-12">
        <button-schedule-free-class
          @click="onCtaClick"
        />
      </div>
    </div>
  </div>

</template>

<style scoped>
  .top-jumbotron {
    margin-bottom: 0;
    min-height: 580px;

    padding-top: 155px;

    background-color: unset;

    position: relative;
    z-index: 2;

    text-align: center;
    min-height: 628px;
  }

  .top-jumbotron h1 + h1 {
    margin-bottom: 58px;
  }

  .top-jumbotron .button {
    margin-top: 30px;
    max-width: 320px;
  }

</style>
