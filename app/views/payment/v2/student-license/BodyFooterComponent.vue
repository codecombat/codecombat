<template>
  <div
    class="license__footer"
    v-if="classType === 'small-class'"
  >
    <div class="license__buy row">
      <div class="license__buy-once col-md-6">
        Available for purchase one time annually.
      </div>
      <div class="col-md-1">&nbsp;</div>
      <div class="license__buy-btn clearfix col-md-5">Buy Now</div>
    </div>
  </div>
  <div
    class="license__footer"
    v-else
  >
    <div class="license__buy license__request row" v-if="numStudents === '<=10'">
      <div class="license__buy-once col-md-6">
        We'll help you build a solution that meets the needs of your class, school or district.
      </div>
      <div class="col-md-1">&nbsp;</div>
      <div class="license__buy-btn clearfix col-md-5">Request a Quote</div>
    </div>
    <div class="license__buy license__request license__bulk-only" v-else>
      <div class="license__buy-once">
        We'll help you build a solution that meets the needs of your class, school or district.
      </div>
      <div class="license__bulk-discount">
        <div class="license__bulk-discount-body">
            <div class="license__price">
              Bulk
            </div>
            <div class="license__per">
              <span class="license__per-student">discounts</span>
              <span class="license__per-year">available</span>
            </div>
        </div>
        <div class="license__buy-btn license__bulk-only-request-quote cls2">Request a Quote</div>
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
        return [ 'small-class', 'school-district' ].includes(v)
      }
    },
    numStudents: {
      type: String,
      validator: (v) => {
        return [ '<=10', '10+' ].includes(v)
      }
    }
  }
}
</script>

<style scoped lang="scss">
.license {
  &__buy {
    background: #1FBAB4;
    padding: 5rem;

    &-once {
      display: inline-block;

      font-style: italic;
      font-weight: 500;
      font-size: 16px;
      line-height: 21px;
      /* identical to box height, or 131% */

      align-items: center;

      /* White */

      color: #FFFFFF;

      padding-top: 1rem;
    }

    &-btn {
      float: right;

      background: #FCBB00;
      padding: 1rem 3.5rem;

      font-style: normal;
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
  }

  &__price {
    font-style: normal;
    font-weight: 700;
    font-size: 5rem;
    line-height: 3.2rem;
    /* identical to box height, or 53% */

    letter-spacing: 0.56px;

    /* Teal Dark */

    color: #0E4C60;

    display: inline-block;
  }

  &__per {
    display: inline-block;

    text-transform: uppercase;

    font-style: normal;
    font-weight: 600;
    font-size: 1.6rem;
    line-height: 2.1rem;
    /* or 122% */

    letter-spacing: 0.56px;
    color: #0E4C60;

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
