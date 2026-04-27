<template>
  <div
    class="page-section section spaced-section"
    style="background:#193640;"
  >
    <div class="frame constrained-width">
      <div class="heading">
        <span class="title">
          <span class="text-white">学了就能比——</span><span class="text-teal">无缝对接高含金量赛事</span>
        </span>
        <p class="description">
          AI HackStack课程与扣哒世界竞赛体系天然打通，形成"课堂学习—赛事实战—成果认可"的完整闭环
        </p>
      </div>

      <div class="body grid-3">
        <div
          v-for="(comp, index) in competitions"
          :key="index"
          class="card-box"
        >
          <h3>{{ comp.title }}</h3>
          <p class="extra-info">
            {{ comp.desc }}
          </p>
          <p
            v-if="comp.extra"
            class="extra-info"
          >
            {{ comp.extra }}
          </p>
        </div>
      </div>

      <div class="winner-display">
        <h3 class="sub-heading">
          获奖学生展示
        </h3>

        <div class="v-marquee-container">
          <div class="v-marquee-wrapper">
            <div class="v-marquee-list">
              <div
                v-for="(winner, index) in winners"
                :key="'w1-' + index"
                class="v-item"
              >
                {{ winner.name }} · {{ winner.school }} · <span>{{ winner.award }}</span>
              </div>
            </div>
            <div class="v-marquee-list">
              <div
                v-for="(winner, index) in winners"
                :key="'w2-' + index"
                class="v-item"
              >
                {{ winner.name }} · {{ winner.school }} · <span>{{ winner.award }}</span>
              </div>
            </div>
          </div>
        </div>

        <h3 class="sub-heading logo-wall-heading">
          参赛学校Logo墙
        </h3>

        <div
          v-for="(row, rIndex) in logoRows"
          :key="'row-' + rIndex"
          :class="['h-marquee-container', 'row-' + (rIndex + 1)]"
        >
          <div class="h-marquee-wrapper">
            <div class="h-marquee-list">
              <div
                v-for="(logo, lIndex) in row"
                :key="'l1-' + lIndex"
                class="h-item"
              >
                {{ logo }}
              </div>
            </div>
            <div class="h-marquee-list">
              <div
                v-for="(logo, lIndex) in row"
                :key="'l2-' + lIndex"
                class="h-item"
              >
                {{ logo }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'CompetitionSection',
  data () {
    return {
      competitions: [
        {
          title: 'AI世青赛（第八届火热报名中）',
          desc: '由扣哒人工智能学院、CodeCombat和网易伏羲联合主办。2026年春季赛报名时间：3月15日至5月15日。',
          extra: '流程：省市赛 → 全国决赛 → 金牌附加赛 | 奖项：一/二/三等奖，均可获扣哒之星奖学金',
        },
        {
          title: '教育部白名单赛事',
          desc: '扣哒世界是"少年硅谷——全国青少年人工智能教育成果展示大赛"AI算法竞技赛的独家技术合作平台。白名单赛事是教育部官方认可的全国性竞赛活动，在综合评价招生中普遍获得认可。',
        },
        {
          title: 'Code Quest 全球算法竞技',
          desc: '全球范围内代码算法竞技的经典赛事，采用组队编程模式，培养团队协作与算法思维。',
        },
      ],
      winners: [
        { name: '刘同学', school: '成都七中（林荫校区）', award: 'AI世青赛全国一等奖（中学组）' },
        { name: '于同学', school: '北京市海淀区中关村第一小学', award: 'AI世青赛全国一等奖金牌 + 教育部白名单赛事金牌' },
        { name: '胡同学', school: '苏州市振华中学', award: 'AI世青赛全国一等奖金牌' },
        { name: '王同学', school: '北京市第十二中学', award: 'AI世青赛全国一等奖（中学组）' },
        { name: '赵同学', school: '', award: 'Code Quest全球总决赛金牌（中学组）' },
        { name: '吴同学', school: '', award: 'Code Quest全球总决赛金牌（小学组）' },
        { name: '李同学', school: '江苏省苏州中学相城实验项目', award: 'AI世青赛全国一等奖金牌' },
        { name: '丁同学', school: '上海市闵行区实验小学', award: '教育部白名单赛事全国一等奖金牌' },
      ],
      logoRows: [
        ['华中师大一附中', '成都七中', '北京市第十二中学', '苏州市振华中学', '广州市执信中学'],
        ['北京市新英才学校', '杭州中学', '上海市建平中学', '北京市中关村第一小学', '上海市闵行区实验小学'],
        ['南京市江宁中心小学', '温州市南浦实验中学', '昆明市第一中学附属山海实验学校', '杭州市崇文实验学校', '上海七宝明强小学'],
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
    }
    .description {
        color: #b4b4b4;
        font-size: 18px;
        margin-top: 20px;
    }
}

.text-white { color: #fff; }
.text-teal { color: #4decf0; }

.grid-3 {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 30px;
    margin-top: 50px;
}

.card-box {
    background: rgba(255,255,255,0.05);
    padding: 40px 30px;
    border-radius: 16px;
    border: 1px solid rgba(77,236,240,0.2);
    text-align: left;
    h3 {
        color: #4decf0;
        margin-top: 0;
        font-size: 22px;
        margin-bottom: 15px;
        font-weight: bold;
    }
    p {
        color: #fff;
        font-size: 15px;
        line-height: 1.8;
    }
    .extra-info {
        color: #b4b4b4;
        font-size: 14px;
        margin-top: 10px;
    }
}

.winner-display {
    margin-top: 60px;
}

.sub-heading {
    text-align: center;
    margin-bottom: 20px;
    font-size: 24px;
    color: #4decf0;
    font-weight: bold;
}

.logo-wall-heading {
    margin-top: 50px;
}

/* 获奖学生：无缝垂直滚动 */
.v-marquee-container {
    height: 260px;
    overflow: hidden;
    background: rgba(255,255,255,0.03);
    border: 1px solid rgba(77, 236, 240, 0.2);
    border-radius: 12px;
    position: relative;
    margin-top: 30px;
    &::before { content: ''; position: absolute; top: 0; left: 0; right: 0; height: 40px; background: linear-gradient(to bottom, rgba(2,30,39,1), transparent); z-index: 2; }
    &::after { content: ''; position: absolute; bottom: 0; left: 0; right: 0; height: 40px; background: linear-gradient(to top, rgba(2,30,39,1), transparent); z-index: 2; }
}

.v-marquee-wrapper {
    display: flex;
    flex-direction: column;
    animation: scrollY 15s linear infinite;
    &:hover { animation-play-state: paused; }
}

@keyframes scrollY { 0% { transform: translateY(0); } 100% { transform: translateY(-50%); } }

.v-marquee-list { display: flex; flex-direction: column; }

.v-item {
    padding: 12px 20px;
    text-align: center;
    color: #fff;
    font-size: 16px;
    border-bottom: 1px solid rgba(255,255,255,0.05);
    span { color: #4decf0; font-weight: bold; }
}

/* 学校Logo墙：无缝水平弹幕 */
.h-marquee-container {
    overflow: hidden;
    white-space: nowrap;
    margin-bottom: 15px;
    position: relative;
    border-radius: 8px;
    background: rgba(255,255,255,0.02);
    padding: 12px 0;
    border: 1px solid rgba(255,255,255,0.05);
}

.h-marquee-wrapper {
    display: inline-flex;
    width: max-content;
    animation: scrollX 20s linear infinite;
    &:hover { animation-play-state: paused; }
}

.h-marquee-list { display: flex; align-items: center; }

@keyframes scrollX { 0% { transform: translateX(0); } 100% { transform: translateX(-50%); } }

.h-item {
    font-size: 18px;
    font-weight: bold;
    color: #fff;
    padding: 0 40px;
    position: relative;
    &::after { content: '•'; position: absolute; right: -5px; color: #4decf0; opacity: 0.5; }
    &:last-child::after { display: none; }
}

.row-2 .h-marquee-wrapper { animation-duration: 25s; }
.row-3 .h-marquee-wrapper { animation-duration: 30s; }

@media (max-width: 768px) {
    .grid-3 {
        grid-template-columns: 1fr;
    }
    .heading .title { font-size: 28px; }
}
</style>
