<template>
  <page-section class="section">
    <template #body>
      <div>
        <image-and-text
          :title="$t('hackstack_page.learn_title')"
          :text="$t('hackstack_page.learn_description')"
          image="/images/pages/hackstack/hackstack-debrief.webp"
        />
        <image-and-text
          :title="$t('hackstack_page.create_title')"
          :text="$t('hackstack_page.create_description')"
          :reverse="true"
        >
          <template #image>
            <video-box
              video-id="274971c4154aa46305c65d739a7d4412"
            />
          </template>
        </image-and-text>
        <image-and-text
          :title="$t('hackstack_page.remix_title')"
          :text="$t('hackstack_page.remix_description')"
          image="/images/pages/hackstack/hackstack-remix.webp"
        />
      </div>
    </template>
    <template #tail>
      <div class="row">
        <div class="col-md-12">
          <CTAButton
            class="contact-us-quote"
            @clickedCTA="CTAClicked"
          >
            {{ $t('new_home.request_quote') }}
          </CTAButton>
        </div>
      </div>
    </template>
  </page-section>
</template>

<script>
import PageSection from 'app/components/common/elements/PageSection'
import ImageAndText from 'app/components/common/elements/ImageAndText.vue'
import VideoBox from 'app/components/common/image-containers/VideoBox.vue'
import CTAButton from 'app/components/common/buttons/CTAButton.vue'

export default {
  name: 'SafeAIUse',
  components: {
    PageSection,
    ImageAndText,
    VideoBox,
    CTAButton,
  },
  methods: {
    CTAClicked () {
      this.$emit('open-modal')
    },
  },
}
</script>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "app/styles/component_variables.scss";

$primary-color: #4DECF0;
$primary-background: #31636F;

.section {
  background: #021E27;
  ::v-deep .text-h3 {
    color: $primary-color !important;
  }
  ::v-deep .mixed-color-label__normal {
    color: white;
  }
  ::v-deep .mixed-color-label__highlight {
    color: $primary-color !important;
  }
}

</style>
