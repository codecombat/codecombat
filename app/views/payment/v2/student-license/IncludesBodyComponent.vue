<template>
  <div class="includes-body">
    <div
      v-if="classType === 'small-class'"
      class="license__body-2 small-class__body-2"
    >
      <div class="license__includes">
        Includes:
      </div>
      <div class="license__product row">
        <div class="col-md-6">
          <img src="/images/pages/payment/lock-green.png" alt="Lock icon" class="license__product-lock">
          <div class="license__product-full">
            Full Access to both CodeCombat:
          </div>
          <ul class="license__product-list">
            <li class="license__coco-list-feature">Computer Science 1-6</li>
            <li class="license__coco-list-feature">Web Development 1-2</li>
            <li class="license__coco-list-feature">Game Development 1-3</li>
          </ul>
        </div>
        <div class="col-md-6 license__product-oz">
          <div class="license__product-full">
            And Ozaria:
          </div>
          <ul class="license__product-list">
            <li class="license__oz-list-feature">Chapter 1: 10 class sessions</li>
            <li class="license__oz-list-feature">Chapter 2: 30 class sessions</li>
            <li class="license__oz-list-feature">Chapter 3: 25 class sessions</li>
            <li class="license__oz-list-feature">Chapter 4: 20 class sessions</li>
          </ul>
        </div>
      </div>

      <div class="license__info">
        <img src="/images/pages/payment/message-green.png" class="license__info-logo" alt="Message logo">
        <span class="license__info-text">Customer support via email or chat</span>
      </div>
      <div class="license__info">
        <img src="/images/pages/payment/dollar-green.png" class="license__info-logo" alt="Dollar logo">
        <span class="license__info-text">Self-serve credit card purchase</span>
      </div>

    </div>
    <div
      v-else
      class="school-district__body-2"
    >
      <div class="license__includes">
        Includes:
      </div>
      <div class="license__product row">
        <div class="col-md-6">
          <img src="/images/pages/payment/lock-green.png" alt="Lock icon" class="license__product-lock">
          <div class="license__product-full">
            Full Access to both CodeCombat:
          </div>
          <ul class="license__product-list">
            <li class="license__coco-list-feature">Computer Science 1-6</li>
            <li class="license__coco-list-feature">Web Development 1-2</li>
            <li class="license__coco-list-feature">Game Development 1-3</li>
          </ul>
        </div>
        <div class="col-md-6 license__product-oz">
          <div class="license__product-full">
            And Ozaria:
          </div>
          <ul class="license__product-list">
            <li class="license__oz-list-feature">Chapter 1: 10 class sessions</li>
            <li class="license__oz-list-feature">Chapter 2: 30 class sessions</li>
            <li class="license__oz-list-feature">Chapter 3: 25 class sessions</li>
            <li class="license__oz-list-feature">Chapter 4: 20 class sessions</li>
          </ul>
        </div>
      </div>

      <div class="license__info">
        <img src="/images/pages/payment/message-green.png" class="license__info-logo" alt="Message logo">
        <span class="license__info-text">Customer support via email or chat, plus a dedicated school success manager available via phone or email for implementation support</span>
      </div>
      <div class="license__info">
        <img src="/images/pages/payment/dollar-green.png" class="license__info-logo" alt="Dollar logo">
        <span class="license__info-text">Variety of payment options available, including: purchase order, site licenses, & multi-year discounts.</span>
      </div>
      <div class="license__info">
        <img src="/images/pages/payment/insights-green.png" class="license__info-logo" alt="Dollar logo">
        <span class="license__info-text">Administrator dashboard with actionable data and insights</span>
      </div>

    </div>
  </div>

</template>

<script>
export default {
  name: 'IncludesBodyComponent',
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
  &__includes {
    font-style: normal;
    font-weight: 600;
    font-size: 2.4rem;
    line-height: 3.2rem;
    /* or 133% */

    letter-spacing: 0.56px;

    /* Teal Dark */

    color: #0E4C60;

    padding-bottom: .5rem;
    border-bottom: .5rem solid #1FBAB4;
  }

  &__product {
    font-style: normal;
    font-weight: 400;
    font-size: 1.6rem;
    line-height: 2.2rem;
    /* or 138% */

    display: flex;
    align-items: center;

    color: #000000;

    &-oz {
      padding-top: 2rem;
    }

    &-lock {
      width: 1.5rem;
    }

    &-full {
      display: inline-block;
      padding-bottom: .5rem;
    }

    &-list {
      font-size: 1.4rem;
    }
  }

  &__info {
    font-style: normal;
    font-weight: 400;
    font-size: 1.6rem;
    line-height: 2.2rem;
    /* or 138% */

    display: flex;
    align-items: center;

    color: #000000;

    padding-top: 1rem;

    &-logo {
      width: 1.5rem;
    }

    &-text {
      padding-left: 1rem;
    }
  }

}

.school-district__body-only .license__includes {
  padding-bottom: 1.2rem;
}
</style>
