<template>
  <div class="FA-qs">
    <div class="frame">
      <div class="heading">
        {{ $t('codequest_page.faq') }}
      </div>
      <div
        id="accordion"
        class="faq-list"
      >
        <FaqItem
          id="collapseOne"
          :question="$t('codequest_page.faq_q_1')"
          href="#collapseOne"
        >
          {{ $t('codequest_page.faq_a_1') }}
        </FaqItem>
        <FaqItem
          id="collapseTwo"
          :question="$t('codequest_page.faq_q_2')"
          href="#collapseTwo"
        >
          {{ $t('codequest_page.faq_a_2') }}
        </FaqItem>
        <FaqItem
          id="collapseThree"
          :question="$t('codequest_page.faq_q_3')"
          href="#collapseThree"
        >
          {{ $t('codequest_page.faq_a_3') }}
        </FaqItem>
        <FaqItem
          id="collapseFour"
          :question="$t('codequest_page.faq_q_4')"
          href="#collapseFour"
        >
          {{ $t('codequest_page.faq_a_4') }}
        </FaqItem>
        <FaqItem
          id="collapseFive"
          :question="$t('codequest_page.faq_q_5')"
          href="#collapseFive"
        >
          {{ $t('codequest_page.faq_a_5_1') }}
          <br>
          {{ $t('codequest_page.faq_a_5_2') }}
        </FaqItem>
        <FaqItem
          id="collapseSix"
          :question="$t('codequest_page.faq_q_6')"
          href="#collapseSix"
        >
          {{ $t('codequest_page.faq_a_6') }}
        </FaqItem>
        <FaqItem
          id="collapseSeven"
          :question="$t('codequest_page.faq_q_7')"
          href="#collapseSeven"
        >
          {{ $t('codequest_page.faq_a_7') }}
        </FaqItem>
        <FaqItem
          id="collapseEight"
          :question="$t('codequest_page.faq_q_8')"
          href="#collapseEight"
        >
          {{ $t('codequest_page.faq_a_8_1') }}
          <br><br>
          {{ $t('codequest_page.faq_a_8_2') }}
        </FaqItem>
        <FaqItem
          id="collapseNine"
          :question="$t('codequest_page.faq_q_9')"
          href="#collapseNine"
        >
          {{ $t('codequest_page.faq_a_9') }}
        </FaqItem>
        <FaqItem
          id="collapseTen"
          :question="$t('codequest_page.faq_q_10')"
          href="#collapseTen"
        >
          {{ $t('codequest_page.faq_a_10') }}
        </FaqItem>
      </div>
      <p class="p">
        <span class="span">{{ $t('codequest_page.more_faq') }}</span>
        <a
          href="https://codecombat.zendesk.com/hc/en-us"
          rel="noopener noreferrer"
          target="_blank"
        >
          <span class="text-wrapper-2">{{ $t('codequest_page.help_center') }}</span><span class="span">.</span>
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
