<template>
  <PageSection class="section">
    <template #heading>
      <div>
        开通会员，立即获得以下所有权益
      </div>
    </template>
    <template #body>
      <div class="benefits-grid anim-up">
        <div class="benefit-card-new anim-left">
          <div class="benefit-img-box">
            <img
              src="/images/pages/cn-home/all_levels.webp"
              alt="All Levels"
            >
          </div>
          <div class="benefit-text">
            <div class="benefit-title">
              解锁全部2300+实战关卡
            </div>
            <p class="benefit-desc">
              从Python到C++，从网页开发到AI编程，所有内容一次全拥有，全面提升编程能力。
            </p>
          </div>
        </div>

        <div class="benefit-card-new anim-zoom">
          <div class="benefit-img-box">
            <img
              src="/images/pages/cn-home/maps_collection.webp"
              alt="11 Maps"
            >
          </div>
          <div class="benefit-text">
            <div class="benefit-title">
              11个地图全部开启
            </div>
            <div class="highlight-tag">
              适合各个年龄段的学习
            </div>
            <p class="benefit-desc mb-2">
              地牢 + 森林 + 沙漠 + 雪山 + 冰川 + 游戏开发(1-3) + 网页开发(1-2) + 少年版
            </p>
          </div>
        </div>

        <div class="benefit-card-new anim-right">
          <div class="benefit-img-box">
            <img
              src="/images/pages/cn-home/gems_gear.webp"
              alt="Gems and Gear"
            >
          </div>
          <div class="benefit-text">
            <div class="benefit-title">
              闯关就送宝石
            </div>
            <p class="benefit-desc">
              每完成一关都能获得宝石，宝石可兑换酷炫装备和英雄角色，让你的角色形象随编程能力一起成长。
            </p>
          </div>
        </div>
      </div>
      <CTAButton
        class="cta-button"
        href="/play"
        target="_self"
      >
        立即免费体验
      </CTAButton>
    </template>
  </PageSection>
</template>
<script>
import PageSection from '../../../../components/common/elements/PageSection'
import CTAButton from '../../../../components/common/buttons/CTAButton.vue'
export default {
  name: 'PageSection9',
  components: {
    PageSection,
    CTAButton,
  },
}

</script>
<style scoped lang="scss">
/* Benefits Section */
.benefits-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 3.2rem;
  max-width: 1200px;
  width: 100%;
  align-items: stretch;
}

@media (min-width: 1024px) {
  .benefits-grid {
    grid-template-columns: repeat(3, 1fr);
  }
}

.benefit-card-new {
  background: white;
  border: none;
  border-radius: 24px;
  padding: 4.0rem 3.2rem;
  display: flex;
  flex-direction: column;
  gap: 2.4rem;
  height: 100%;
  transition: all 0.4s cubic-bezier(0.2, 0.8, 0.2, 1);
  box-shadow: 0 10px 40px -10px rgba(0,0,0,0.08);
  position: relative;
  z-index: 1;
}

.benefit-card-new:hover {
  transform: translateY(-12px);
  box-shadow: 0 25px 60px -15px rgba(0,0,0,0.15);
  z-index: 5;
}

.benefit-img-box {
  background: transparent;
  border: none;
  min-height: 200px;
  position: relative;
  flex-shrink: 0;
  overflow: visible;
  border-radius: 0;
  box-shadow: none;
  display: flex;
  justify-content: center;
  align-items: center;
}

@media (min-width: 768px) {
  .benefit-img-box {
    min-height: 240px;
  }
}

.benefit-img-box img {
  width: auto;
  height: auto;
  max-width: 100%;
  max-height: 100%;
  object-fit: contain;
  transform: scale(1.1);
  transition: transform 0.4s ease;
}

.benefit-card-new:hover .benefit-img-box img {
  transform: scale(1.2);
}

.benefit-title {
  font-size: 2.16rem;
  font-weight: 900;
  color: #1e293b;
  margin-bottom: 1.2rem;
  line-height: 1.2;
}

.benefit-desc {
  font-size: 1.52rem;
  color: #64748b;
  line-height: 1.6;
}

.highlight-tag {
  display: inline-block;
  background: #fffbeb;
  color: #d97706;
  padding: 4px 12px;
  border-radius: 99px;
  font-size: 1.2rem;
  font-weight: bold;
  margin-bottom: 8px;
  border: 1px solid #fcd34d;
}
</style>