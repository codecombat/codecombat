<template>
  <div class="card">
    <div class="corner-ribbon ribbon-purple">
      长期成长计划
    </div>
    <div class="card-title">
      年度会员
    </div>
    <div class="price-row">
      <span class="symbol">¥</span><span class="amount">{{ price }}</span><span class="unit"> / 365天</span>
    </div>
    <div style="font-size:11px; color:#888; margin-bottom:5px;">
      8.3 折 · 平均每天仅 2.7元
    </div>

    <div
      class="info-box"
      style="background:#f3e5f5; color:#8e44ad; padding: 8px;"
    >
      <span style="font-weight:bold; display:block; font-size:12px;">适合长期系统学习，从入门到进阶</span>
    </div>

    <ul class="check-list">
      <li class="positive">
        包含完整编程成长计划全部权益
      </li>
      <li class="positive">
        解锁全年系统学习内容
      </li>
      <li class="positive">
        获得年度学习报告与成长记录
      </li>
      <li class="positive">
        年度知识点复盘，方便查漏补缺
      </li>
      <li
        class="positive"
        style="color:#2980b9;"
      >
        赠送价值 420元 的 42000 宝石
      </li>
    </ul>

    <button
      class="btn btn-purple"
      @click="$emit('clicked')"
    >
      开启全年系统学习
    </button>

    <div style="font-size:11px; color:#8e44ad; margin-top:8px; font-weight:bold;">
      🌟 每天不到3元，长线投资更划算
    </div>
  </div>
</template>
<script>
export default {
  props: ['price'],
}
</script>