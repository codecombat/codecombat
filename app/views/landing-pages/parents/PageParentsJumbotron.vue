<template>
  <div class="jumbotron">
    <div class="row">
      <div class="col-lg-12">
        <h1>Live Online Coding Classes</h1>
        <h1>Your Child Will Love</h1>
      </div>
    </div>
    <div class="row">
      <div class="col-lg-12">
        <a href="#" class="full-width button" @click="onCtaClick">
          Schedule a Free Class
        </a>
      </div>
    </div>
  </div>

</template>

<script>
export default {
  methods: {
    onCtaClick (e) {
      e.preventDefault()
      this.$emit('cta-clicked')
    }
  }
}
</script>

<style scoped>
  .jumbotron {
    padding: 70px;
    margin-bottom: 0;
    min-height: 580px;

    background-size: cover;
    background-repeat: no-repeat;
    background-position: center;

    position: relative;
    z-index: 2;

    text-align: center;
  }

  .jumbotron h1 {
    margin-bottom: 10px;
  }

  .jumbotron .button {
    margin-top: 30px;
    max-width: 320px;
  }

</style>
