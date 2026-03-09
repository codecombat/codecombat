<template>
  <PageSection class="section">
    <template #heading>
      {{ $t('hackstack_algebra_page.module_structure_title') }}
    </template>
    <template #body>
      <div class="modules">
        <div
          v-for="(mod, index) in modules"
          :key="mod.num"
          class="module-entry"
        >
          <AlgebraStepCard
            :step-num="mod.num"
            :title="$t(`hackstack_algebra_page.module_${mod.num}_title`)"
            :description="$t(`hackstack_algebra_page.module_${mod.num}_desc`)"
            :tag-text="$t(`hackstack_algebra_page.module_${mod.num}_tag`)"
            :tag-type="mod.tagType"
          />
          <div
            v-if="index < modules.length - 1"
            class="modules__arrow"
            aria-hidden="true"
          >
            ›
          </div>
        </div>
      </div>
    </template>
  </PageSection>
</template>

<script>
import PageSection from 'app/components/common/elements/PageSection.vue'
import AlgebraStepCard from './AlgebraStepCard.vue'

export default {
  name: 'ModuleStructureSection',
  components: { PageSection, AlgebraStepCard },
  data () {
    return {
      modules: [
        { num: 1, tagType: 'traditional' },
        { num: 2, tagType: 'ai-traditional' },
        { num: 3, tagType: 'ai-traditional' },
        { num: 4, tagType: 'ai-enabled' },
        { num: 5, tagType: 'ai-enabled' },
      ],
    }
  },
}
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";
@import "app/styles/component_variables.scss";

.section {
  background: var(--color-section-bg);

  ::v-deep .heading {
    color: white;
  }

  padding: 50px 35px;

  ::v-deep .body {
    // your overrides here, e.g.:
    padding-left: 5px;
    padding-right: 5px;
  }
}

.modules {
  display: flex;
  align-items: stretch;
  justify-content: center;
  flex-wrap: wrap;
  row-gap: 40px;
  width: 100%;
}

// Each entry holds a card + its trailing arrow side by side
.module-entry {
  display: flex;
  align-items: stretch;
}

.modules__arrow {
  color: var(--color-primary-1);
  font-size: 36px;
  line-height: 1;
  padding: 0 8px;
  align-self: center;

  @media (max-width: $screen-sm-max) {
    display: none;
  }
}
</style>
