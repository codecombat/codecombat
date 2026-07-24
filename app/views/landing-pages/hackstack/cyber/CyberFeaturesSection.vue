<template>
  <PageSection class="section">
    <template #heading>
      {{ $t('hackstack_cyber_page.features_title') }}
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
            :alt="$t(`hackstack_cyber_page.${feature.key}_title`)"
          >
          <p class="feature__title">
            {{ $t(`hackstack_cyber_page.${feature.key}_title`) }}
          </p>
          <p class="feature__desc">
            {{ $t(`hackstack_cyber_page.${feature.key}_desc`) }}
          </p>
        </div>
      </div>
    </template>
  </PageSection>
</template>

<script>
import PageSection from 'app/components/common/elements/PageSection.vue'

export default {
  name: 'CyberFeaturesSection',
  components: {
    PageSection,
  },
  data () {
    return {
      features: [
        { key: 'feature_1', image: '/images/pages/hackstack/cyber/pillar-certification.png' },
        { key: 'feature_2', image: '/images/pages/hackstack/cyber/pillar-writing.png' },
        { key: 'feature_3', image: '/images/pages/hackstack/cyber/pillar-delivery.png' },
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
  padding-top: 60px;

  ::v-deep .heading {
    color: white;
  }

  ::v-deep .frame > div:empty {
    display: none;
  }

  ::v-deep .body {
    display: flex;
    flex-direction: row;
  }
}

.features {
  display: flex;
  justify-content: space-evenly;
  flex-wrap: wrap;
  width: 100%;

  @media (max-width: $screen-sm-max) {
    row-gap: 40px;
  }
}

.feature {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  flex: 1;
  max-width: 420px;
  text-align: center;

  @media (max-width: $screen-sm-max) {
    flex-basis: 100%;
  }
}

.feature__icon {
  height: 100px;
  width: auto;
  object-fit: contain;
  flex-shrink: 0;
  margin-bottom: 12px;
}

.feature__title {
  @extend %font-24-30;
  color: white;
  margin: 0;
}

.feature__desc {
  @extend %font-18-24;
  color: #B4B4B4;
  margin: 0;
}
</style>
