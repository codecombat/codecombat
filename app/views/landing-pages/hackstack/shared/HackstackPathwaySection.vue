<template>
  <PageSection :class="['section', `section--${variant}`]">
    <template #heading>
      {{ title }}
    </template>
    <template #body>
      <div
        v-if="variant === 'algebra'"
        class="algebra-items"
      >
        <div
          v-for="(item, index) in items"
          :key="item.key"
          class="algebra-entry"
        >
          <HackstackPathwayCard
            variant="algebra"
            :label="item.label"
            :title="item.title"
            :description="item.description"
            :tag-text="item.tagText"
            :tag-type="item.tagType"
            :image-src="item.imageSrc"
          />
          <div
            v-if="index < items.length - 1"
            class="algebra-arrow"
            aria-hidden="true"
          >
            ›
          </div>
        </div>
      </div>
      <div
        v-else
        class="pathways"
      >
        <div
          v-if="$slots.cta"
          class="pathways__cta-group"
        >
          <slot name="cta" />
        </div>
        <div class="modules">
          <HackstackPathwayCard
            v-for="(item, index) in items"
            :key="item.key"
            variant="cyber"
            :label="item.label"
            :title="item.title"
            :description="item.description"
            :tag-text="item.tagText"
            :image-src="item.imageSrc"
            :icon-src="item.iconSrc"
            :show-separator="index < items.length - 1"
          />
        </div>
      </div>
    </template>
    <template #tail>
      <slot name="tail" />
    </template>
  </PageSection>
</template>

<script>
import PageSection from 'app/components/common/elements/PageSection.vue'
import HackstackPathwayCard from './HackstackPathwayCard.vue'

export default {
  name: 'HackstackPathwaySection',
  components: {
    PageSection,
    HackstackPathwayCard,
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
    items: {
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
  background: var(--color-section-bg);
  padding: 50px 35px;

  ::v-deep .heading {
    color: white;
  }

  ::v-deep .body {
    padding-left: 5px;
    padding-right: 5px;
  }
}

.section--cyber {
  ::v-deep .body {
    max-width: 1320px;
  }
}

.algebra-items {
  display: flex;
  align-items: stretch;
  justify-content: center;
  flex-wrap: wrap;
  row-gap: 40px;
  width: 100%;
}

.algebra-entry {
  display: flex;
  align-items: stretch;
}

.algebra-arrow {
  color: var(--color-primary-1);
  font-size: 36px;
  line-height: 1;
  padding: 0 8px;
  align-self: center;

  @media (max-width: $screen-sm-max) {
    display: none;
  }
}

.pathways {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 40px;
  width: 100%;
}

.pathways__cta-group {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
}

::v-deep .pathways__subtitle {
  @extend %font-18-24;
  color: white;
  margin: 0;
  text-align: center;
}

.modules {
  --module-gap: 32px;
  display: flex;
  align-items: stretch;
  justify-content: center;
  flex-wrap: wrap;
  row-gap: 40px;
  column-gap: 16px;
  width: 100%;

  @media (min-width: $screen-lg) {
    display: grid;
    grid-template-columns: repeat(5, minmax(0, 1fr));
    gap: var(--module-gap);

    ::v-deep .module-card {
      max-width: none;
      min-width: 0;
      width: 100%;
    }
  }
}

::v-deep .standards-cta {
  margin-top: 40px;
}
</style>
