<template>
  <div class="card">
    <div class="corner-ribbon ribbon-gold">
      {{ context.planText || '快速开始' }}
    </div>
    <div class="card-title">
      {{ context.title || '季度成长计划' }}
    </div>
    <div class="price-row">
      <span class="symbol">¥</span><span class="amount">{{ amount }}</span><span class="unit"> / 3个月</span>
    </div>

    <div
      v-if="false"
      style="margin-top:-2px; margin-bottom:5px; font-size:11px; color:#999;"
    >
      <span style="text-decoration:line-through;">原价¥299</span> <span style="color:#e74c3c; font-weight:bold;">限时立省 30元</span>
      <br><span class="deadline-text">⏰ 3月1日恢复原价299元</span>
    </div>

    <div style="font-size:11px; color:#888; margin-bottom:5px;">
      {{ context.inspiration || '平均每天约 3.3 元' }}
    </div>
    <div class="hot-pot-tag">
      {{ context.description || '🔥 3个月系统练习，帮你打稳编程基础' }}
    </div>

    <ul class="check-list">
      <li
        v-for="positive in positives"
        :key="positive.text"
        class="positive"
        :style="positive.type === 'gem' ? 'color: #2980b9;' : ''"
      >
        {{ positive.text }}
      </li>
    </ul>

    <button
      class="btn btn-gold"
      @click="$emit('clicked')"
    >
      {{ context.cta || '开始 3 个月系统学习' }}
    </button>
    <div class="sub-btn-text">
      {{ context.extra || '💡 适合首次探索编程世界的同学' }}
    </div>
  </div>
</template>
<script>
export default {
  props: ['price'],
  computed: {
    amount () {
      return (this.price?.amount / 100) || '-'
    },
    context () {
      return this.price?.metadata || {}
    },
    positives () {
      return this.context.positives || [
        { text: '解锁全部关卡与完整内容' },
        { text: '通过闯关练习掌握编程基础' },
        { text: '获得阶段学习记录与成长反馈' },
        { text: '卡关时可使用 AI 提示辅助学习' },
        { text: '赠送价值90元的 9000 宝石', type: 'gem' },
      ]
    },
  },
}
</script>