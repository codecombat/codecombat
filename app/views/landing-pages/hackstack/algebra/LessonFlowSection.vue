<template>
  <PageSection class="section">
    <template #heading>
      {{ $t('hackstack_algebra_page.lesson_flow_title') }}
    </template>
    <template #body>
      <div class="flow">
        <div
          v-for="(step, index) in steps"
          :key="step.num"
          class="flow__entry"
        >
          <AlgebraStepCard
            :step-num="step.num"
            :title="$t(`hackstack_algebra_page.step_${step.num}_title`)"
            :description="$t(`hackstack_algebra_page.step_${step.num}_desc`)"
            :tag-text="$t(`hackstack_algebra_page.step_${step.num}_tag`)"
            :tag-type="step.tagType"
            :image-src="step.image"
          />
          <div
            v-if="index < steps.length - 1"
            class="flow__arrow"
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
  name: 'LessonFlowSection',
  components: { PageSection, AlgebraStepCard },
  data () {
    return {
      steps: [
        { num: 1, tagType: 'traditional', image: '/images/pages/hackstack/algebra/lesson-flow-step-1.png' },
        { num: 2, tagType: 'ai-traditional', image: '/images/pages/hackstack/algebra/lesson-flow-step-2.png' },
        { num: 3, tagType: 'ai-traditional', image: '/images/pages/hackstack/algebra/lesson-flow-step-3.png' },
        { num: 4, tagType: 'ai-enabled', image: '/images/pages/hackstack/algebra/lesson-flow-step-4.png' },
        { num: 5, tagType: 'ai-enabled', image: '/images/pages/hackstack/algebra/lesson-flow-step-5.png' },
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

.flow {
  display: flex;
  align-items: stretch;
  justify-content: center;
  flex-wrap: wrap;
  row-gap: 40px;
  width: 100%;
}

// Each entry: card + trailing arrow side by side
.flow__entry {
  display: flex;
  align-items: stretch;
}

.flow__arrow {
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
