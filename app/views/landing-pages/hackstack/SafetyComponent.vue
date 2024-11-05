<template>
  <background-container
    type="default"
    class="dark-theme"
  >
    <div class="container">
      <content-box>
        <template #text>
          <div class="content">
            <div>
              <p class="title">
                {{ $t('hackstack_page.privacy_title') }}
              </p>
              <p class="subtitle">
                {{ $t('hackstack_page.privacy_subtitle') }}
              </p>
            </div>
            <div class="data-text">
              <div class="data">
                <img
                  class="vector"
                  alt="Vector"
                  src="/images/pages/hackstack/safety-icon.webp"
                  loading="lazy"
                >
                <div class="div">
                  <p class="header">
                    {{ $t('hackstack_page.data_title') }}
                  </p>
                  <p class="text">
                    {{ $t('hackstack_page.data_description') }}
                  </p>
                  <learn-more-button
                    link="https://docs.google.com/document/d/1OfQw0B841BUu7iABRlS-UXMbHDb9npYLvOPgcsdIiH0"
                    target="_blank"
                    class="learn-more"
                  >
                    {{ $t('hackstack_page.learn_more') }}
                  </learn-more-button>
                </div>
              </div>
              <div class="data">
                <img
                  class="vector"
                  alt="Vector"
                  src="/images/pages/hackstack/magnifying-glass.webp"
                  loading="lazy"
                >
                <div class="div">
                  <p class="header">
                    {{ $t('hackstack_page.moderation_title') }}
                  </p>
                  <p class="text">
                    {{ $t('hackstack_page.moderation_description') }}
                  </p>
                  <learn-more-button
                    link="https://docs.google.com/document/d/1OfQw0B841BUu7iABRlS-UXMbHDb9npYLvOPgcsdIiH0/edit?tab=t.0#bookmark=id.calwdm8t21hq"
                    target="_blank"
                    class="learn-more"
                  >
                    {{ $t('hackstack_page.learn_more') }}
                  </learn-more-button>
                </div>
              </div>
            </div>
          </div>
        </template>
      </content-box>
    </div>
  </background-container>
</template>

<script>
import BackgroundContainer from 'app/components/common/backgrounds/BackgroundContainer.vue'
import ContentBox from 'app/components/common/elements/ContentBox.vue'
import LearnMoreButton from 'app/components/common/buttons/LearnMoreButton.vue'
export default {
  name: 'SafetyComponent',
  components: {
    ContentBox,
    LearnMoreButton,
    BackgroundContainer,
  },
}
</script>

<style scoped lang="scss">
@import "app/styles/component_variables.scss";

.section {
  background: #021E27;
}

::v-deep.box {
  background: linear-gradient(109.69deg, #FFFFFF 0%, #ECFFFF 100%);
}

.content {
  align-items: center;
  display: flex;
  flex-direction: column;
  gap: 40px;
  justify-content: center;
  position: relative;

  .title {
    @extend %font-36;
    color: #0F4C60;
    position: relative;
    text-align: center;
    font-weight: 500;
  }

  .subtitle {
    @extend %font-18-24;
    font-weight: 500;
    align-self: stretch;
    color: #0A2239;
  }

  .learn-more {
    font-weight: 500;
  }

  .data-text {
    align-items: center;
    align-self: stretch;
    display: flex;
    flex: 0 0 auto;
    flex-direction: column;
    gap: 40px;
    justify-content: center;
    position: relative;
    width: 100%;
  }

  .data {
    align-items: center;
    align-self: stretch;
    display: flex;
    flex: 0 0 auto;
    gap: 30px;
    position: relative;
    width: 100%;
    @media (max-width: $screen-sm-max) {
      flex-direction: column;
      gap: 20px;
    }
  }

  .vector {
    position: relative;
    width: 170px;
  }

  .div {
    align-items: flex-start;
    display: flex;
    flex: 1;
    flex-direction: column;
    flex-grow: 1;
    gap: 12px;
    position: relative;
  }

  .text {
    @extend %font-18-24;
    font-weight: 400;
    align-self: stretch;
    color: #0A2239;
    font-style: normal;
  }

  .header {
    @extend %font-24-30;
    font-weight: 500;
    align-self: stretch;
    color: #0F4C60;
    font-style: italic;
  }
}
</style>
