<template>
  <div
    class="page-section section spaced-section"
    style="background: #021e27;"
  >
    <div class="frame constrained-width">
      <div class="heading">
        <span class="title">
          <span class="text-white">学习模式图解：</span>
          <span class="text-teal">三阶闯关，步步进阶</span>
        </span>
      </div>

      <div class="body grid-3">
        <div
          v-for="(mode, index) in modes"
          :key="index"
          class="card-box"
        >
          <img
            :src="mode.image"
            :alt="mode.title"
          >
          <h3>{{ mode.title }}</h3>
          <p>{{ mode.desc }}</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'LearningModeSection',
  data () {
    return {
      modes: [
        {
          image: '/images/pages/hackstack/AI-HackStack-Learn-Image.webp',
          title: '第一阶 · 学习',
          desc: '从语文到数学到科学，学生在各学科场景中掌握核心提示词工程技能，亲身体验DeepSeek、通义千问等热门AI模型。标准化案例引导，确保每个学生都能学得会。',
        },
        {
          image: '/images/pages/hackstack/hackstack-remix.webp',
          title: '第二阶 · 二创',
          desc: '基于社区库中的优秀项目进行修改、优化和再创作。降低创作门槛，巩固核心知识点，在协作中让想法快速演进。课堂的集体产出远超个体之和。',
        },
        {
          image: '/images/pages/hackstack/AI-HackStack-Create-Image.webp',
          title: '第三阶 · 创造',
          desc: '完全开放创作权限，学生自主设定主题、编写提示词、完成原创作品。同步融入AI负责任使用与伦理影响的讨论，创意落地与价值反思并重。',
        },
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
    text-align: center;
    img {
        width: 100%;
        height: 180px;
        object-fit: cover;
        border-radius: 8px;
        margin-bottom: 20px;
    }
    h3 {
        color: #4decf0;
        margin-top: 0;
        font-size: 22px;
        margin-bottom: 15px;
        font-weight: bold;
        text-align: left;
    }
    p {
        color: #b4b4b4;
        font-size: 15px;
        line-height: 1.8;
        text-align: left;
    }
}

@media (max-width: 768px) {
    .grid-3 {
        grid-template-columns: 1fr;
    }
    .heading .title { font-size: 28px; }
}
</style>
