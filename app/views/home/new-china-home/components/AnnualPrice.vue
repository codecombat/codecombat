<template>
  <div class="card">
    <div class="corner-ribbon ribbon-purple">
      {{ context.planText || '长期成长计划' }}
    </div>
    <div class="card-title">
      {{ context.title || '年度会员' }}
    </div>
    <div class="price-row">
      <span class="symbol">¥</span><span class="amount">{{ amount }}</span><span class="unit"> / 365天</span>
    </div>
    <div style="font-size:11px; color:#888; margin-bottom:5px;">
      {{ context.inspiration || '8.3 折 · 平均每天仅 2.7元' }}
    </div>

    <div
      class="info-box"
      style="background:#f3e5f5; color:#8e44ad; padding: 8px;"
    >
      <span style="font-weight:bold; display:block; font-size:12px;">
        {{ context.description || '适合长期系统学习，从入门到进阶' }}
      </span>
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
      class="btn btn-purple"
      @click="$emit('clicked')"
    >
      {{ context.cta || '开启全年系统学习' }}
    </button>

    <div style="font-size:11px; color:#8e44ad; margin-top:8px; font-weight:bold;">
      {{ context.extra || '🌟 每天不到3元，长线投资更划算' }}
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
        { text: '包含完整编程成长计划全部权益' },
        { text: '解锁全年系统学习内容' },
        { text: '获得年度学习报告与成长记录' },
        { text: '年度知识点复盘，方便查漏补缺' },
        { text: '赠送价值 420元 的 42000 宝石', type: 'gem' },
      ]
    },
  },
}
</script>