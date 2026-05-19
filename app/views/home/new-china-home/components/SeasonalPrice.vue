<template>
  <div class="card featured">
    <div class="gold-badge">
      更多人选择
    </div>

    <div class="shimmer-mask" />

    <div class="featured-content">
      <div class="featured-header">
        <img
          src="/images/pages/subscribe/AnyaPose.png"
          alt="Anya"
          class="anya-icon"
        >
        <h2>完整编程成长计划</h2>
      </div>

      <div class="price-row">
        <span class="symbol">¥</span><span class="amount">{{ price }}</span><span class="unit"> / 3个月</span>
      </div>

      <div
        v-if="false"
        style="margin-top:-2px; margin-bottom:5px; font-size:11px; color:#999;"
      >
        <span style="text-decoration:line-through;">原价¥299</span> <span style="color:#e74c3c; font-weight:bold;">限时立省 30元</span>
        <br><span class="deadline-text">⏰ 3月1日恢复原价299元</span>
      </div>

      <div class="hot-pot-tag">
        🔥 3个月系统练习，帮你打稳编程基础
      </div>

      <ul class="check-list">
        <li class="positive">
          解锁全部关卡与完整内容
        </li>
        <li class="positive">
          通过闯关练习掌握编程基础
        </li>
        <li class="positive">
          获得阶段学习记录与成长反馈
        </li>
        <li class="positive">
          卡关时可使用 AI 提示辅助学习
        </li>
        <li
          class="positive"
          style="color:#2980b9;"
        >
          赠送价值90元的 9000 宝石
        </li>
      </ul>

      <button
        class="btn btn-gold"
        @click="$emit('clicked')"
      >
        开始 3 个月系统学习
      </button>
      <div class="sub-btn-text">
        💡 多数新用户从这个计划开始
      </div>
    </div>
  </div>
</template>
<script>
export default {
  props: ['price'],
}
</script>