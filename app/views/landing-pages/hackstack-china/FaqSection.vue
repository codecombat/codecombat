<template>
  <div
    class="page-section section spaced-section"
    style="background:#193640;"
  >
    <div class="frame constrained-width">
      <div class="heading">
        常见问题
      </div>
      <div class="body">
        <div class="faq-list">
          <div
            v-for="(item, index) in faqs"
            :key="index"
            :class="['faq-item', item.open ? 'open' : '']"
            @click="toggleFaq(index)"
          >
            <div class="q">
              <span>{{ item.question }}</span>
              <svg
                class="chevron"
                viewBox="0 0 24 24"
              ><path d="M7 10l5 5 5-5z" /></svg>
            </div>
            <div
              class="collapse-content"
              :style="{ display: item.open ? 'block' : 'none' }"
            >
              {{ item.answer }}
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'FaqSection',
  data () {
    return {
      faqs: [
        { question: '扣哒宇宙适合多大的学生？', answer: '答：主体课程适合初中和高中阶段学生，AI入门课程向下兼容至小学三年级。针对更低年龄段（K-5），扣哒世界另有CodeCombat AI Junior可供选择，欢迎联系我们了解详情。', open: false },
        { question: '学校的网络和设备能用吗？', answer: '答：扣哒宇宙是纯网页端产品，只需浏览器即可使用，无需安装任何软件，适配学校现有电脑教室和设备。', open: false },
        { question: '没有计算机专业背景的老师能教吗？', answer: '答：完全可以。每节课都配备从课前到课后的标准化授课资源包，教师按流程操作即可完成高质量授课。同时我们还提供从零基础入门到赛事指导的全维度师资培训。', open: false },
        { question: '学生使用AI安全吗？', answer: '答：扣哒宇宙从技术过滤（提示词脱敏、不当内容拦截）、权限管控（教师锁定AI工具范围）、全程审计（所有交互记录可查）三个维度保障安全，禁止AI供应商使用聊天记录训练模型，完全符合教育部对中小学生成式AI使用的安全管理要求。', open: false },
        { question: '平台使用哪些AI大模型？', answer: '答：目前集成DeepSeek（深度求索）、通义千问、千问图片等模型，AI沙盒课程还支持豆包、元宝、Kimi等国内主流大模型。所有模型均经过严格安全审查，并持续更新。', open: false },
        { question: '老师和学生有多少提示词额度？', answer: '答：获取许可后，教师每月100条提示词，学生每周30条。个人高级版用户每月50条。', open: false },
        { question: '如何对接竞赛？', answer: '答：扣哒宇宙课程与AI世青赛、教育部白名单赛事、Code Quest等赛事体系天然打通。引入课程的学校可直接组织学生参赛，平台提供赛事宣讲物料和备赛方案。', open: false },
      ],
    }
  },
  methods: {
    toggleFaq (index) {
      this.faqs[index].open = !this.faqs[index].open
      // Optional: close other faqs
      this.faqs.forEach((item, i) => {
        if (i !== index) item.open = false
      })
    },
  },
}
</script>

<style scoped lang="scss">
.spaced-section { padding: 100px 0; }
.constrained-width { max-width: 1100px; margin: 0 auto; width: 100%; padding: 0 20px; }

.heading {
    color: #fff;
    font-size: 36px;
    font-weight: bold;
    text-align: center;
    margin-bottom: 50px;
}

.faq-item {
    background: rgba(255,255,255,0.05);
    padding: 20px 30px;
    border-radius: 12px;
    margin-bottom: 15px;
    border: 1px solid rgba(255,255,255,0.1);
    cursor: pointer;
    .q {
        color: #4decf0;
        font-size: 20px;
        font-weight: bold;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }
}

.chevron {
    fill: #4decf0;
    width: 20px;
    transition: transform 0.3s ease;
}

.faq-item.open .chevron {
    transform: rotate(180deg);
}

.collapse-content {
    padding-top: 15px;
    border-top: 1px solid rgba(255,255,255,0.1);
    margin-top: 15px;
    color: #ffffff;
    line-height: 1.8;
    font-size: 16px;
}
</style>
