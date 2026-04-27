<template>
  <div
    class="page-section section spaced-section"
    style="background:#021e27;"
  >
    <div class="frame constrained-width">
      <div class="heading">
        <span class="title">
          <span class="text-white">您最关心的三件事，</span>
          <span class="text-teal">我们都解决了</span>
        </span>
      </div>
      <div class="body">
        <div class="two-column-block">
          <div class="column-one">
            <img
              src="/images/pages/hackstack-new/t.png"
              alt="老师能教"
            >
          </div>
          <div class="column-two">
            <h3 class="feature-title">
              老师能教——无需技术背景也能上好AI课
            </h3>
            <p class="feature-desc">
              扣哒宇宙不是把AI工具丢给老师就不管了，而是一套从备课到授课到课后全程配好的完整教学解决方案。<br><br>
              <span class="highlight">每节课都配备标准化授课资源包：</span>课前有备课指南和教学AI目标拆解，课中有标准化演示流程和操作步骤指引，课后有知识点总结课件和优秀作品展示方案。<br><br>
              <span class="highlight">教师面板提供学情数据追踪：</span>可实时查看全班整体进度，也可深入查看每位学生与AI对话的完整记录和项目提交情况，系统自动定位学习难点，精准辅导有据可依。<br><br>
              <span class="highlight">配套师资培训体系同步就绪：</span>从入门使用到进阶教研到赛事指导，全维度培训支持。
            </p>
          </div>
        </div>

        <div class="two-column-block reverse">
          <div class="column-one">
            <img
              src="/images/pages/hackstack-new/s.png"
              alt="学生爱学"
            >
          </div>
          <div class="column-two">
            <h3 class="feature-title">
              学生爱学——游戏化闯关，不用逼着学
            </h3>
            <p class="feature-desc">
              扣哒宇宙的学生端采用<span class="highlight">星际星球主题</span>的可视化界面——10大主题星球错落排布在宇宙星空中，每个星球对应一个课程系列. 学生通过完成星球内的关卡任务解锁学习进度，集星星、解成就、探索新星球。<br><br>
              每个关卡遵循<span class="highlight">"学习—二创—创造"</span>三阶递进设计：先学会，再改进，最后自己创造。学生在一站式AI沙盒中即可完成文本生成、图像创作、代码编写等全场景实践，所有作品都会沉淀到个人创作库，可分享、可展示。
            </p>
          </div>
        </div>

        <div class="two-column-block">
          <div class="column-one">
            <img
              src="/images/pages/hackstack-new/safe.png"
              alt="安全可控"
            >
          </div>
          <div class="column-two">
            <h3 class="feature-title">
              安全可控——让学生接触AI，您完全放心
            </h3>
            <p class="feature-desc">
              这是您引入AI教育最大的顾虑。扣哒宇宙从三个维度筑牢安全防线：<br><br>
              <span class="highlight">技术层面</span>——平台自动过滤学生提示词中的个人身份信息/敏感问题和信息，实时拦截不当内容，并要求后端大语言模型供应商不得使用学生交互数据进行模型训练。<br><br>
              <span class="highlight">权限层面</span>——教师可自主锁定特定AI模型与工具，自定义学生可访问的范围，教学节奏完全由教师掌控。<br><br>
              <span class="highlight">审计层面</span>——教师在后台可查看每一位学生的每一条提示词和AI生成内容，全程可追溯、可监管。<br><br>
              安全体系符合教育部《中小学生成式人工智能使用指南（2025年版）》的管理要求。
            </p>
          </div>
        </div>

        <div class="btns-group">
          <a
            href="/ai/play"
            class="btn-cta-solid"
          >
            <span class="CTA__button">免费试用</span>
          </a>
          <a
            href="#"
            class="btn-cta-outline"
            @click.prevent="toggleQRModal(true)"
          >
            <span class="CTA__button">预约演示</span>
          </a>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'FeaturesSection',
  inject: ['toggleQRModal'],
}
</script>

<style scoped lang="scss">
.spaced-section { padding: 100px 0; }
.constrained-width { max-width: 1100px; margin: 0 auto; width: 100%; padding: 0 20px; }

.heading {
    text-align: center;
    margin-bottom: 60px;
    .title {
        font-size: 36px;
        font-weight: bold;
    }
}

.text-white { color: #fff; }
.text-teal { color: #4decf0; }

.two-column-block {
    display: flex;
    align-items: center;
    gap: 60px;
    margin-bottom: 80px;
    &.reverse {
        flex-direction: row-reverse;
    }
}

.column-one {
    flex: 1;
    img {
        width: 100%;
        border-radius: 16px;
        box-shadow: 0 20px 40px rgba(0,0,0,0.5);
    }
}

.column-two {
    flex: 1.2;
}

.feature-title {
    color: #4decf0;
    font-size: 26px;
    font-weight: bold;
    margin-bottom: 20px;
}

.feature-desc {
    color: #fff;
    line-height: 1.8;
    font-size: 16px;
}

.highlight {
    color: #4decf0;
    font-weight: bold;
}

.btns-group {
    display: flex;
    gap: 20px;
    justify-content: center;
    margin-top: 50px;
}

.btn-cta-solid {
    background-color: #4decf0 !important;
    border: 2px solid #4decf0 !important;
    border-radius: 6px !important;
    padding: 12px 30px !important;
    transition: all 0.3s ease;
    cursor: pointer;
    text-decoration: none;
    display: inline-block;
    span { color: #021e27 !important; font-weight: bold !important; font-size: 16px !important; }
    &:hover { background-color: #3bcdd0 !important; transform: translateY(-2px); }
}

.btn-cta-outline {
    background-color: transparent !important;
    border: 2px solid #4decf0 !important;
    border-radius: 6px !important;
    padding: 12px 30px !important;
    transition: all 0.3s ease;
    cursor: pointer;
    text-decoration: none;
    display: inline-block;
    span { color: #4decf0 !important; font-weight: bold !important; font-size: 16px !important; }
    &:hover { background-color: rgba(77, 236, 240, 0.1) !important; transform: translateY(-2px); }
}

@media (max-width: 768px) {
    .two-column-block, .two-column-block.reverse {
        flex-direction: column;
        gap: 30px;
    }
    .heading .title { font-size: 28px; }
}
</style>
