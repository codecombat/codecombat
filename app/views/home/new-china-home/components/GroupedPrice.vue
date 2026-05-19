<template>
  <div class="card">
    <div class="corner-ribbon ribbon-green">
      省近1000元
    </div>
    <div class="card-title">
      家庭/学习小队计划
    </div>
    <div class="price-row">
      <span class="symbol">¥</span><span class="amount">{{ price }}</span><span class="unit"> / 年 </span>
    </div>

    <div style="font-size:11px; color:#888; margin-bottom:5px;">
      3个账号
    </div>
    <div
      class="info-box"
      style="background:#e8f8f5; color:#16a085; padding:8px;"
    >
      <span style="font-weight:bold; display:block; font-size:12px;">3人独立学习，进度互不影响</span>
    </div>

    <ul class="check-list">
      <li class="positive">
        每个账号均享年度会员全部权益
      </li>
      <li class="positive">
        每个账号独立保存学习进度与成就
      </li>
      <li class="positive">
        适合兄弟姐妹、同学好友组队学习
      </li>
      <li class="positive">
        家长可为多个孩子统一购买更省心
      </li>
      <li class="positive">
        人均约 ¥666/年，长期学习更划算
      </li>
    </ul>

    <button
      class="btn btn-green-theme"
      @click="$emit('clicked')"
    >
      开启学习小队计划
    </button>
    <div style="font-size:11px; color:#16a085; margin-top:8px; font-weight:bold;">
      👨‍👩‍👧 两个人用就不亏，三个人用更划算
    </div>
  </div>
</template>
<script>
export default {
  props: ['price'],
}
</script>