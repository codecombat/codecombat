<template>
  <PageSection class="section">
    <template #body>
      <two-column-block>
        <template #column-one>
          <div class="lg-col-span-5 space-y-6 md-space-y-8 anim-left flex flex-col justify-center">
            <div class="space-y-4 text-center lg-text-left">
              <div class="std-section-title text-3xl md-text-5xl lg-text-6xl">
                <span class="block mb-2">放心自学</span>
                <span class="highlight-primary whitespace-nowrap">AI私教随时在线</span>
              </div>
            </div>
            <div class="text-lg md-text-xl text-slate-600 leading-relaxed border-l-4 border-indigo-400 pl-6">
              自由探索，支持多解法，鼓励自主学习。<br>
              卡住了？一键呼出AI，秒懂问题在哪。
            </div>

            <CTAButton
              class="cta-button"
              href="/play"
              target="_self"
            >
              立即免费体验
            </CTAButton>
          </div>
        </template>
        <template #column-two>
          <img src="/images/pages/cn-home/ai_robot_mentor.png">
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
  name: 'PageSection4',
  components: {
    PageSection,
    CTAButton,
    TwoColumnBlock,
  },
}
</script>