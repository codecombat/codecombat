<template>
  <div
    class="page-section section spaced-section"
    style="background: #021e27;"
  >
    <div class="frame constrained-width">
      <div class="heading">
        <span class="title">
          <span class="text-white">内置国内主流大模型，</span><span class="text-teal">一站式安全体验</span>
        </span>
      </div>
      <div class="body model-grid">
        <div
          v-for="(model, index) in models"
          :key="index"
          class="model-card"
        >
          <img
            :src="model.logo"
            :alt="model.name"
          >
          <h4>{{ model.name }}</h4>
          <p>{{ model.desc }}</p>
        </div>
      </div>
      <p class="foot-note">
        所有模型在接入前均经过严格安全审查。平台团队持续评估模型性能与安全性，确保更新至最新版本。教师可自主锁定特定模型，控制学生可访问范围。
      </p>
    </div>
  </div>
</template>

<script>
export default {
  name: 'AiModelsSection',
  data () {
    return {
      models: [
        { logo: '/images/pages/hackstack-new/logo_deepseek.png', name: 'DeepSeek 深度求索', desc: '自然语言理解与生成，擅长文本创作、逻辑推理和代码生成' },
        { logo: '/images/pages/hackstack-new/logo_tongyi.png', name: '通义千问', desc: '阿里巴巴语言模型，专注交互性能与安全性' },
        { logo: '/images/pages/hackstack-new/logo_doubao.png', name: '豆包', desc: '字节跳动大模型' },
        { logo: '/images/pages/hackstack-new/logo_zhipu.png', name: '智谱', desc: '' },
        { logo: '/images/pages/hackstack-new/logo_minimax.png', name: 'MiniMax', desc: '' },
        { logo: '/images/pages/hackstack-new/logo_kimi.png', name: 'Kimi', desc: '月之暗面大模型' },
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

.model-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 20px;
    margin-top: 40px;
}

.model-card {
    background: rgba(255,255,255,0.05);
    border: 1px solid rgba(255,255,255,0.1);
    padding: 30px 20px;
    border-radius: 12px;
    text-align: center;
    img {
        height: 50px;
        margin-bottom: 15px;
        object-fit: contain;
        border-radius: 8px;
    }
    h4 {
        color: #fff;
        font-weight: bold;
        margin: 0 0 15px 0;
        font-size: 18px;
    }
    p {
        color: #b4b4b4;
        font-size: 13px;
        margin: 0;
        line-height: 1.5;
    }
}

.foot-note {
    color: #b4b4b4;
    text-align: center;
    margin-top: 40px;
    font-size: 16px;
    max-width: 900px;
    margin-left: auto;
    margin-right: auto;
    line-height: 1.8;
}

@media (max-width: 768px) {
    .model-grid {
        grid-template-columns: 1fr;
    }
    .heading .title { font-size: 28px; }
}
</style>
