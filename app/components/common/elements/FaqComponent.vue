<template>
  <div class="FA-qs">
    <div class="frame">
      <div class="heading">
        Frequently Asked Questions
      </div>
      <div
        id="accordion"
        class="faq-list"
      >
        <FaqItem
          v-for="(item, index) in faqItems"
          :id="'collapse' + (index + 1)"
          :key="index"
          :question="item.question"
          :is-open="openItemId === index"
          @toggle="openItemId = openItemId === index ? null : index"
        >
          {{ item.answer }}
        </FaqItem>
      </div>
      <p class="p">
        <span class="span">See more frequently asked questions in our </span>
        <a
          href="https://codecombat.zendesk.com/hc/en-us"
          rel="noopener noreferrer"
          target="_blank"
        >
          <span class="text-wrapper-2">help center</span><span class="span">.</span>
        </a>
      </p>
    </div>
  </div>
</template>

<script>
import FaqItem from './FaqItem.vue'

export default {
  name: 'FaQs',
  components: {
    FaqItem
  },
  props: {
    faqItems: {
      type: Array,
      required: true
    }
  },
  data () {
    return {
      openItemId: null
    }
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";

.FA-qs {
    align-items: center;
    display: flex;
    flex-direction: column;
    gap: 40px;
    justify-content: center;
    padding: 100px 135px;
    position: relative;

    @media (max-width: $screen-md-max) {
        padding: 100px 40px;
    }

    .frame {
        align-items: center;
        display: inline-flex;
        flex: 0 0 auto;
        flex-direction: column;
        gap: 80px;
        justify-content: center;
        position: relative;
        width: 100%;
    }

    .heading {
        font-family: "Plus Jakarta Sans-Medium", Helvetica;
        font-size: 36px;
        font-weight: 500;
        letter-spacing: 0;
        line-height: 45px;
        margin-top: -1px;
        position: relative;
        text-align: center;
    }

    .faq-list {
        align-items: flex-start;
        display: inline-flex;
        flex: 0 0 auto;
        flex-direction: column;
        gap: 0;
        position: relative;
        width: 100%;
    }

    .p {
        color: transparent;
        font-family: "Plus Jakarta Sans-Medium", Helvetica;
        font-size: 28px;
        font-weight: 500;
        letter-spacing: 0;
        line-height: 36px;
        position: relative;
        text-align: center;
    }

    .span {
        color: #111928;
    }

    .text-wrapper-2 {
        color: #4799A9;
    }
}
</style>
