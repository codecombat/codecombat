<template>
  <PageSection class="section">
    <template #heading>
      {{ $t('hackstack_cyber_page.pathways_title') }}
    </template>
    <template #body>
      <div class="pathways">
        <div class="pathways__cta-group">
          <CTAButton
            v-if="isAnonymous()"
            class="pathways__cta"
            @clickedCTA="$emit('open-signup-modal')"
          >
            {{ $t('hackstack_cyber_page.pathways_cta') }}
          </CTAButton>
          <CTAButton
            v-else
            href="/teachers/guide/hackstack/cyber"
            class="pathways__cta"
          >
            {{ $t('hackstack_cyber_page.pathways_cta_try') }}
          </CTAButton>
          <p class="pathways__subtitle">
            {{ $t('hackstack_cyber_page.pathways_subtitle') }}
          </p>
        </div>
        <div class="modules">
          <div
            v-for="(mod, index) in modules"
            :key="mod.num"
            class="module-entry"
          >
            <CyberModuleCard
              :module-num="mod.num"
              :title="$t(`hackstack_cyber_page.module_${mod.num}_title`)"
              :description="$t(`hackstack_cyber_page.module_${mod.num}_desc`)"
              :tag-text="$t(`hackstack_cyber_page.module_${mod.num}_tag`)"
              :image-src="`/images/pages/hackstack/cyber/module-${mod.num}.jpg`"
              :icon-src="`/images/pages/hackstack/cyber/module-icon-${mod.num}.png`"
            />
            <div
              v-if="index < modules.length - 1"
              class="modules__arrow"
              aria-hidden="true"
            >
              ❯
            </div>
          </div>
        </div>
      </div>
    </template>
    <template #tail>
      <CTAButton
        href="/standards"
        target="_blank"
        class="standards-cta"
      >
        {{ $t('hackstack_cyber_page.standards_cta') }}
      </CTAButton>
    </template>
  </PageSection>
</template>

<script>
import PageSection from 'app/components/common/elements/PageSection.vue'
import CTAButton from 'app/components/common/buttons/CTAButton.vue'
import CyberModuleCard from './CyberModuleCard.vue'

export default {
  name: 'CyberPathwaysSection',
  components: { PageSection, CTAButton, CyberModuleCard },
  data () {
    return {
      modules: [
        { num: 1 },
        { num: 2 },
        { num: 3 },
        { num: 4 },
        { num: 5 },
      ],
    }
  },
  methods: {
    isAnonymous () {
      return typeof me === 'undefined' || me.isAnonymous()
    },
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
    max-width: 1320px;
    padding-left: 5px;
    padding-right: 5px;
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

.pathways__subtitle {
  @extend %font-18-24;
  color: white;
  margin: 0;
  text-align: center;
}

.modules {
  display: flex;
  align-items: stretch;
  justify-content: center;
  flex-wrap: wrap;
  row-gap: 40px;
  column-gap: 16px;
  width: 100%;

  // one row of five at desktop, like the design; cards shrink instead of wrapping
  @media (min-width: $screen-lg) {
    flex-wrap: nowrap;
  }
}

.module-entry {
  display: flex;
  align-items: stretch;

  @media (min-width: $screen-lg) {
    flex: 1 1 0;
    min-width: 0;

    .module-card {
      flex: 1 1 auto;
      min-width: 0;
    }
  }
}

.modules__arrow {
  color: var(--color-primary-1);
  font-size: 40px;
  font-weight: bold;
  line-height: 1;
  padding: 0 6px;
  // sit at the photo band of the cards, like the design
  align-self: flex-start;
  margin-top: 80px;

  @media (max-width: $screen-sm-max) {
    display: none;
  }
}

.standards-cta {
  margin-top: 40px;
}
</style>
