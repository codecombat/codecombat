<template>
  <page-section class="section">
    <template #body>
      <div>
        <image-and-text
          :title="$t('hackstack_page.professional_development')"
          :text="$t('hackstack_page.professional_development_text')"
          :reverse="true"
          image="/images/pages/hackstack/workshop.webp"
        >
          <div class="contact-us">
            <CTAButton
              class="contact-us-quote"
              @clickedCTA="CTAClicked"
            >
              {{ $t('hackstack_page.ask_pd') }}
            </CTAButton>
          </div>
        </image-and-text>
      </div>
    </template>
  </page-section>
</template>

<script>
import PageSection from 'app/components/common/elements/PageSection'
import ImageAndText from 'app/components/common/elements/ImageAndText.vue'
import CTAButton from 'app/components/common/buttons/CTAButton.vue'

export default {
  name: 'PDComponent',
  components: {
    PageSection,
    ImageAndText,
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

  .contact-us {
    display: flex;
    align-items: flex-start;
    margin-top: 40px;
  }

  ::v-deep .box {
    background: none;
  }
}

</style>
