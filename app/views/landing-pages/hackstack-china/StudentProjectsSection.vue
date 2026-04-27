<template>
  <div
    class="page-section section spaced-section"
    style="background:#193640;"
  >
    <div class="frame constrained-width">
      <div class="heading">
        <span class="title">看看学生用 AI HackStack 做出了什么</span><br>
        <p class="description">
          不需要专业编程基础，只需要一个好的想法和精准的提示词——以下是学生在平台上完成的真实项目
        </p>
      </div>

      <div class="body">
        <div
          v-for="(project, index) in projects"
          :key="index"
          :class="['two-column-block', 'project-block', project.reverse ? 'reverse' : '']"
        >
          <div class="column-one">
            <video
              v-if="project.video"
              :src="project.video"
              autoplay
              loop
              muted
              playsinline
              class="project-media"
            >
              您的浏览器不支持视频播放。
            </video>
            <img
              v-else
              :src="project.image"
              :alt="project.title"
              class="project-media"
            >
          </div>
          <div class="column-two">
            <h4 class="project-title">
              {{ project.title }}
            </h4>
            <span class="project-tag">{{ project.tag }}</span>
            <p class="project-desc">
              {{ project.desc }}
            </p>
            <div class="project-meta">
              学科融合：{{ project.meta }}
            </div>
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
  name: 'StudentProjectsSection',
  inject: ['toggleQRModal'],
  data () {
    return {
      projects: [
        {
          video: '/images/pages/hackstack-new/project_poetry.mp4',
          title: 'AI古诗词意境画生成器',
          tag: '语文 + AI绘画',
          desc: '学生输入一首古诗词，通过精心设计的提示词引导AI理解诗中意象，生成与诗境匹配的画作。学生需要反复调整提示词来修正AI的"误读"——比如让AI理解"瘦马"不是"胖马"，"大漠孤烟直"不是"沙漠着火了"。这个过程不仅练习了提示词工程，更深化了对古诗词的理解。',
          meta: '语文素养 + 审美鉴赏 + AI提示词工程 + 批判性思维',
          reverse: true,
        },
        {
          image: '/images/pages/hackstack-new/project_math.png',
          title: '个性化数学辅导平台',
          tag: '数学 + AI应用开发',
          desc: '学生设计了一个AI数学学习工具，覆盖代数、几何、统计等模块。用户答题后，AI自动判定对错并给出逐步解析，还能根据答题情况追踪薄弱环节。一个学生用AI帮助更多学生学习——这就是AI赋能教育的真实场景。',
          meta: '数学知识 + 逻辑设计 + AI交互 + 用户体验',
          reverse: false,
        },
        {
          video: '/images/pages/hackstack-new/project_english.mp4',
          title: 'AI英语互动故事绘本',
          tag: '英语 + 创意写作 + AI绘画',
          desc: '学生用英文编写故事大纲和角色设定，通过提示词指导AI生成完整的英语故事文本和配套插画。从主题构思、角色设计到情节发展，全部由学生主导。最终成果是一本图文并茂的英语互动绘本，既练习了英语写作，又培养了视觉叙事能力。',
          meta: '英语写作 + 叙事结构 + AI绘画 + 跨媒体表达',
          reverse: true,
        },
        {
          image: '/images/pages/hackstack-new/project_weather.png',
          title: '校园气象站数据分析报告',
          tag: '科学 + 数据分析',
          desc: '学生收集学校所在城市一整年的气象数据，利用AI进行数据清洗、可视化分析和趋势预测。最终产出一份包含温度变化曲线、降水分布图和气候趋势分析的完整报告，并用AI辅助撰写研究结论。一个真实的跨学科STEM项目，从数据采集到研究报告一气呵成。',
          meta: '地理/科学 + 数据分析 + 统计学 + AI辅助写作',
          reverse: false,
        },
        {
          image: '/images/pages/hackstack-new/project_game.png',
          title: '3D 射击游戏',
          tag: '3D游戏开发 + AI辅助设计 + Unity引擎',
          desc: '学生在AI HackStack中学习提示词工程和AI辅助编程的核心技能后，将其应用到Unity 3D游戏开发中。这款第一人称射击游戏的开发流程充分体现了AI协作的力量：游戏关卡设计用AI生成初稿，角色建模用AI辅助创建3D素材，敌人的行为逻辑用自然语言描述后由AI转化为C#脚本，甚至音效和UI界面也是AI辅助完成的。学生从"氛围编程"走向真实的工业级游戏引擎，完成了从AI学习者到AI开发者的跨越。',
          meta: '3D空间设计 + 物理引擎 + AI辅助编程 + 项目工程管理',
          reverse: true,
        },
        {
          image: '/images/pages/hackstack-new/project_scifi.png',
          title: 'AI创意写作——科幻冒险小说',
          tag: '创意写作 + AI叙事',
          desc: '学生创作了一部关于两位少年穿越到AI虚拟世界的互动小说。通过精心设计的提示词，AI帮助构建了丰富的角色对话、情节反转和场景描写。学生在创作过程中既锻炼了故事架构能力，也体验了人机协作创作的完整流程。AI不只是技术工具，更是激发创意的写作搭档。',
          meta: '文学创作 + 叙事设计 + 想象力 + AI协作',
          reverse: false,
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
    margin-bottom: 60px;
    .title {
        font-size: 36px;
        color: #fff;
        font-weight: bold;
    }
    .description {
        color: #b4b4b4;
        font-size: 16px;
        margin-top: 15px;
    }
}

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
    flex: 1.6;
}

.column-two {
    flex: 1;
}

.project-media {
    width: 100%;
    height: auto;
    aspect-ratio: 16 / 9;
    object-fit: cover;
    display: block;
    border-radius: 12px;
}

.project-title {
    color: #4decf0;
    font-size: 26px;
    font-weight: bold;
    margin-bottom: 20px;
}

.project-tag {
    display: inline-block;
    background: #2a4a5a;
    color: #b0e0e6;
    padding: 4px 12px;
    border-radius: 20px;
    font-size: 14px;
    margin-bottom: 15px;
}

.project-desc {
    color: #fff;
    line-height: 1.8;
    font-size: 16px;
    margin-bottom: 20px;
}

.project-meta {
    color: #8ecae6;
    font-size: 14px;
    border-left: 3px solid #4decf0;
    padding-left: 15px;
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
