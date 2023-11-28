<template>
  <div class="footer">
    <div class="footer__heading">
      Policies
    </div>
    <div class="footer__policies">
      <div class="footer__policy">
        <div class="footer__policy__heading">
          Class reschedule & cancellation policy
        </div>
        <div class="footer__policy__subheading">
          Please note that once you have booked a weekly class with us, we reserve that time in our schedule exclusively for you. We require 48 hours advance notice for class cancellations and/or rescheduling. Unfortunately, classes missed or canceled with less than 48 hours notice will not be rescheduled or refunded.
        </div>
      </div>
      <div class="footer__policy">
        <div class="footer__policy__heading">
          30 day money back guarantee
        </div>
        <div class="footer__policy__subheading">
          All subscriptions are billed on a monthly basis and may be paused, canceled, or resumed with no fees. Your subscription purchase is 100% risk-free within the first 30 days. If for any reason you decide not to continue, simply contact us within 30 days of purchase and we will promptly refund 100% of your payment, no questions asked. All plans are automatically renewed at the same level and billing cycle unless otherwise changed or canceled.
        </div>
      </div>
      <div class="footer__policy">
        <div class="footer__policy__heading">
          CodeCombat Holiday Details
        </div>
        <div class="footer__policy__subheading">
          In observance of major US holidays, the instructor may reach out to you if there is interference with your student’s class. There’s nothing you need to do on your end. If you have any questions, please reach out to <a href="mailto:classes@codecombat.com">classes@codecombat.com</a>.
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'FooterComponent'
}
</script>

<style scoped lang="scss">
@import "../css-mixins/variables";

.footer {
  padding: 4rem;

  &__heading {
    color: $color-yellow-3;
    font-size: 1.8rem;
    font-style: normal;
    font-weight: 600;
    line-height: 3rem;
    letter-spacing: 0.444px;
    text-transform: uppercase;

    &::after {
      content: "";
      height: 2px;
      width: 100%;
      display: block;
      background-color: $color-yellow-3;
    }
  }

  &__policies {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    grid-column-gap: 2rem;

    margin-top: 1rem;
  }

  &__policy {
    font-family: Work Sans, sans-serif;
    font-style: normal;
    margin-top: 2rem;

    &__heading {
      font-size: 1.6rem;
      font-weight: 600;
      line-height: 1.7rem;
      letter-spacing: 0.333px;

      margin-bottom: 1rem;
    }

    &__subheading {
      font-size: 1.4rem;
      font-weight: 400;
      line-height: 1.8rem;
      letter-spacing: 0.267px;
      color: $color-grey-4;
    }
  }
}
</style>
