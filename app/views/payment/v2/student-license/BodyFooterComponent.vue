<template>
  <div
    v-if="classType === 'small-class'"
    class="license__footer"
  >
    <div class="license__buy row">
      <div class="license__buy-once col-md-6">
        {{ $t('payments.purchase_annually') }}
      </div>
      <div class="col-md-offset-1 col-md-5">
        <div class="license__buy-btn">
          {{ $t('subscribe.buy_now') }}
        </div>
      </div>
    </div>
  </div>
  <div
    v-else
    class="license__footer"
  >
    <div
      v-if="numStudents === '<=10'"
      class="license__buy license__request row"
    >
      <div class="license__buy-once col-md-6">
        {{ $t('payments.class_school_solution') }}
      </div>
      <div class="col-md-offset-1 col-md-5">
        <div class="license__buy-btn">
          {{ $t('payments.request_quote') }}
        </div>
      </div>
    </div>
    <div
      v-else
      class="license__buy license__request license__bulk-only"
    >
      <div class="license__buy-once">
        {{ $t('payments.class_school_solution') }}
      </div>
      <div class="license__bulk-discount">
        <div class="license__bulk-discount-body">
          <div class="license__price">
            {{ $t('payments.bulk') }}
          </div>
          <div class="license__per">
            <span class="license__per-student">{{ $t('payments.discounts') }}</span>
            <span class="license__per-year">{{ $t('payments.available') }}</span>
          </div>
        </div>
        <div class="license__buy-btn license__bulk-only-request-quote cls2">
          {{ $t('payments.request_quote') }}
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'BodyFooterComponent',
  props: {
    classType: {
      type: String,
      validator: (v) => {
        return ['small-class', 'school-district'].includes(v)
      }
    },
    numStudents: {
      type: String,
      validator: (v) => {
        return ['<=10', '10+'].includes(v)
      }
    }
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/payment/variables";
@import "app/styles/bootstrap/variables";

.license {
  &__buy {
    background: $blue-dark-1;
    padding: 5rem;

    @media (max-width: $screen-md-min) {
      padding: 2rem;
    }

    &-once {
      font-style: italic;
      font-weight: 500;
      font-size: 16px;
      line-height: 21px;
      /* identical to box height, or 131% */

      align-items: center;

      /* White */

      color: #FFFFFF;

      padding-top: 1rem;

      @media (max-width: $screen-md-min) {
        padding-bottom: 1rem;
        text-align: center;
      }
    }

    &-btn {
      background: #FCBB00;
      padding: 1rem 3.5rem;

      font-weight: 600;
      font-size: 1.8rem;
      line-height: 2.8rem;
      /* identical to box height, or 150% */

      align-items: center;
      text-align: center;
      letter-spacing: 0.444444px;
    }
  }

  &__request {
    padding: 4rem;

    @media (max-width: $screen-md-min) {
      padding: 2rem;
    }
  }

  &__price {
    font-weight: 700;
    font-size: 5rem;
    line-height: 3.2rem;
    /* identical to box height, or 53% */

    letter-spacing: 0.56px;

    color: $teal-dark;

    display: inline-block;
  }

  &__per {
    display: inline-block;

    text-transform: uppercase;

    font-weight: 600;
    font-size: 1.6rem;
    line-height: 2.1rem;
    /* or 122% */

    letter-spacing: 0.56px;
    color: $teal-dark;

    &-student {
      display: block;
    }

    &-year {
      display: block;
    }
  }

  &__bulk-only {
    text-align: center;

    &-request-quote {
      float: none;
      display: inline-block;
    }
  }

  &__bulk-discount {
    padding-top: 2rem;

    &-body {
      display: inline-block;
      padding-right: 5rem;

      position: relative;
      top: 1rem;
    }
  }

}
</style>
