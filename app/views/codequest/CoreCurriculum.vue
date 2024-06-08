<template>
  <div class="core-curriculum">
    <p class="heading">
      <span class="text-wrapper">{{ $t('codequest_page.core_curriculum_heading_1') }}</span>
      <span class="span">{{ $t('codequest_page.core_curriculum_heading_2') }}</span>
      <span class="text-wrapper">{{ $t('codequest_page.core_curriculum_heading_3') }}</span>
      <span class="span">{{ $t('codequest_page.core_curriculum_heading_4') }}</span>
      <span class="text-wrapper">{{ $t('codequest_page.core_curriculum_heading_5') }}</span>
      <span class="span">{{ $t('codequest_page.core_curriculum_heading_6') }}</span>.
    </p>
    <div class="content">
      <Box
        image="/images/pages/codequest/rectangle-233.webp"
        :title="$t('codequest_page.core_curriculum_title_1')"
        :text="$t('codequest_page.core_curriculum_text_1')"
      />
      <Box
        image="/images/pages/codequest/rectangle-233-2.webp"
        :title="$t('codequest_page.core_curriculum_title_2')"
        :text="$t('codequest_page.core_curriculum_text_2')"
      />
    </div>
    <p class="heading">
      <span class="text-wrapper">{{ $t('codequest_page.core_curriculum_heading_11') }}</span>
      <span class="span">{{ $t('codequest_page.core_curriculum_heading_12') }}</span>,
      <span class="text-wrapper">{{ $t('codequest_page.core_curriculum_heading_13') }}</span>
      <span class="span">{{ $t('codequest_page.core_curriculum_heading_14') }}</span>
      <span class="text-wrapper">{{ $t('codequest_page.core_curriculum_heading_15') }}</span>
      <span class="span">{{ $t('codequest_page.core_curriculum_heading_16') }}</span>.
    </p>
    <div class="content">
      <Box
        image="/images/pages/codequest/cc2-1.webp"
        symbol-image="/images/pages/codequest/cc2-b.webp"
        :text="$t('codequest_page.core_curriculum_text_11')"
      />

      <Box
        image="/images/pages/codequest/cc2-2.webp"
        symbol-image="/images/pages/codequest/cc2-s.webp"
        :text="$t('codequest_page.core_curriculum_text_12')"
      />
    </div>
    <p class="heading">
      <span class="text-wrapper"> {{ $t('codequest_page.core_curriculum_heading_21') }}</span>
      <span class="span"> {{ $t('codequest_page.core_curriculum_heading_22') }}</span>
      <span class="text-wrapper"> {{ $t('codequest_page.core_curriculum_heading_23') }}</span>
    </p>

    <div class="content horizontal">
      <Box
        image="/images/pages/codequest/cc3-uc-berkley.webp"
        :title="$t('codequest_page.core_curriculum_title_21')"
        :text="$t('codequest_page.core_curriculum_text_21')"
        arrangement="horizontal"
        :has-padding="true"
      />

      <Box
        image="/images/pages/codequest/cc3-x.webp"
        :title="$t('codequest_page.core_curriculum_title_22')"
        :text="$t('codequest_page.core_curriculum_text_22')"
        arrangement="horizontal"
        :has-padding="true"
      />

      <Box
        image="/images/pages/codequest/cc3-cc.webp"
        :title="$t('codequest_page.core_curriculum_title_23')"
        :text="$t('codequest_page.core_curriculum_text_23')"
        arrangement="horizontal"
        :has-padding="true"
      />

      <Box
        image="/images/pages/codequest/cc3-apple.webp"
        :title="$t('codequest_page.core_curriculum_title_24')"
        :text="$t('codequest_page.core_curriculum_text_24')"
        arrangement="horizontal"
        :has-padding="true"
      />
    </div>
    <p class="heading">
      <span class="text-wrapper"> {{ $t('codequest_page.core_curriculum_heading_31') }}</span>
      <span class="span"> {{ $t('codequest_page.core_curriculum_heading_32') }}</span>
      <span class="text-wrapper"> {{ $t('codequest_page.core_curriculum_heading_33') }}</span>
      <span class="span"> {{ $t('codequest_page.core_curriculum_heading_34') }}</span>.
    </p>
    <div class="content">
      <Box
        image="/images/pages/codequest/cc4-1.webp"
        :title="$t('codequest_page.core_curriculum_title_31')"
        :text="$t('codequest_page.core_curriculum_text_31')"
        frame-image="/images/pages/codequest/cc4-google.webp"
      />
      <Box
        image="/images/pages/codequest/cc4-2.webp"
        :title="$t('codequest_page.core_curriculum_title_32')"
        :text="$t('codequest_page.core_curriculum_text_32')"
        frame-image="/images/pages/codequest/cc4-apple.webp"
      />
    </div>
    <div class="content horizontal">
      <Box
        image="/images/pages/codequest/cc4-3.jpeg"
        :title="$t('codequest_page.core_curriculum_title_33')"
        :text="$t('codequest_page.core_curriculum_text_33')"
        :main-image-bg="true"
      />
    </div>
  </div>
</template>

<script>
import Box from './components/Box.vue'
export default {
  name: 'CoreCurriculum',
  components: {
    Box
  }
}
</script>

<style scoped lang="scss">
@import 'app/styles/bootstrap/variables';
.core-curriculum {
    align-items: stretch;
    display: inline-flex;
    flex-direction: column;
    gap: 40px;
    padding: 0px 0px 80px;
    position: relative;
}

.core-curriculum .heading {
    color: transparent;
    font-family: "Plus Jakarta Sans-Medium", Helvetica;
    font-size: 28px;
    font-weight: 500;
    letter-spacing: 0;
    line-height: 36px;
    margin-top: -1px;
    position: relative;
    text-align: center;
    width: 100%;
    color: #000000;
}

.core-curriculum .span {
    color: #4799A9;
}

.core-curriculum .content {
    align-items: stretch;
    display: flex;
    // flex: 0 0 auto;
    gap: 30px;
    position: relative;
    width: 100%;

    > div {
        flex: 1;
    }

    &.horizontal {
        flex-direction: column;
    }

    @media (max-width: $screen-sm) {
        flex-direction: column;
    }
}

.core-curriculum .a-ozaria {
    align-items: flex-start;
    box-shadow: 0px 0px 22px #00000026;
    display: flex;
    flex-direction: column;
    position: relative;
    border-radius: 24px;
    width: 100%;
}

.core-curriculum .rectangle {
    object-fit: cover;
    position: relative;
    width: 100%;
}

.core-curriculum .div {
    align-items: center;
    background: linear-gradient(180deg, rgb(245, 255, 255) 0%, rgb(255, 255, 255) 100%);
    border-radius: 0px 0px 24px 24px;
    display: inline-flex;
    flex: 0 0 auto;
    flex-direction: column;
    gap: 20px;
    padding: 40px 50px;
    position: relative;
}

.core-curriculum .info {
    align-items: flex-start;
    align-self: stretch;
    display: flex;
    flex: 0 0 auto;
    flex-direction: column;
    gap: 12px;
    padding: 4px 0px 0px;
    position: relative;
    width: 100%;
}

.core-curriculum .title {
    color: #0a2239;
    font-family: "Plus Jakarta Sans-Bold", Helvetica;
    font-size: 20px;
    font-weight: 700;
    letter-spacing: 0;
    line-height: 20px;
}

.core-curriculum .text {
    color: #0a2239;
    font-family: "Plus Jakarta Sans-Regular", Helvetica;
    font-size: 18px;
    font-weight: 400;
    letter-spacing: 0;
    line-height: 24px;
    position: relative;
}
</style>
