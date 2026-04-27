<template>
  <div
    class="page-section section spaced-section"
    style="background: #021e27;"
  >
    <div class="frame constrained-width">
      <div class="heading">
        <span class="title">荣誉与合作伙伴</span>
      </div>

      <div
        class="grid-3"
        style="margin-top: 40px;"
      >
        <div
          v-for="(honor, index) in honors"
          :key="index"
          class="card-box"
        >
          <h4>{{ honor.title }}</h4>
          <p>{{ honor.desc }}</p>
        </div>
      </div>

      <div class="stats-display">
        <div
          v-for="(stat, index) in stats"
          :key="index"
          class="stat-item"
        >
          <h2 class="stat-val">
            {{ stat.val }}
          </h2>
          <p class="stat-label">
            {{ stat.label }}
          </p>
        </div>
      </div>
      <div class="stats-note">
        以上数据为扣哒世界（CodeCombat）全球平台累计数据
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'HonorSection',
  data () {
    return {
      honors: [
        { title: '教育部白名单赛事平台', desc: '扣哒世界是全国青少年科技教育成果展示大赛AI算法竞技赛的独家技术合作平台，该赛事已入选教育部2025—2028学年全国性竞赛活动白名单' },
        { title: '国际信息学奥林匹克竞赛（IOI）合作平台', desc: '2021年，CodeCombat竞技场被选为第33届国际信息学奥林匹克竞赛（IOI）专项赛平台，来自87个国家的信奥国家队选手通过扣哒世界多人竞技场展开对战' },
        { title: 'Code.org官方教育合作伙伴', desc: 'CodeCombat是全球最大的计算机科学教育非营利组织的官方合作成员' },
      ],
      stats: [
        { val: '200+', label: '覆盖国家和地区' },
        { val: '2000万+', label: '全球学习者' },
        { val: '14万+', label: '全球教师用户' },
        { val: '5万+', label: '全球学校用户' },
      ],
    }
  },
}
</script>

<style scoped lang="scss">
.spaced-section { padding: 100px 0; }
.constrained-width { max-width: 1100px; margin: 0 auto; width: 100%; padding: 0 20px; }

.heading {
    text-align: center;
    .title {
        font-size: 36px;
        font-weight: bold;
        color: #fff;
    }
}

.grid-3 {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 30px;
}

.card-box {
    background: rgba(255,255,255,0.05);
    padding: 30px;
    border-radius: 16px;
    border: 1px solid rgba(77,236,240,0.2);
    text-align: center;
    h4 {
        color: #4decf0;
        font-size: 18px;
        margin-bottom: 15px;
        font-weight: bold;
    }
    p {
        color: #b4b4b4;
        font-size: 14px;
        line-height: 1.6;
        margin: 0;
        text-align: left;
    }
}

.stats-display {
    display: flex;
    justify-content: space-around;
    flex-wrap: wrap;
    margin-top: 60px;
    padding-top: 40px;
    border-top: 1px solid rgba(255,255,255,0.1);
}

.stat-item {
    text-align: center;
    margin-bottom: 20px;
}

.stat-val {
    color: #fff;
    font-size: 48px;
    font-weight: bold;
    margin: 0 0 10px 0;
}

.stat-label {
    color: #4decf0;
    font-size: 16px;
    margin: 0;
}

.stats-note {
    text-align: center;
    color: #b4b4b4;
    font-size: 14px;
    margin-top: 20px;
}

@media (max-width: 768px) {
    .grid-3 {
        grid-template-columns: 1fr;
    }
    .heading .title { font-size: 28px; }
    .stat-val { font-size: 36px; }
}
</style>
