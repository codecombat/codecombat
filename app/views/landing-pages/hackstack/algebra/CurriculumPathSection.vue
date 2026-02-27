<template>
  <PageSection class="section">
    <template #heading>
      {{ $t('hackstack_algebra_page.curriculum_path_title') }}
    </template>
    <template #body>
      <div class="curriculum">
        <template v-if="isCtaVisible">
          <CTAButton
            class="curriculum__cta"
            @clickedCTA="$emit('open-signup-modal')"
          >
            {{ $t('hackstack_algebra_page.curriculum_path_cta') }}
          </CTAButton>
          <p class="curriculum__subtitle">
            {{ $t('hackstack_algebra_page.curriculum_path_subtitle') }}
          </p>
        </template>
        <img
          class="curriculum__diagram"
          src="/images/pages/hackstack/algebra/ai-algebra-curriculum.svg"
          alt="Algebra + AI Curriculum Path"
        >
      </div>
    </template>
  </PageSection>
</template>

<script>
import PageSection from 'app/components/common/elements/PageSection.vue'
import CTAButton from 'app/components/common/buttons/CTAButton.vue'

export default {
  name: 'CurriculumPathSection',
  components: { PageSection, CTAButton },
  computed: {
    isCtaVisible () {
      return typeof me !== 'undefined' && me.isAnonymous()
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

  ::v-deep .frame {
    gap: 20px;
  }

}

.curriculum {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  width: 100%;
}

.curriculum__subtitle {
  @extend %font-16;
  color: #B4B4B4;
  margin: 0;
  text-align: center;
}

.curriculum__diagram {
  width: 100%;
  max-width: 1100px;
  height: auto;
  display: block;
  margin-top: 8px;
}
</style>
