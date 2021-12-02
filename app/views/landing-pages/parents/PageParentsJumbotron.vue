<script>
import ButtonMainCta from './ButtonMainCta'

export default {
  components: {
    ButtonMainCta
  },

  methods: {
    onCtaClick () {
      this.$emit('cta-clicked')
    }
  },

  props: {
    mainCtaButtonText: {
      type: String,
      default: 'Schedule a Free Class'
    },
    trialClassExperiment: {
      type: String,
      default: 'trial-class'
    }
  }
}

</script>

<template>
  <div class="top-jumbotron">
    <img class="animated-griffin"
         src="/images/pages/parents/Griffin_and_Alejandro1.svg"
         alt="flying griffin"
         v-if="trialClassExperiment == 'trial-class'" />
    <div v-else class="money-back-guarantee-section" >
      <img
        class="img-responsive money-back-guarantee"
        src="/images/pages/parents/money_back_guarantee.png"
        title="30-day money-back guarantee"
        alt='"30 Day Money back Guarantee Transparent" by transparentpng.com is licensed under CC BY 4.0 - source: https://www.transparentpng.com/details/30-day-money-back-guarantee-transparent_15977.html'
      />
      <div class="money-back-guarantee-text">
        Enroll with the confidence that you have 30 days to see if CodeCombat is right for you
      </div>
    </div>
    <div class="row">
      <div class="col-lg-12">
        <h1 class="pixelated parents-header-text">Live Online Coding Classes</h1>
        <!--<h1 class="pixelated parents-header-text">Your Child Will Love</h1>--><!-- Original; didn't convert as well -->
        <h1 class="pixelated parents-header-text">Powered by Play</h1>
      </div>
    </div>


    <div class="row">
      <div class="col-lg-12">
        <button-main-cta
          @click="onCtaClick"
          :buttonText="mainCtaButtonText"
        />
      </div>
    </div>
  </div>

</template>

<style scoped>
  .top-jumbotron {
    font-style: normal;

    margin-bottom: 0;

    padding-top: 155px;
    overflow-x: hidden;

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

  .pixelated {
    font-family: "lores12ot-bold", "VT323";
    color: #0E4C60;
  }

  .top-jumbotron h1 + h1 {
    margin-bottom: 58px;
  }

  .top-jumbotron .button {
    margin-top: 30px;
    max-width: 320px;
  }

  .animated-griffin, .money-back-guarantee-section {
    position: absolute;
    top: 30%;
    right: 6%;
  }

  .money-back-guarantee-section {
    width: 310px;
    right: calc(20% - 185px);
    font-family: 'Work Sans', sans-serif;
    color: #131B25;
    font-weight: 300;
    font-size: 22px;
  }

  img.money-back-guarantee {
    margin: 0px auto;
  }

  @media (max-width: 1000px) {
    .top-jumbotron h1 + h1 {
      margin-bottom: 38px;
    }
    .top-jumbotron {
      /* Moves images out of the way of the heading to keep it legible */
      background-size: 443px, 260px, 90px, 260px, 250px;
      background-position: bottom -65% left -5%,
        top 50px left 30px,
        top 35px right 280px,
        top 360px right 300px,
        bottom 52px right 475px;
    }

    .animated-griffin {
      position: absolute;
      top: -1%;
      right: -11%;
      overflow: hidden;
      max-width: 50%;
    }

    .money-back-guarantee-section {
      display: none;
    }
  }

  .top-jumbotron h1 {
    font-weight: 700;
  }
  
  @media (max-width: 767px) {
    .parents-header-text {
      font-size: 40px;
    }
  }

  @media (max-width: 320px) {
    .parents-header-text {
      font-size: 36px;
      line-height: 48px;
    }
    .top-jumbotron h1 + h1 {
      margin-bottom: 20px;
    }
    .top-jumbotron {
      /* Moves images out of the way of the heading to keep it legible */
      background-size: 443px, 260px, 90px, 260px, 250px;
      background-position: bottom -40% left -5%,
        top 50px left 30px,
        top 35px right 280px,
        top 360px right 300px,
        bottom 52px right 475px;
    }
  }

</style>
