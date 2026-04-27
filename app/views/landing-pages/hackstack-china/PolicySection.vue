<template>
  <div
    class="page-section section spaced-section"
    style="background: #021e27;"
  >
    <div class="frame constrained-width">
      <div class="heading">
        <span class="title">
          <span class="text-white">政策明确要求——</span>
          <span class="text-teal">人工智能课，现在就要开</span>
        </span>
      </div>
      <div class="body">
        <p class="description">
          2026年4月10日，教育部、国家发展改革委、工业和信息化部、科技部、国家数据局五部门联合发布《“人工智能+教育"行动计划》，明确要求基础教育阶段"开齐开足开好人工智能课程”，并推动人工智能教育全面纳入地方课程体系。
          此前，教育部已于2025年5月发布《中小学人工智能通识教育指南（2025年版）》，为课程设计给出了明确框架。AI HackStack的课程体系与以上政策框架高度对标，帮助学校一步到位完成政策落地。
        </p>
        <div class="policy-cards">
          <div class="policy-card">
            <h4>每学年≥8课时</h4>
            <p>北京市率先要求中小学AI通识教育每学年不少于8课时，2025年秋季学期起全面实施，多省市正在跟进</p>
          </div>
          <div class="policy-card">
            <h4>推动纳入课程标准</h4>
            <p>教育部明确提出，2026年推动人工智能进入中小学课程标准、日常教学和考试评价</p>
          </div>
          <div class="policy-card">
            <h4>五部门联合推动</h4>
            <p>教育部等五部门联合发布《"人工智能+教育"行动计划》，全面部署基础教育阶段AI课程</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'PolicySection',
}
</script>

<style scoped lang="scss">
.spaced-section { padding: 100px 0; }
.constrained-width { max-width: 1100px; margin: 0 auto; width: 100%; padding: 0 20px; }

.heading {
    text-align: center;
    margin-bottom: 30px;
    .title {
        font-size: 36px;
        font-weight: bold;
    }
}

.text-white { color: #fff; }
.text-teal { color: #4decf0; }

.description {
    color: #b4b4b4;
    font-size: 18px;
    text-align: center;
    margin-bottom: 20px;
    line-height: 1.8;
}

.policy-cards {
    display: flex;
    gap: 20px;
    justify-content: center;
    flex-wrap: wrap;
    margin-top: 50px;
}

.policy-card {
    background: rgba(255,255,255,0.05);
    padding: 40px 30px;
    border-radius: 16px;
    border: 1px solid rgba(77, 236, 240, 0.3);
    flex: 1;
    min-width: 280px;
    text-align: center;
    h4 {
        color: #4decf0;
        font-size: 24px;
        margin-bottom: 20px;
        font-weight: bold;
    }
    p {
        color: #fff;
        font-size: 16px;
        line-height: 1.6;
        text-align: left;
    }
}

@media (max-width: 768px) {
    .spaced-section { padding: 60px 20px; }
    .heading .title { font-size: 28px; }
}
</style>
