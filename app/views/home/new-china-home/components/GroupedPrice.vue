<template>
  <div class="card">
    <div class="corner-ribbon ribbon-green">
      {{ context.planText || '省近1000元' }}
    </div>
    <div class="card-title">
      {{ context.title || '家庭/学习小队计划' }}
    </div>
    <div class="price-row">
      <span class="symbol">¥</span><span class="amount">{{ amount }}</span><span class="unit"> / 年 </span>
    </div>

    <div style="font-size:11px; color:#888; margin-bottom:5px;">
      {{ context.inspiration || '3个账号' }}
    </div>
    <div
      class="info-box"
      style="background:#e8f8f5; color:#16a085; padding:8px;"
    >
      <span style="font-weight:bold; display:block; font-size:12px;">
        {{ context.description || '3人独立学习，进度互不影响' }}
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
      class="btn btn-green-theme"
      @click="$emit('clicked')"
    >
      {{ context.cta || '开启学习小队计划' }}
    </button>
    <div style="font-size:11px; color:#16a085; margin-top:8px; font-weight:bold;">
      {{ context.extra || '👨‍👩‍👧 两个人用就不亏，三个人用更划算' }}
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
        { text: '每个账号均享年度会员全部权益' },
        { text: '每个账号独立保存学习进度与成就' },
        { text: '适合兄弟姐妹、同学好友组队学习' },
        { text: '家长可为多个孩子统一购买更省心' },
        { text: '人均约 ¥666/年，长期学习更划算' },
      ]
    },
  },
}
</script>