<template>
  <div
    class="page-section section spaced-section"
    style="background: #021e27;"
  >
    <div class="frame constrained-width">
      <div class="heading">
        <span class="title">5分钟开始您的AI课堂</span>
      </div>
      <div class="body">
        <div class="steps-container">
          <div
            v-for="(step, index) in steps"
            :key="index"
            class="step-item"
          >
            <div class="step-num">
              {{ index + 1 }}
            </div>
            <div class="step-text">
              <h4>{{ step.title }}</h4>
              <p>{{ step.desc }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'StepsSection',
  data () {
    return {
      steps: [
        { title: '创建教师账户', desc: '打开浏览器访问扣哒世界官网，注册教师或管理员账户。纯网页端产品，无需安装任何软件，无需IT支持。' },
        { title: '创建班级，添加学生', desc: '一键创建教学班级，批量导入学生信息。学生无需自主注册，教师即可完成全部账号配置。' },
        { title: '申请试用', desc: '申请试用，为班级一键解锁扣哒宇宙课程，选择适合学段的课程系列，即可开始教学。' },
        { title: '打开标准化教案，轻松授课', desc: '每节课都配备完整的备课指南、课堂演示流程和课后总结方案，开箱即用。' },
      ],
    }
  },
}
</script>

<style scoped lang="scss">
.spaced-section { padding: 100px 0; }
.constrained-width { max-width: 1100px; margin: 0 auto; width: 100%; padding: 0 20px; }

.heading {
    margin-bottom: 50px;
    text-align: center;
    .title {
        font-size: 36px;
        color: #fff;
        font-weight: bold;
    }
}

.steps-container {
    display: flex;
    flex-direction: column;
    gap: 20px;
    margin-top: 50px;
}

.step-item {
    display: flex;
    align-items: center;
    background: rgba(255,255,255,0.05);
    padding: 30px;
    border-radius: 12px;
    border: 1px solid rgba(255,255,255,0.1);
}

.step-num {
    font-size: 48px;
    color: #4decf0;
    font-weight: bold;
    margin-right: 30px;
    min-width: 50px;
    text-align: center;
}

.step-text {
    h4 {
        color: #fff;
        margin: 0 0 10px 0;
        font-size: 22px;
        font-weight: bold;
    }
    p {
        color: #b4b4b4;
        margin: 0;
        font-size: 16px;
        line-height: 1.6;
    }
}

@media (max-width: 768px) {
    .step-item {
        flex-direction: column;
        text-align: center;
    }
    .step-num {
        margin-right: 0;
        margin-bottom: 20px;
    }
    .heading .title { font-size: 28px; }
}
</style>
