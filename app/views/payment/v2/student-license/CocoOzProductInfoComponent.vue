<template>
  <div class="coco-product-info__product">
    <div class="col-md-6">
      <img
        src="/images/pages/payment/lock-green.png"
        alt="Lock icon"
        class="coco-product-info__product-lock"
      >
      <div class="coco-product-info__product-full">
        {{ $t('payments.full_access_coco') }}:
      </div>
      <ul class="coco-product-info__product-list">
        <li class="license__coco-list-feature">
          {{ $t('payments.cs_info') }}
        </li>
        <li class="license__coco-list-feature">
          {{ $t('payments.wd_info') }}
        </li>
        <li class="license__coco-list-feature">
          {{ $t('payments.gd_info') }}
        </li>
      </ul>
    </div>
    <div class="col-md-6 coco-product-info__product-oz">
      <div class="coco-product-info__product-full">
        {{ $t('payments.and_oz') }}:
      </div>
      <ul class="coco-product-info__product-list">
        <li class="coco-product-info__oz-list-feature">
          {{ $t('payments.chap1_info') }}
        </li>
        <li class="coco-product-info__oz-list-feature">
          {{ $t('payments.chap2_info') }}
        </li>
        <li class="coco-product-info__oz-list-feature">
          {{ $t('payments.chap3_info') }}
        </li>
        <li class="coco-product-info__oz-list-feature">
          {{ $t('payments.chap4_info') }}
        </li>
      </ul>
    </div>
  </div>
</template>

<script>
export default {
  name: 'CocoOzProductInfoComponent'
}
</script>

<style scoped lang="scss">
.coco-product-info {
  &__product {
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
}
</style>
