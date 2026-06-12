<template>
  <div class="card featured">
    <div class="gold-badge">
      {{ context.planText || '更多人选择' }}
    </div>

    <div class="shimmer-mask" />

    <div class="featured-content">
      <div class="featured-header">
        <img
          src="/images/pages/subscribe/AnyaPose.png"
          alt="Anya"
          class="anya-icon"
        >
        <h2>
          {{ context.title || '完整编程成长计划' }}
        </h2>
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
        {{ context.extra || '💡 多数新用户从这个计划开始' }}
      </div>
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