<template>
  <div class="container">
    <p class="step-boxes-header">
      <mixed-color-label
        :text="$t('parents_v2.step_boxes_header_text')"
      />
    </p>
    <div class="step-boxes">
      <StepBox
        :title="$t('parents_v2.step_box_1_title')"
        :subtitle="$t('parents_v2.step_box_1_subtitle')"
        image-alt="Image"
        image-src="/images/pages/parents/steps/step_1.webp"
        :footer-text="$t('parents_v2.step_box_1_footer_text')"
      >
        <template #icon>
          <TextBubble />
        </template>
      </StepBox>
      <div class="arrow-right">
        <StepBoxArrow />
      </div>
      <StepBox
        :title="$t('parents_v2.step_box_2_title')"
        :subtitle="$t('parents_v2.step_box_2_subtitle')"
        image-alt="Image"
        image-src="/images/pages/parents/steps/step_2.webp"
        :footer-text="$t('parents_v2.step_box_2_footer_text')"
      >
        <template #icon>
          <TextBubble />
        </template>
      </StepBox>
      <div class="arrow-up">
        <StepBoxArrow />
      </div>
      <div class="empty" />
      <div class="arrow-down">
        <StepBoxArrow />
      </div>
      <StepBox
        :title="$t('parents_v2.step_box_3_title')"
        :subtitle="$t('parents_v2.step_box_3_subtitle')"
        image-alt="Image"
        image-src="/images/pages/parents/steps/step_3.webp"
        :footer-text="$t('parents_v2.step_box_3_footer_text')"
      >
        <template #icon>
          <ConsoleController />
        </template>
      </StepBox>
      <div class="arrow-left">
        <StepBoxArrow />
      </div>
      <StepBox
        :title="$t('parents_v2.step_box_4_title')"
        :subtitle="$t('parents_v2.step_box_4_subtitle')"
        image-alt="Image"
        image-src="/images/pages/parents/steps/step_4.webp"
        :footer-text="$t('parents_v2.step_box_4_footer_text')"
      >
        <template #icon>
          <ConsoleController />
        </template>
      </StepBox>
    </div>
    <p class="step-boxes-footer">
      <mixed-color-label
        :text="$t('parents_v2.step_boxes_footer_text')"
      />
    </p>
  </div>
</template>

<script>
import MixedColorLabel from 'app/components/common/labels/MixedColorLabel.vue'
import StepBox from './StepBox.vue'
import TextBubble from './image-components/TextBubble.vue'
import ConsoleController from './image-components/ConsoleController.vue'
import StepBoxArrow from './image-components/StepBoxArrow.vue'

export default {
  name: 'StepBoxes',
  components: {
    MixedColorLabel,
    StepBox,
    TextBubble,
    ConsoleController,
    StepBoxArrow
  }
}
</script>

<style scoped lang="scss">
.step-boxes {
  display: grid;
  grid-template-columns: 470fr 130fr 470fr;
  grid-template-rows: 470fr 130fr 470fr;
  gap: 10px;

  .arrow-right,
  .arrow-up,
  .arrow-down,
  .arrow-left {
    display: flex;
    justify-content: center;
    align-items: center;
    &.arrow-down {
      transform: rotate(90deg);
    }
    &.arrow-up {
      transform: rotate(-90deg);
    }
    &.arrow-left {
      transform: rotate(180deg);
    }

    svg {
      width: min(70px, 10vw);
    }
  }
}

.step-boxes-header,
.step-boxes-footer {
  text-align: center;
  padding-top: 60px;
  padding-bottom: 60px;
}
</style>