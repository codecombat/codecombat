<template>
  <div id="page-hackstack-new">
    <hero-section />
    <policy-section />
    <solutions-section />
    <features-section />
    <course-path-section />
    <learning-mode-section />
    <student-projects-section />
    <outcomes-section />
    <competition-section />
    <ai-models-section />
    <testimonials-section />
    <steps-section />
    <faq-section />
    <honor-section />
    <cta-section />

    <div
      v-if="showQRModal"
      id="qrModal"
      class="qr-modal-overlay"
      @click.self="showQRModal = false"
    >
      <div class="qr-modal-content">
        <h4 class="qr-modal-title">
          扫码预约演示
        </h4>
        <img
          src="/images/pages/hackstack-new/qr.png"
          alt="QR Code"
          class="qr-image"
        >
        <div
          class="qr-modal-close"
          @click="showQRModal = false"
        >
          关闭
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import HeroSection from './HeroSection.vue'
import PolicySection from './PolicySection.vue'
import SolutionsSection from './SolutionsSection.vue'
import FeaturesSection from './FeaturesSection.vue'
import CoursePathSection from './CoursePathSection.vue'
import LearningModeSection from './LearningModeSection.vue'
import StudentProjectsSection from './StudentProjectsSection.vue'
import OutcomesSection from './OutcomesSection.vue'
import CompetitionSection from './CompetitionSection.vue'
import AiModelsSection from './AiModelsSection.vue'
import TestimonialsSection from './TestimonialsSection.vue'
import StepsSection from './StepsSection.vue'
import FaqSection from './FaqSection.vue'
import HonorSection from './HonorSection.vue'
import CtaSection from './CtaSection.vue'

export default Vue.extend({
  name: 'PageHackstackNew',
  components: {
    HeroSection,
    PolicySection,
    SolutionsSection,
    FeaturesSection,
    CoursePathSection,
    LearningModeSection,
    StudentProjectsSection,
    OutcomesSection,
    CompetitionSection,
    AiModelsSection,
    TestimonialsSection,
    StepsSection,
    FaqSection,
    HonorSection,
    CtaSection,
  },
  provide () {
    return {
      toggleQRModal: this.toggleQRModal,
    }
  },
  data () {
    return {
      showQRModal: false,
    }
  },
  methods: {
    toggleQRModal (show) {
      this.showQRModal = show
    },
  },
})
</script>

<style scoped lang="scss">
#page-hackstack-new {
  background-color: #021e27;
  color: #fff;
  font-family: "PingFang SC", "Microsoft YaHei", sans-serif;
  overflow-x: hidden;
}

.qr-modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0,0,0,0.7);
  z-index: 9999;
  display: flex;
  justify-content: center;
  align-items: center;
}

.qr-modal-content {
  background: #fff;
  padding: 30px;
  border-radius: 12px;
  text-align: center;
  box-shadow: 0 10px 30px rgba(0,0,0,0.5);
}

.qr-modal-title {
  color: #021e27;
  margin-top: 0;
  font-weight: bold;
}

.qr-image {
  max-width: 200px;
  margin: 15px 0;
  border-radius: 8px;
}

.qr-modal-close {
  color: #888;
  margin-top: 10px;
  cursor: pointer;
  font-weight: bold;
  padding: 10px;
  border-radius: 6px;
  background: #f0f0f0;
  &:hover {
    background: #e0e0e0;
  }
}
</style>
