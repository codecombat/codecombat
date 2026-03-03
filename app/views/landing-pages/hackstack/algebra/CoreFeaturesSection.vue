<template>
  <PageSection class="section">
    <template #heading>
      {{ $t('hackstack_algebra_page.features_title') }}
    </template>
    <template #body>
      <div class="features">
        <div
          v-for="feature in features"
          :key="feature.key"
          class="feature"
        >
          <img
            class="feature__icon"
            :src="feature.image"
            :alt="$t(`hackstack_algebra_page.${feature.key}`)"
          >
          <p class="feature__title">
            {{ $t(`hackstack_algebra_page.${feature.key}`) }}
          </p>
        </div>
      </div>
    </template>
  </PageSection>
</template>

<script>
import PageSection from 'app/components/common/elements/PageSection.vue'

export default {
  name: 'CoreFeaturesSection',
  components: {
    PageSection,
  },
  data () {
    return {
      features: [
        { key: 'feature_1_title', image: '/images/pages/hackstack/ai-foundations.png' },
        { key: 'feature_2_title', image: '/images/pages/hackstack/ai-evaluate.png' },
        { key: 'feature_3_title', image: '/images/pages/hackstack/ai-modelling.png' },
      ],
    }
  },
}
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";
@import "app/styles/component_variables.scss";

.section {
  background: #193640;

  ::v-deep .heading {
    color: white;
  }
}

.features {
  display: flex;
  justify-content: center;
  gap: 80px;
  flex-wrap: wrap;
}

.feature {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 24px;
  max-width: 200px;
  text-align: center;
}

.feature__icon {
  width: 100px;
  height: 100px;
  object-fit: contain;
  flex-shrink: 0;
}

.feature__title {
  @extend %font-16;
  color: white;
  white-space: pre-line;
  margin: 0;
}
</style>
