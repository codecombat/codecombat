<template>
  <PageSection :class="['section', `section--${variant}`]">
    <template #heading>
      {{ title }}
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
            :alt="feature.alt || feature.title"
          >
          <p class="feature__title">
            {{ feature.title }}
          </p>
          <p
            v-if="feature.description"
            class="feature__desc"
          >
            {{ feature.description }}
          </p>
        </div>
      </div>
    </template>
  </PageSection>
</template>

<script>
import PageSection from 'app/components/common/elements/PageSection.vue'

export default {
  name: 'HackstackFeaturesSection',
  components: {
    PageSection,
  },
  props: {
    variant: {
      type: String,
      required: true,
      validator: value => ['algebra', 'cyber'].includes(value),
    },
    title: {
      type: String,
      required: true,
    },
    features: {
      type: Array,
      required: true,
    },
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

  ::v-deep .body {
    display: flex;
    flex-direction: row;
  }
}

.section--cyber {
  padding-top: 60px;

  ::v-deep .frame > div:empty {
    display: none;
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
  flex: 1;
  text-align: center;

  @media (max-width: $screen-sm-max) {
    flex-basis: 100%;
  }
}

.section--algebra {
  .feature {
    justify-content: center;
    gap: 24px;
  }

  .feature__icon {
    width: 100px;
    height: 100px;
  }

  .feature__title {
    @extend %font-16;
    white-space: pre-line;
  }
}

.section--cyber {
  .feature {
    gap: 12px;
    max-width: 420px;
  }

  .feature__icon {
    height: 100px;
    width: auto;
    margin-bottom: 12px;
  }

  .feature__title {
    @extend %font-24-30;
  }
}

.feature__icon {
  object-fit: contain;
  flex-shrink: 0;
}

.feature__title {
  color: white;
  margin: 0;
}

.feature__desc {
  @extend %font-18-24;
  color: #B4B4B4;
  margin: 0;
}
</style>
