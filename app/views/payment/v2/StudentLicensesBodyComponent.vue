<template>
  <div class="student-licenses-body">
    <div class="row">
      <div class="col-md-6">
        <div class="small-class">
          <div class="small-class__header">
            <div class="small-class__header-heading">
              Small Classroom
            </div>
            <div class="small-class__header-subheading">
              For clubs, after-school programs and small classrooms with 5-9 students.
            </div>
          </div>

          <div class="small-class__body">
            <div class="small-class__body-1">
              <div class="small-class__price">
                $50
              </div>
              <div class="small-class__per">
                <span class="small-class__per-student">per student</span>
                <span class="small-class__per-year">per year</span>
              </div>
              <div class="small-class__licenses clearfix">
                <span class="small-class__licenses-num">5-9</span>
                <span class="small-class__licenses-lic">licenses</span>
              </div>
            </div>

            <div class="small-class__body-2">
              <div class="small-class__includes">
                Includes:
              </div>
              <div class="small-class__product row">
                <div class="col-md-6">
                  <img src="/images/pages/payment/lock-green.png" alt="Lock icon" class="small-class__product-lock">
                  <div class="small-class__product-full">
                    Full Access to both CodeCombat:
                  </div>
                  <ul class="small-class__product-list">
                    <li class="small-class__coco-list-feature">Computer Science 1-6</li>
                    <li class="small-class__coco-list-feature">Web Development 1-2</li>
                    <li class="small-class__coco-list-feature">Game Development 1-3</li>
                  </ul>
                </div>
                <div class="col-md-6 small-class__product-oz">
                  <div class="small-class__product-full">
                    And Ozaria:
                  </div>
                  <ul class="small-class__product-list">
                    <li class="small-class__oz-list-feature">Chapter 1: 10 class sessions</li>
                    <li class="small-class__oz-list-feature">Chapter 2: 30 class sessions</li>
                    <li class="small-class__oz-list-feature">Chapter 3: 25 class sessions</li>
                    <li class="small-class__oz-list-feature">Chapter 4: 20 class sessions</li>
                  </ul>
                </div>
              </div>

              <div class="small-class__info">
                <img src="/images/pages/payment/message-green.png" class="small-class__info-logo" alt="Message logo">
                <span class="small-class__info-text">Customer support via email or chat</span>
              </div>
              <div class="small-class__info">
                <img src="/images/pages/payment/dollar-green.png" class="small-class__info-logo" alt="Dollar logo">
                <span class="small-class__info-text">Self-serve credit card purchase</span>
              </div>

            </div>

            <div class="small-class__body-3">
              <div class="small-class__addon">
                <span class="small-class__addon-new">New!</span> <span class="small-class__addon-text">Paid Add-Ons:</span>
              </div>

              <div class="small-class__pd">
                <div class="small-class__pd-heading">
                  <img src="/images/pages/payment/apple-green.png" alt="Apple logo" class="small-class__pd-apple">
                  <span class="small-class__pd-heading-text">Professional Development</span>
                </div>
                <div class="small-class__pd-subheading">
                  Comprehensive 40-hour online course that allows you to learn anytime, anywhere and at any pace. <a href="https://www.ozaria.com/professional-development" target="_blank">Learn More.</a>
                </div>
              </div>
            </div>
          </div>

          <div class="small-class__footer">
            <div class="small-class__buy">
              <div class="small-class__buy-once">
                Available for purchase one time annually.
              </div>
              <div class="small-class__buy-btn clearfix">Buy Now</div>
            </div>
          </div>
        </div>
      </div>
      <div class="col-md-6">
        <div class="school-district">

        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
name: "StudentLicensesBodyComponent"
}
</script>

<style scoped lang="scss">
.small-class {
  background: #FFFFFF;
  /* Gray 3 */

  border: 1px solid #D8D8D8;
  box-sizing: border-box;
  /* Drop Shadow (Box) */

  box-shadow: 3px 0 8px rgba(0, 0, 0, 0.15), -1px 0 1px rgba(0, 0, 0, 0.06);
  border-radius: 2.4rem;

  overflow: hidden;

  font-family: 'Work Sans', serif;

  &__header {
    background: #6AE8E3;
    /* Drop Shadow (Box) */

    box-shadow: 3px 0 8px rgba(0, 0, 0, 0.15), -1px 0 1px rgba(0, 0, 0, 0.06);
    text-align: center;

    padding: 2rem;

    &-heading {
      font-family: 'Work Sans',serif;
      font-style: normal;
      font-weight: 700;
      font-size: 3.6rem;
      line-height: 3.2rem;
      /* or 89% */

      letter-spacing: 0.56px;

      /* Teal Dark */

      color: #0E4C60;
    }

    &-subheading {
      font-family: 'Work Sans',serif;
      font-style: normal;
      font-weight: 400;
      font-size: 1.6rem;
      line-height: 2.6rem;
      /* or 162% */

      /* Teal Dark */

      color: #0E4C60;
    }
  }

  &__body {
    padding: 2rem;

    &-1 {
      padding-bottom: 2rem;
    }

    &-2 {
      padding-bottom: 4rem;
    }

    &-3 {
      padding-bottom: 8rem;
    }
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

  &__licenses {
    font-style: normal;
    font-weight: 600;
    font-size: 1.6rem;
    line-height: 2.1rem;
    /* or 122% */

    letter-spacing: 0.56px;
    text-transform: uppercase;

    /* Teal Dark */

    color: #0E4C60;

    display: inline-block;

    float: right;

    &-num {
      display: block;
    }

    &-lic {
      display: block;
    }
  }

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

  &__pd {
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
}
</style>
