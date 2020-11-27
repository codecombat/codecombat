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
    <img class="animated-griffin"
         src="/images/pages/parents/Griffin_and_Alejandro1.svg"
         alt="flying griffin"/>
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
  /* This makes lores12ot-bold and lores12ot-boldaltoakland available from the codecombat-css s3 bucket */
  @import 'https://dbbpm1bnahe9k.cloudfront.net/webfont.css';

  .top-jumbotron {
    font-family: "lores12ot-bold"; /* We can add fallbacks here in the future */
    font-style: normal;

    margin-bottom: 0;
    min-height: 580px;

    padding-top: 155px;

    background-color: unset;

    position: relative;
    z-index: 2;

    text-align: center;
    min-height: 628px;

    background-image: url(/images/pages/parents/parent_hero_image.png),
      url(/images/pages/parents/image_cloud_3.svg),
      url(/images/pages/parents/image_cloud_4.svg),
      url(/images/pages/parents/image_cloud_3.svg),
      url(/images/pages/parents/image_cloud_1.svg);

    background-repeat: no-repeat,
      no-repeat,
      no-repeat,
      no-repeat,
      no-repeat;

    background-position: bottom left 5%,
      top 50px left 30px,
      top 35px right 280px,
      top 360px right 300px,
      bottom 52px right 475px;

    background-size: 500px,
      260px,
      90px,
      260px,
      250px;
  }

  @media (max-width: 1000px) {
    .top-jumbotron {
      /* Moves images out of the way of the heading to keep it legible */
      background-position: bottom -74% left -5%,
        top 50px left 30px,
        top 35px right 280px,
        top 360px right 300px,
        bottom 52px right 475px;
    }
  }

  .top-jumbotron h1 + h1 {
    margin-bottom: 58px;
  }

  .top-jumbotron .button {
    margin-top: 30px;
    max-width: 320px;
  }

  .animated-griffin {
    position: absolute;
    top: 30%;
    right: 6%;
  }

</style>
