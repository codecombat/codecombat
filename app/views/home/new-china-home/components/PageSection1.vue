<template>
  <PageSection class="section">
    <template #body>
      <img
        src="/images/pages/cn-home/c1.webp"
        alt="云朵"
        class="cloud-left-top"
      >
      <img
        src="/images/pages/cn-home/c1.webp"
        alt="云朵"
        class="cloud-button-right"
      >
      <img
        src="/images/pages/cn-home/c3.webp"
        alt="云朵"
        class="cloud-text-right-top"
      >
      <two-column-block class="block">
        <template #column-one>
          <div class="content">
            <div class="head">
              <span class="">玩游戏</span>
              <span class="">学编程</span>
            </div>
            <div class="description">
              玩着玩着小白变编程高手
            </div>
            <CTAButton
              class="cta-button"
              href="/play"
              target="_self"
            >
              {{ ctaText() }}
            </CTAButton>
          </div>
        </template>
        <template #column-two>
          <img
            class="image w-full max-w-sm md:max-w-3xl mx-auto drop-shadow-[-20px_20px_50px_rgba(0,0,0,0.1)] hero-image"
            src="/images/pages/cn-home/techgirl.webp"
          >
        </template>
      </two-column-block>
    </template>
  </PageSection>
</template>
<script>
import PageSection from '../../../../components/common/elements/PageSection'
import CTAButton from '../../../../components/common/buttons/CTAButton.vue'

import TwoColumnBlock from '../../../../components/common/elements/TwoColumnBlock'
export default {
  name: 'PageSection1',
  components: {
    PageSection,
    CTAButton,
    TwoColumnBlock,
  },
  methods: {
    ctaText () {
      if (me.isAnonymous()) {
        return '立即免费体验'
      } else {
        return '开始冒险'
      }
    },
  },
}
</script>
<style scoped lang="scss">
.head {
  font-size: clamp(6.0rem, 3.2rem + 8vw, 9.6rem);
  font-weight: 900;
  line-height: 1;
  display: flex;
  flex-wrap: wrap;
  row-gap: 1rem;
  column-gap: 2.5rem;

  span {
    white-space: nowrap;
  }
}
.description {
  font-size: 2.96rem;
  margin-top: 3.2rem;
}
/* --- 第一页特效 --- */
@keyframes float { 0%, 100% { transform: translate(0, 0); } 50% { transform: translate(20px, -10px); } }
/* 移动端弱化云朵，防止遮挡文字 */
.cloud-left-top { position: absolute; top: -80px; left: 20px; width: 250px; animation: float 8s ease-in-out infinite; z-index: 0; opacity: 0.6; pointer-events: none; }
.cloud-button-right { position: absolute; top: 100px; left: 40%; width: 150px; transform: rotate(-15deg); z-index: 0; opacity: 0.6; pointer-events: none; }
.cloud-text-right-top { position: absolute; top: -150px; left: 45%; width: 120px; z-index: 0; opacity: 0.6; pointer-events: none; }
.cloud-image-right-top { position: absolute; top: -180px; right: 80px; width: 120px; z-index: 0; pointer-events: none; }

@media (max-width: 768px) {
  .cloud-left-top, .cloud-button-right, .cloud-text-right-top {
    opacity: 0.2; /* 手机端大幅降低透明度 */
    width: 150px;
  }
  .hero-image-glow::before { display: none; } /* 手机端移除发光，提升性能 */
}

@keyframes breathe { 0%, 100% { transform: translateY(0); } 50% { transform: translateY(-20px); } }
.hero-image { animation: breathe 4s ease-in-out infinite; }
.hero-image-glow::before {
  content: ''; position: absolute; top: -10%; left: -10%; width: 120%; height: 120%;
  background: radial-gradient(ellipse at center, rgba(99, 102, 241, 0.3) 0%, rgba(6, 182, 212, 0.2) 50%, transparent 70%);
  border-radius: 50%; animation: glow-pulse 3s ease-in-out infinite; z-index: -1;
}
@keyframes glow-pulse { 0%, 100% { opacity: 0.6; transform: scale(1); } 50% { opacity: 0.9; transform: scale(1.05); } }
</style>