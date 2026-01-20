<template>
  <PageSection class="section">
    <template #heading>
      <div>
        游戏通关，人生通关
      </div>
      <div class="description">
        来自真实用户的学习反馈
      </div>
    </template>
    <template #body>
      <div
        ref="feedbackCarousel"
        class="feedback-container anim-up mx-auto"
      >
        <div
          v-for="(feedback, index) in feedbacks"
          :key="index"
          :class="['feedback-slide', { active: currentFeedbackIndex === index }]"
        >
          <div class="feedback-card-new">
            <i class="fa-solid fa-quote-left quote-icon" />
            <div class="feedback-content">
              <p class="feedback-text">
                {{ feedback.text }}
              </p>
              <div class="feedback-author-info">
                <div class="feedback-name">
                  {{ feedback.name }}
                </div>
                <div
                  v-if="feedback.role"
                  class="feedback-role"
                >
                  {{ feedback.role }}
                </div>
              </div>
            </div>
            <div class="feedback-avatar-box">
              <div class="feedback-avatar">
                <img
                  :src="`/images/pages/cn-home/${feedback.avatar}`"
                  :alt="feedback.name"
                >
              </div>
            </div>
          </div>
        </div>
        <div
          class="feedback-btn prev"
          @click="prevFeedback"
        >
          <i class="fa-solid fa-chevron-left" />
        </div>
        <div
          class="feedback-btn next"
          @click="nextFeedback"
        >
          <i class="fa-solid fa-chevron-right" />
        </div>
        <div class="feedback-dots">
          <div
            v-for="(_, index) in feedbacks"
            :key="index"
            :class="['carousel-dot', { active: currentFeedbackIndex === index }]"
            @click="goToFeedback(index)"
          />
        </div>
      </div>
    </template>
  </PageSection>
</template>
<script>
import PageSection from '../../../../components/common/elements/PageSection'
export default {
  name: 'PageSection7',
  components: {
    PageSection,
  },
  data () {
    return {

      currentFeedbackIndex: 0,
      feedbackInterval: null,
      isFeedbackPlaying: false,
      feedbacks: [
        {
          text: '"我觉得那个CodeCombat真的很适合打基础，虽然讲的是Python，但触类旁通，C语言也能学得很快。今天期末考试我满分通过了，编程能力提升了不少！"',
          name: '吉林大学，人工智能专业，大一学生',
          avatar: 'avatar1.webp',
        },
        {
          text: '"我给孩子高考后第一份礼物就是 CodeCombat。比起大学里枯燥的 C 语言教材，这种轻松有趣的编程闯关能让孩子更容易进入专业课的学习。如今，学会编程是进入 AI 时代的必备技能，给孩子一个好的起点才是最重要的投资。"',
          name: '高三毕业生家长',
          role: '帮孩子提前规划大学专业的爸爸',
          avatar: 'avatar2.webp',
        },
        {
          text: '"虽然我从零开始，但一点都不觉得难。每当我通过一关，看到\'宝石掉落\'的成就感，我就觉得自己在走向未来，这种投资比买奶茶值多了！"',
          name: '某本科院校，文科专业，大四在读女生',
          avatar: 'avatar3.webp',
        },
        {
          text: '"作为工作 10 年的土木人，以前看编程书 5 分钟就困。但在 CodeCombat 里，写代码就像打游戏，每写对一行代码都能看到角色释放技能，那种\'心流\'体验让我彻底告别了刷短视频的焦虑。"',
          name: '某铁路局，土木工程专业，职场自学者',
          avatar: 'avatar4.webp',
        },
      ],
    }
  },
  mounted () {
    this.initFeedbackCarousel()
  },
  methods: {
    nextFeedback () {
      this.currentFeedbackIndex = (this.currentFeedbackIndex + 1) % this.feedbacks.length
      this.resetFeedbackInterval()
    },

    prevFeedback () {
      this.currentFeedbackIndex = (this.currentFeedbackIndex - 1 + this.feedbacks.length) % this.feedbacks.length
      this.resetFeedbackInterval()
    },

    goToFeedback (index) {
      this.currentFeedbackIndex = index
      this.resetFeedbackInterval()
    },
    resetFeedbackInterval () {
      this.stopFeedbackAutoPlay()
      this.startFeedbackAutoPlay()
    },
    startFeedbackAutoPlay () {
      if (this.isFeedbackPlaying) return
      this.isFeedbackPlaying = true
      this.feedbackInterval = setInterval(() => this.nextFeedback(), 8000)
    },

    stopFeedbackAutoPlay () {
      this.isFeedbackPlaying = false
      if (this.feedbackInterval) {
        clearInterval(this.feedbackInterval)
        this.feedbackInterval = null
      }
    },

    initFeedbackCarousel () {
      const feedbackContainer = this.$refs.feedbackCarousel
      if (!feedbackContainer) return

      this.feedbackObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            this.startFeedbackAutoPlay()
          } else {
            this.stopFeedbackAutoPlay()
          }
        })
      }, { threshold: 0.5 })

      this.feedbackObserver.observe(feedbackContainer)
    },

  },
}
</script>
<style scoped lang="scss">
/* Feedback/Testimonial Section */
.feedback-container {
  width: 100%;
  max-width: 1000px;
  min-height: 550px;
  background: transparent;
  box-shadow: none;
  position: relative;
  padding-bottom: 80px;
}

@media (min-width: 768px) {
  .feedback-container {
    min-height: 480px;
    padding-bottom: 0;
  }
}

.feedback-slide {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  opacity: 0;
  transition: all 0.6s ease-in-out;
  transform: scale(0.98);
  pointer-events: none;
  display: flex;
  justify-content: center;
  align-items: center;
}

.feedback-slide:not(.active) {
  visibility: hidden;
}

.feedback-slide.active {
  opacity: 1;
  transform: scale(1);
  pointer-events: auto;
  z-index: 10;
  visibility: visible;
}

.feedback-card-new {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 32px;
  padding: 3.2rem 2.4rem;
  width: 100%;
  box-shadow: 0 20px 50px -10px rgba(0,0,0,0.08);
  display: flex;
  flex-direction: column;
  gap: 2.4rem;
  position: relative;
  align-items: center;
}

@media (min-width: 768px) {
  .feedback-card-new {
    flex-direction: row;
    text-align: left;
    padding: 6.4rem 8.0rem;
    gap: 3.2rem;
    align-items: center;
  }
}

.quote-icon {
  font-size: 4.8rem;
  color: #F2BE22;
  opacity: 0.2;
  position: absolute;
  top: 1.6rem;
  left: 1.6rem;
  line-height: 1;
}

@media (min-width: 768px) {
  .quote-icon {
    font-size: 6.4rem;
    top: 2.4rem;
    left: 2.4rem;
  }
}

.feedback-content {
  flex: 1;
  z-index: 2;
}

.feedback-text {
  font-size: 1.76rem;
  line-height: 1.6;
  font-weight: 500;
  color: #334155;
  margin-bottom: 2.4rem;
}

@media (min-width: 768px) {
  .feedback-text {
    font-size: 2.4rem;
    margin-bottom: 3.2rem;
  }
}

.feedback-author-info {
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
}

.feedback-name {
  font-size: 1.6rem;
  font-weight: 900;
  color: #4338ca;
}

.feedback-role {
  font-size: 1.36rem;
  color: #64748b;
  font-weight: 500;
}

@media (min-width: 768px) {
  .feedback-name {
    font-size: 1.76rem;
  }
  .feedback-role {
    font-size: 1.52rem;
  }
}

.feedback-avatar-box {
  position: relative;
  flex-shrink: 0;
}

.feedback-avatar {
  width: 100px;
  height: 100px;
  border-radius: 50%;
  border: 5px solid #F2BE22;
  overflow: hidden;
  box-shadow: 0 10px 25px rgba(242, 190, 34, 0.3);
  background: #f8fafc;
}

@media (min-width: 768px) {
  .feedback-avatar {
    width: 180px;
    height: 180px;
    border-width: 8px;
  }
}

.feedback-avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.feedback-btn {
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  width: 50px;
  height: 50px;
  border-radius: 50%;
  background: rgba(255,255,255,0.9);
  box-shadow: 0 4px 15px rgba(0,0,0,0.1);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  z-index: 20;
  transition: all 0.2s;
  color: #1e293b;
  border: 1px solid #e2e8f0;
}

.feedback-btn:hover {
  background: #F2BE22;
  color: #422B06;
  border-color: #F2BE22;
  transform: translateY(-50%) scale(1.1);
}

.feedback-btn.prev {
  left: -60px;
}

.feedback-btn.next {
  right: -60px;
}

@media (max-width: 768px) {
  .feedback-btn {
    top: auto;
    bottom: 0;
    transform: none;
    width: 44px;
    height: 44px;
    background: white;
  }
  .feedback-btn:hover {
    transform: scale(1.1);
  }
  .feedback-btn.prev {
    left: 30%;
  }
  .feedback-btn.next {
    right: 30%;
  }
}

.feedback-dots {
  position: absolute;
  bottom: 10px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  gap: 8px;
  z-index: 20;
}

@media (max-width: 768px) {
  .feedback-dots {
    bottom: 18px;
  }
}

.carousel-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: #cbd5e1;
  cursor: pointer;
  transition: all 0.3s;
}

.carousel-dot.active {
  width: 30px;
  border-radius: 10px;
  background: #4338ca;
}
</style>