<template>
  <PageSection class="section">
    <template #heading>
      <div>
        开启你的编程进化之旅
      </div>
      <div class="description">
        选择最适合你的学习计划
      </div>
    </template>
    <template #body>
      <div class="price-grid anim-up">
        <div
          v-for="(plan, index) in pricingPlans"
          :key="index"
          :class="['card-p', { 'active-plan': selectedPlan === index }]"
          @click="selectPlan(index)"
        >
          <div class="ribbon-wrapper">
            <div :class="['ribbon', plan.ribbonClass]">
              {{ plan.ribbonText }}
            </div>
          </div>
          <div :style="{ fontSize: '2.4rem', marginBottom: '5px', fontWeight: plan.featured ? 'bold' : 'bold', color: plan.titleColor }">
            {{ plan.title }}
          </div>
          <div
            class="c-price"
            :style="{ color: plan.priceColor }"
          >
            {{ plan.price }} <span
              class="text-sm font-normal"
              :class="plan.type === 'annual' ? 'text-indigo-300' : 'text-slate-500'"
            >/ {{ plan.duration }}</span>
            <span
              v-if="plan.discount"
              class="bg-indigo-100 text-indigo-700 text-xs px-2 py-0.5 rounded ml-1 align-middle"
            >{{ plan.discount }}</span>
          </div>

          <div
            v-if="plan.saleText"
            class="text-xs text-red-500 font-bold mb-2"
            v-html="plan.saleText"
          />

          <div
            v-if="plan.highlight"
            :class="plan.highlightClass"
            v-html="plan.highlight"
          />

          <div
            v-if="plan.note"
            class="text-xs text-slate-400 mb-4"
          >
            {{ plan.note }}
          </div>

          <ul>
            <li
              v-for="(feature, idx) in plan.features"
              :key="idx"
              v-html="feature"
            />
          </ul>
        </div>
      </div>
      <CTAButton
        class="cta-button"
        @clickedCTA="onClickMainCta"
      >
        立即购买
        <template #description>
          支持 <i class="fa-brands fa-weixin text-green-500" /> 微信支付 | 开通后权益立即生效，马上加入，快速进步！
        </template>
      </CTAButton>
      <backbone-modal-harness
        :modal-view="SubscribeModal"
        :open="isSubscribeModalOpen"
        :modal-options="{ forceShowMonthlySub: true }"
        @close="isSubscribeModalOpen = false"
      />
    </template>
  </PageSection>
</template>
<script>
import PageSection from '../../../../components/common/elements/PageSection'
import CTAButton from '../../../../components/common/buttons/CTAButton.vue'
import BackboneModalHarness from 'app/views/common/BackboneModalHarness.vue'
import SubscribeModal from 'app/views/core/SubscribeModal.js'
export default {
  name: 'PageSection8',
  components: {
    PageSection,
    CTAButton,
    BackboneModalHarness,
  },
  data () {
    return {
      SubscribeModal,
      isSubscribeModalOpen: false,
      selectedPlan: 1, // Default to middle plan
      pricingPlans: [
        {
          type: 'monthly',
          title: '月度会员',
          price: '¥99',
          duration: '1个月',
          ribbonText: '体验尝鲜',
          ribbonClass: 'ribbon-gray',
          titleColor: '#1e293b',
          priceColor: '#1e293b',
          features: [
            '<i class="fa-solid fa-check text-green-500"></i> 适合短期高效极速学习，集中攻克难点',
            '<i class="fa-solid fa-check text-green-500"></i> 解锁全库关卡权限，快速补充知识',
            '<i class="fa-solid fa-question text-slate-400"></i> 不确定是否适合？从这里开始',
          ],
        },
        {
          type: 'quarterly',
          title: '季度会员',
          price: '¥269',
          duration: '3个月',
          ribbonText: '最多人选择',
          ribbonClass: 'ribbon-gold',
          titleColor: '#b45309',
          priceColor: '#b45309',
          saleText: '(原价<span class="line-through">¥299</span>，寒假特惠：立省30元)',
          highlight: '<div class="bg-orange-100 rounded-lg p-3 mb-2 w-full"><span class="block text-orange-800 font-bold text-sm">完整学习周期，打好编程基础</span><span class="block text-orange-700 font-medium text-xs">适合大多数学习者</span></div>',
          note: '🔥 约等于一顿火锅的钱',
          featured: true,
          features: [
            '<i class="fa-solid fa-check text-orange-500"></i> 解锁全库关卡权限，快速提升',
            '<i class="fa-solid fa-star text-orange-500"></i> 最高性价比，轻松学习，全面进步',
            '<i class="fa-solid fa-gem text-orange-500"></i> 额外赠送价值30元的 3000 宝石，助力学习',
          ],
        },
        {
          type: 'annual',
          title: '年度会员',
          price: '¥999',
          duration: '365天',
          discount: '(8.3折)',
          ribbonText: '长期成长计划',
          ribbonClass: 'ribbon-blue',
          titleColor: '#4338ca',
          priceColor: '#4338ca',
          highlight: '<div class="bg-indigo-100 rounded-lg p-3 mb-2 mt-2 w-full"><span class="block text-indigo-900 font-bold text-sm">最佳投资，专注成长</span><span class="block text-indigo-800 font-medium text-xs">给真正想学会编程的人</span></div>',
          note: '平均每天仅 ¥2.7 元',
          features: [
            '<li class="font-bold text-indigo-800 mb-2 border-b border-indigo-100 pb-1">季度会员所有权益再加：</li>',
            '<i class="fa-solid fa-file-contract text-indigo-500"></i> 年度会员专属学习报告',
            '<i class="fa-solid fa-map text-indigo-500"></i> 年度会员专属详细知识点图总结',
            '<i class="fa-solid fa-headset text-indigo-500"></i> 客服优先解答疑问',
            '<i class="fa-solid fa-gem text-indigo-500"></i> 尊享礼包：赠送价值160元的16000 宝石，助你更快进阶',
          ],
        },
      ],
    }
  },
  methods: {
    selectPlan (index) {
      this.selectedPlan = index
    },
    onClickMainCta () {
      if (me.isPremium()) {
        application.router.navigate('/play', { trigger: true })
      } else {
        this.isSubscribeModalOpen = true
      }
    },
  },
}
</script>
<style scoped lang="scss">
/* Pricing Section */
.price-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 20px;
  max-width: 1100px;
  width: 100%;
  align-items: flex-start;
  margin-bottom: 25px;
}
.cta-button {
  margin-top: 2rem !important;
}

@media (min-width: 768px) {
  .price-grid {
    grid-template-columns: repeat(3, 1fr);
  }
}

.card-p {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 20px;
  padding: 35px 25px 25px;
  display: flex;
  flex-direction: column;
  text-align: center;
  position: relative;
  transition: all 0.3s;
  cursor: pointer;
  height: 100%;
  overflow: hidden;
}

.card-p:hover {
  transform: translateY(-5px);
  box-shadow: 0 15px 30px rgba(0,0,0,0.08);
}

.ribbon-wrapper {
  position: absolute;
  top: 0;
  left: 0;
  width: 120px;
  height: 120px;
  overflow: hidden;
  pointer-events: none;
}

.ribbon {
  position: absolute;
  top: 25px;
  left: -40px;
  width: 160px;
  text-align: center;
  transform: rotate(-45deg);
  font-size: 1.44rem;
  font-weight: 900;
  color: white;
  box-shadow: 0 2px 5px rgba(0,0,0,0.2);
  padding: 5px 0;
  letter-spacing: 1px;
}

.ribbon-gray {
  background: #94a3b8;
}

.ribbon-gold {
  background: #F2BE22;
  color: #422B06;
}

.ribbon-blue {
  background: #4338ca;
}

.card-p.active-plan {
  border: 3px solid #F2BE22;
  transform: scale(1.02);
  z-index: 10;
  background: #fffefb;
  box-shadow: 0 20px 40px rgba(242, 190, 34, 0.15);
}

@media (min-width: 768px) {
  .card-p.active-plan {
    transform: scale(1.05);
  }
}

.card-p.annual {
  border: 2px solid #4338ca;
  background: #f5f3ff;
}

.c-price {
  font-size: 3.52rem;
  font-weight: 900;
  margin-bottom: 5px;
  color: #1e293b;
}

.c-price span {
  font-size: 1.44rem;
  color: #64748b;
  font-weight: normal;
}

.card-p ul {
  list-style: none;
  text-align: left;
  flex: 1;
  font-size: 1.36rem;
  color: #475569;
  margin-top: 15px;
  padding-left: 0;
}

.card-p li {
  margin-bottom: 10px;
  display: flex;
  gap: 10px;
  align-items: flex-start;
  line-height: 1.4;
}

.card-p li i {
  margin-top: 3px;
  flex-shrink: 0;
}
</style>