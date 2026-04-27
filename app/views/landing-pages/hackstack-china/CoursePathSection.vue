<template>
  <div
    class="page-section section spaced-section"
    style="background:#193640;"
  >
    <div class="frame constrained-width">
      <div class="heading">
        <span class="title">
          <span class="text-white">从AI入门到AI创造</span>
          <span class="text-teal">——完整的课程进阶路径</span>
        </span>
        <br>
        <p class="description">
          覆盖提示词工程、跨学科创作、机器学习原理、智能体设计、数据科学、网络安全、生涯规划等全领域
        </p>
      </div>
      <div class="body">
        <div class="course-table-wrapper">
          <table class="course-table">
            <thead>
              <tr>
                <th style="width: 15%;">
                  课程系列
                </th>
                <th style="width: 10%;">
                  状态
                </th>
                <th style="width: 8%;">
                  课时数
                </th>
                <th style="width: 8%;">
                  关卡数
                </th>
                <th style="width: 14%;">
                  适配学段
                </th>
                <th style="width: 45%;">
                  课程简介
                </th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="(course, index) in courses"
                :key="index"
              >
                <td class="course-name">
                  {{ course.name }}
                </td>
                <td><span :class="['status-tag', course.statusClass]">{{ course.status }}</span></td>
                <td>{{ course.lessons }}</td>
                <td>{{ course.levels }}</td>
                <td>{{ course.grade }}</td>
                <td>{{ course.desc }}</td>
              </tr>
            </tbody>
          </table>

          <p class="summary">
            课程体系总规模：10大课程系列，合计182节课时、324个关卡，覆盖小学三年级至高中（含中职）全学段，形成从AI认知启蒙到AI工程实践到AI职业应用的完整培养链路。
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'CoursePathSection',
  data () {
    return {
      courses: [
        { name: '1. AI入门课程', status: '开放试用', statusClass: 'open', lessons: '5节', levels: '13关', grade: '小学3-6年级', desc: '从零开始学习基础提示词设计，在游戏场景中建立AI基础认知，培养人机协作入门能力。' },
        { name: '2. 人工智能探索课程', status: '开放试用', statusClass: 'open', lessons: '4节', levels: '12关', grade: '小学高年级至初中', desc: '跨学科创意拓展：AI艺术创作、AI故事创编、AI肖像画设计、AI博客与网站制作。' },
        { name: '3. 人工智能1课程', status: '测试开发中', statusClass: 'testing', lessons: '28节', levels: '58关', grade: '初中至高中', desc: '系统掌握机器学习、计算机视觉、自然语言处理等AI核心原理，完成从数据分析到应用开发到项目提案的全流程实战。' },
        { name: '4. 人工智能2课程', status: '测试开发中', statusClass: 'testing', lessons: '28节', levels: '59关', grade: '高中', desc: '机器学习进阶、AI伦理规范、AI角色智能体设计与多智能体协同、数据科学全流程项目、行业解决方案开发。' },
        { name: '5. AI沙盒课程', status: '开放试用', statusClass: 'open', lessons: '10节', levels: '10关', grade: '全学段分层适配', desc: '自由体验通义千问、DeepSeek、豆包、元宝、Kimi等国内主流大模型，开展个性化多模态AI创作。' },
        { name: '6. 英语语言艺术课程', status: '测试开发中', statusClass: 'testing', lessons: '3节', levels: '9关', grade: '小学高年级至初中', desc: 'AI赋能英语学习：英语诗歌创作与视觉化呈现、故事创编与叙事优化、神秘小说创作。' },
        { name: '7. 数学与统计学课程', status: '测试开发中', statusClass: 'testing', lessons: '33节', levels: '92关', grade: '初中至高中', desc: '多场景数据分析与函数建模、统计分析实战、学业备考专项、商业策略与市场数据分析。' },
        { name: '8. 计算机科学课程', status: '测试开发中', statusClass: 'testing', lessons: '6节', levels: '6关', grade: '初中至高中', desc: '主题网页、天气应用、疫情模拟系统、打字游戏、画图应用、地图应用的开发实战。' },
        { name: '9. 职业准备课程', status: '即将推出', statusClass: 'soon', lessons: '32节', levels: '32关', grade: '高中或中职', desc: '职场全场景实用AI技能、面试准备与职业规划' },
        { name: '10. 职业规划2课程', status: '即将推出', statusClass: 'soon', lessons: '33节', levels: '33关', grade: '高中或中职', desc: '行业垂直场景AI应用、商业方案设计、职业进阶技能培养' },
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
    margin-bottom: 50px;
    .title {
        font-size: 36px;
        font-weight: bold;
    }
    .description {
        color: #b4b4b4;
        font-size: 16px;
        margin-top: 15px;
    }
}

.text-white { color: #fff; }
.text-teal { color: #4decf0; }

.course-table-wrapper {
    overflow-x: auto;
    margin-top: 50px;
    border-radius: 12px;
    border: 1px solid rgba(77, 236, 240, 0.3);
    background: rgba(2, 30, 39, 0.9);
}

.course-table {
    width: 100%;
    border-collapse: collapse;
    text-align: left;
    color: #fff;
    min-width: 1000px;
    th {
        background: rgba(77, 236, 240, 0.1);
        color: #4decf0;
        padding: 20px 15px;
        font-size: 15px;
        font-weight: bold;
        border-bottom: 2px solid #4decf0;
    }
    td {
        padding: 20px 15px;
        border-bottom: 1px solid rgba(255, 255, 255, 0.1);
        font-size: 14px;
        line-height: 1.6;
        vertical-align: middle;
    }
}

.course-name {
    color: #4decf0;
    font-weight: bold;
}

.status-tag {
    padding: 2px 6px;
    border-radius: 4px;
    font-size: 12px;
    border: 1px solid currentColor;
    &.open { color: #4decf0; }
    &.testing { color: #888; }
    &.soon { color: #888; }
}

.summary {
    color: #4decf0;
    font-size: 16px;
    margin: 20px;
    line-height: 1.8;
    text-align: center;
}

@media (max-width: 768px) {
    .heading .title { font-size: 28px; }
}
</style>
