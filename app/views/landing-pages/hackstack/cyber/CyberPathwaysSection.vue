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
          <CyberModuleCard
            v-for="(mod, index) in modules"
            :key="mod.num"
            :module-num="mod.num"
            :title="$t(`hackstack_cyber_page.module_${mod.num}_title`)"
            :description="$t(`hackstack_cyber_page.module_${mod.num}_desc`)"
            :tag-text="$t(`hackstack_cyber_page.module_${mod.num}_tag`)"
            :image-src="`/images/pages/hackstack/cyber/module-${mod.num}.jpg`"
            :icon-src="`/images/pages/hackstack/cyber/module-icon-${mod.num}.png`"
            :show-separator="index < modules.length - 1"
          />
        </div>
      </div>
    </template>
    <template #tail>
      <CTAButton
        href="https://docs.google.com/spreadsheets/d/1CdVBDHLEoY9cUxGgfuQzmEKrFg9Ip4imURIX77Cna8c/edit?gid=1288109106#gid=1288109106"
        target="_blank"
        rel="noopener noreferrer"
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
  --module-gap: 32px;
  display: flex;
  align-items: stretch;
  justify-content: center;
  flex-wrap: wrap;
  row-gap: 40px;
  column-gap: 16px;
  width: 100%;

  // one row of five equal cards at desktop, like the design
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

.standards-cta {
  margin-top: 40px;
}
</style>
