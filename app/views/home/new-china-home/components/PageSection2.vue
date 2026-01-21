<template>
  <PageSection class="section">
    <template #body>
      <two-column-block>
        <template #column-one>
          <video
            class="video"
            src="https://assets.koudashijie.com/videos/CC_Game_Trailer_MP4_New.mp4"
            autoplay
            loop
            muted
            playsinline
          />
        </template>
        <template #column-two>
          <div class="space-y-6 md-space-y-10">
            <div class="text-3xl md-text-5xl lg-text-6xl font-black text-slate-800 leading-snug text-center lg-text-left">
              玩的是<span class="highlight-primary">游戏</span><br>
              <span class="mt-1 md-mt-2 block">练的是<span class="highlight-primary">真本事</span></span>
            </div>
            <ul class="space-y-4 md-space-y-6">
              <li class="flex items-start gap-3 md-gap-4">
                <div class="mt-1.5 md-mt-2.5 w-2 h-2 rounded-full bg-indigo-500 shrink-0" />
                <div class="text-base md-text-xl text-slate-700 leading-relaxed">
                  不用面对黑屏发呆，<span class="font-bold text-slate-900">写一行代码，角色立刻执行</span>
                </div>
              </li>
              <li class="flex items-start gap-3 md-gap-4">
                <div class="mt-1.5 md-mt-2.5 w-2 h-2 rounded-full bg-indigo-500 shrink-0" />
                <div class="text-base md-text-xl text-slate-700 leading-relaxed">
                  <span class="font-bold text-slate-900">函数就是英雄装备</span>，学会一个，解锁一个新技能
                </div>
              </li>
              <li class="flex items-start gap-3 md-gap-4">
                <div class="mt-1.5 md-mt-2.5 w-2 h-2 rounded-full bg-indigo-500 shrink-0" />
                <div class="text-base md-text-xl text-slate-700 leading-relaxed">
                  11张地图，2300+关卡，足够<span class="font-bold text-slate-900">从零基础打到能写项目</span>
                </div>
              </li>
            </ul>

            <div class="bg-white/80 backdrop-blur-xl border border-indigo-200 p-3 md-p-5 rounded-2xl shadow-lg transform hover:-translate-y-1 transition-transform duration-300 flex items-start gap-3 md-gap-4 mt-2">
              <div class="bg-indigo-100 p-2 rounded-full text-indigo-600 flex-shrink-0">
                <i class="fa-solid fa-code text-base md-text-lg" />
              </div>
              <p class="text-sm md-text-base text-slate-700 font-medium pt-0.5">
                你敲下的 <span class="bg-yellow-50 text-yellow-700 px-1 md-px-2 py-0.5 rounded border border-yellow-200 font-bold font-mono">if</span> 和 <span class="bg-yellow-50 text-yellow-700 px-1 md-px-2 py-0.5 rounded border border-yellow-200 font-bold font-mono">for</span>，直接变成英雄的剑招与魔法。
              </p>
            </div>
          </div>
        </template>
      </two-column-block>
    </template>
  </PageSection>
</template>
<script>
import PageSection from '../../../../components/common/elements/PageSection'

import TwoColumnBlock from '../../../../components/common/elements/TwoColumnBlock'
export default {
  name: 'PageSection2',
  components: {
    PageSection,
    TwoColumnBlock,
  },
}
</script>

<style scoped lang="scss">
.video {
  border-radius: 25px;
  border: 5px white solid;
}
</style>