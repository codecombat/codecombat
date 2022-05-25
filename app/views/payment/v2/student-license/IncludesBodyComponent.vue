<template>
  <div class="includes-body">
    <div
      v-if="classType === 'small-class'"
      class="license__body-2 small-class__body-2"
    >
      <div class="license__includes">
        {{ $t('payments.includes') }}:
      </div>
      <div class="license__product row">
        <coco-oz-product-info-component />
      </div>

      <div class="license__info">
        <img src="/images/pages/payment/message-green.png" class="license__info-logo" alt="Message logo">
        <span class="license__info-text">{{ $t('payments.customer_support_info_1') }}</span>
      </div>
      <div class="license__info">
        <img src="/images/pages/payment/dollar-green.png" class="license__info-logo" alt="Dollar logo">
        <span class="license__info-text">{{ $t('payments.self_serve_credit') }}</span>
      </div>

    </div>
    <div
      v-else
      class="school-district__body-2"
    >
      <div class="license__includes">
        {{ $t('payments.includes') }}:
      </div>
      <div class="license__product row">
        <coco-oz-product-info-component />
      </div>

      <div class="license__info">
        <img src="/images/pages/payment/message-green.png" class="license__info-logo" alt="Message logo">
        <span class="license__info-text">{{ $t('payments.customer_support_info_2') }}</span>
      </div>
      <div class="license__info">
        <img src="/images/pages/payment/dollar-green.png" class="license__info-logo" alt="Dollar logo">
        <span class="license__info-text">{{ $t('payments.multiple_payment_options') }}</span>
      </div>
      <div class="license__info">
        <img src="/images/pages/payment/insights-green.png" class="license__info-logo" alt="Insights logo">
        <span class="license__info-text">{{ $t('payments.admin_dashboard') }}</span>
      </div>

    </div>
  </div>

</template>

<script>
import CocoOzProductInfoComponent from './CocoOzProductInfoComponent'
export default {
  name: 'IncludesBodyComponent',
  components: {
    CocoOzProductInfoComponent
  },
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
@import "app/styles/payment/variables";

.license {
  font-style: normal;

  &__includes {
    font-weight: 600;
    font-size: 2.4rem;
    line-height: 3.2rem;
    /* or 133% */

    letter-spacing: 0.56px;

    color: $teal-dark;

    padding-bottom: .5rem;
    border-bottom: .5rem solid #1fbab4;
  }

  &__info {
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
