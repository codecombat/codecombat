<template>
  <div
    class="page-section section spaced-section"
    style="background:#193640;"
  >
    <div class="frame constrained-width">
      <div class="body">
        <div class="solutions">
          <div class="heading">
            <span class="text-teal title">AI HackStack 是什么</span>
            <p class="description">
              一个为中小学量身打造的生成式人工智能教学平台。学生在游戏化的星球闯关中，亲手体验DeepSeek、通义千问、智谱、MiniMax等热门国产大模型，系统掌握提示词工程——这项被称为"AI时代第一技能"的核心能力。
              教师端提供标准化教案、学情数据面板和全流程安全监管，无需技术背景和AI经验也能轻松开课。
            </p>
          </div>
          <div class="menu-content">
            <div
              v-for="(item, index) in solutionItems"
              :key="index"
              class="list-item"
            >
              <img
                :src="item.icon"
                class="vector"
              >
              <div class="item-title">
                {{ item.title }}
              </div>
              <div class="item-desc">
                {{ item.desc }}
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
  name: 'SolutionsSection',
  data () {
    return {
      solutionItems: [
        { icon: '/images/pages/hackstack/learn_3.svg', title: '提示词工程', desc: 'AI时代最核心的人机交互技能' },
        { icon: '/images/pages/hackstack/learn_2.svg', title: '跨学科课程', desc: '语数英科美，全学科融合' },
        { icon: '/images/pages/hackstack/learn_4.svg', title: 'AI二创项目', desc: '在社区协作中激发创意' },
        { icon: '/images/pages/hackstack/learn_6.svg', title: '学情数据面板', desc: '教师实时掌握每个学生的学习状态' },
        { icon: '/images/pages/hackstack/learn_1.svg', title: '安全AI沙盒', desc: '三重安全防线，校园级合规' },
        { icon: '/images/pages/hackstack/learn_5.svg', title: 'AI伦理反思', desc: '每个模块嵌入伦理讨论' },
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
        color: #4decf0;
        font-size: 36px;
        font-weight: bold;
    }
    .description {
        color: #fff;
        font-size: 18px;
        margin-top: 20px;
        line-height: 1.8;
    }
}

.menu-content {
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    gap: 30px;
    margin-top: 50px;
}

.list-item {
    text-align: center;
    width: 150px;
    .vector {
        height: 60px;
        margin-bottom: 15px;
    }
    .item-title {
        color: #fff;
        font-weight: bold;
    }
    .item-desc {
        font-size: 13px;
        color: #b4b4b4;
        margin-top: 8px;
    }
}

@media (max-width: 768px) {
    .spaced-section { padding: 60px 20px; }
    .heading .title { font-size: 28px; }
    .list-item { width: 120px; }
}
</style>
