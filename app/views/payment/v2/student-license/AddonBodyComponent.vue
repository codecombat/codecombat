<template>
  <div class="addon-body">
    <div
      class="license__body-3 small-class__body-3"
      v-if="classType === 'small-class'"
    >
      <div class="license__addon">
        <span class="license__addon-new">New!</span> <span class="license__addon-text">Paid Add-Ons:</span>
      </div>

      <div class="license__addon-info">
        <div class="license__addon-info-heading">
          <img src="/images/pages/payment/apple-green.png" alt="Apple logo" class="license__addon-info-apple">
          <span class="license__addon-info-heading-text">Professional Development</span>
        </div>
        <div class="license__addon-info-subheading">
          Comprehensive 40-hour online course that allows you to learn anytime, anywhere and at any pace. <a href="https://www.ozaria.com/professional-development" target="_blank">Learn More.</a>
        </div>
      </div>
    </div>
    <div
      class="school-district__body-3"
      v-else
    >
      <div class="license__addon">
        <span class="license__addon-new">New!</span> <span class="license__addon-text">Paid Add-Ons:</span>
      </div>

      <div class="license__addon-info">
        <div class="license__addon-info-heading">
          <img src="/images/pages/payment/apple-green.png" alt="Apple logo" class="license__addon-info-apple">
          <span class="license__addon-info-heading-text">Professional Development</span>
        </div>
        <div class="license__addon-info-subheading">
          Comprehensive 40-hour online course that allows you to learn anytime, anywhere and at any pace. <a href="https://www.ozaria.com/professional-development" target="_blank">Learn More.</a>
        </div>
      </div>

      <div class="license__addon-info">
        <div class="license__addon-info-heading">
          <img src="/images/pages/payment/desktop-green.png" alt="Training logo" class="license__addon-info-apple">
          <span class="license__addon-info-heading-text">Implementation Training</span>
        </div>
        <div class="license__addon-info-subheading">
          60 min Onboarding Training on how to use CodeCombat and Ozaria to support specific institutional and instructional goals.
        </div>
      </div>

      <div class="license__addon-info">
        <div class="license__addon-info-heading">
          <img src="/images/pages/payment/league-green.png" alt="AI league logo" class="license__addon-info-apple">
          <span class="license__addon-info-heading-text">AI League Custom Tournament</span>
        </div>
        <div class="license__addon-info-subheading">
          Engage students in an exciting esports competition that allows them to showcase their understanding of concepts in a new environment and practice creative problem-solving strategies! <a href="https://codecombat.com/league" target="_blank">Learn More.</a>
        </div>
      </div>

    </div>
  </div>
</template>

<script>
export default {
  name: 'AddonBodyComponent',
  props: {
    classType: {
      type: String,
      validator: (v) => {
        return [ 'small-class', 'school-district' ].includes(v)
      }
    }
  }
}
</script>

<style scoped lang="scss">
.license {
  &__addon {
    font-style: normal;
    font-weight: 700;
    font-size: 1.6rem;
    line-height: 3.2rem;
    /* identical to box height, or 167% */

    /* Teal Dark */

    color: #0E4C60;

    padding-bottom: 1rem;
    border-bottom: .5rem solid #1FBAB4;

    &-new {
      background: #FF82F2;
      border-radius: 14px;
      line-height: 3rem;

      padding: .7rem 1.5rem;
    }

    &-text {
      font-size: 2.3rem;
      font-weight: 600;

      letter-spacing: 0.56px;

      padding-left: .5rem;
    }
  }

  &__addon-info {
    font-style: normal;
    padding-top: 1.5rem;

    &-heading {
      font-weight: 700;
      font-size: 2rem;
      line-height: 2.6rem;
      /* or 130% */

      display: flex;
      align-items: center;

      /* Teal Dark */

      color: #0E4C60;

      text-transform: uppercase;

      padding-bottom: 1rem;

      &-text {
        padding-left: .5rem;
      }
    }

    &-subheading {
      font-weight: 400;
      font-size: 1.5rem;
      line-height: 2.2rem;
      /* or 138% */

      color: #000000;

      padding-left: 2.5rem;
    }

    &-apple {
      width: 2rem;
    }
  }
}
</style>
