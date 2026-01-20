<template>
  <PageSection class="section">
    <template #heading>
      <div>学编程，像打游戏一样有趣</div>
    </template>
    <template #body>
      <div class="container mx-auto px-4 md-px-6 h-full flex flex-col justify-center items-center py-6">
        <div
          ref="storyCarousel"
          class="slant-viewport anim-up"
        >
          <div
            v-for="(slide, index) in storySlides"
            :key="index"
            :class="['slant-slide', { active: currentSlantIndex === index }]"
          >
            <div class="slant-img-layer">
              <img
                :src="`/images/pages/cn-home/${slide.image}`"
                :alt="`Story ${index + 1}`"
              >
            </div>
            <div class="slant-text-layer">
              <div class="slant-content-wrapper">
                <div class="slant-title-box">
                  <span class="slant-title-text">{{ slide.title }}</span>
                </div>
                <p
                  class="slant-desc"
                  v-html="slide.description"
                />
              </div>
            </div>
          </div>

          <div
            class="slant-nav prev"
            @click="prevSlantSlide"
          >
            <i class="fa-solid fa-chevron-left" />
          </div>
          <div
            class="slant-nav next"
            @click="nextSlantSlide"
          >
            <i class="fa-solid fa-chevron-right" />
          </div>

          <div
            class="slant-progress-bar"
            :style="{ width: slantProgressWidth }"
          />
        </div>
      </div>
    </template>
  </PageSection>
</template>
<script>
import PageSection from '../../../../components/common/elements/PageSection'
export default {
  name: 'PageSection3',
  components: {
    PageSection,
  },
  data () {
    return {
      currentSlantIndex: 0,
      storySlides: [
        {
          image: 'story_left_1.webp',
          title: '你的身份',
          description: '你进入的，<span class="highlight">不是一间教室</span>。<br>而是一片等待被拯救的大陆。<br>在 CodeCombat 的世界里，<br>你不是学生，<strong>你是英雄</strong>。',
        },
        {
          image: 'story_left_2.webp',
          title: '冒险启程',
          description: '一开始，你什么都没有。<br>没有装备，没有技能，<br>甚至连最弱的食人魔都打不过。<br>直到你<span class="highlight">写下第一行代码</span>。<br>那一刻，<strong>世界开始回应你</strong>。',
        },
        {
          image: 'story_left_3.webp',
          title: '魔法装备',
          description: '函数，不再是课本里的抽象概念，<br>而是你手中的<strong>第一件魔法装备</strong>。<br>你写下它，它就被装备；<br>你调用它，它就被释放。',
        },
        {
          image: 'story_left_4.webp',
          title: '策略与技能',
          description: '学会一个<strong>函数</strong>，<br>就多一件装备。<br><span class="highlight"><strong>变量</strong></span>，是你的随身背包；<br><span class="highlight"><strong>判断</strong></span>，让你在关键时刻做出选择；<br><span class="highlight"><strong>循环</strong></span>，让你一次次变强。',
        },
        {
          image: 'story_left_5.webp',
          title: '试炼与成长',
          description: '敌人会升级，<br>你也一样。<br>这里不是刷题，<br>而是游戏<strong>闯关</strong>。<br>失败不会惩罚你，<br>只会告诉你：<br>这套技能，还能<strong>更好</strong>。',
        },
        {
          image: 'story_left_6.webp',
          title: '真实进阶',
          description: '当你击败食人魔boss，<br>拯救这片大陆，<br>你才发现——<br>升级的不只是角色，<br>还有你<strong>真正的编程能力</strong>。',
        },
        {
          image: 'story_left_7.webp',
          title: '超越自我',
          description: '这就是 CodeCombat <br>最有趣的地方：<br>你以为你在打游戏，<br>其实你在<strong>学编程</strong>；<br>你以为你在冒险，<br>其实你在成为<br><strong>更强的自己</strong>。',
        },
      ],
    }
  },
  computed: {
    slantProgressWidth () {
      return `${((this.currentSlantIndex + 1) / this.storySlides.length) * 100}%`
    },
  },
  mounted () {
    this.initStoryCarousel()
  },
  methods: {
    // Story Carousel Methods
    initStoryCarousel () {
      const storyContainer = this.$refs.storyCarousel
      if (!storyContainer) return

      this.storyObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            if (!this.isSlantPlaying) this.startSlantAutoPlay()
          } else {
            this.stopSlantAutoPlay()
          }
        })
      }, { threshold: 0.5 })

      this.storyObserver.observe(storyContainer)
    },

    nextSlantSlide () {
      this.currentSlantIndex = (this.currentSlantIndex + 1) % this.storySlides.length
    },

    prevSlantSlide () {
      this.currentSlantIndex = (this.currentSlantIndex - 1 + this.storySlides.length) % this.storySlides.length
    },
    startSlantAutoPlay () {
      if (this.slantInterval) clearInterval(this.slantInterval)
      this.isSlantPlaying = true
      this.slantInterval = setInterval(() => this.nextSlantSlide(), 10000)
    },

    stopSlantAutoPlay () {
      this.isSlantPlaying = false
      if (this.slantInterval) {
        clearInterval(this.slantInterval)
        this.slantInterval = null
      }
    },

  },
}
</script>
<style scoped lang="scss">
/* Story Carousel - Slant Viewport */
.slant-viewport {
  width: 100%;
  max-width: 1100px;
  height: 480px;
  position: relative;
  margin: 0 auto;
  border-radius: 24px;
  overflow: hidden;
  box-shadow: 0 25px 60px -15px rgba(0,0,0,0.3);
  background: #1e293b;
  cursor: default;
}

@media (max-width: 1024px) {
  .slant-viewport {
    height: 600px;
    border-radius: 16px;
  }
}

@media (max-width: 640px) {
  .slant-viewport {
    height: 500px;
  }
}

.slant-slide {
  position: absolute;
  inset: 0;
  display: flex;
  opacity: 0;
  visibility: hidden;
  transition: opacity 0.5s ease-in-out;
  z-index: 1;
}

.slant-slide.active {
  opacity: 1;
  visibility: visible;
  z-index: 10;
}

.slant-img-layer {
  position: absolute;
  top: 0;
  left: 0;
  bottom: 0;
  width: 75%;
  z-index: 1;
  overflow: hidden;
  background: #1e293b;
}

.slant-img-layer img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  object-position: center;
  transition: transform 6s ease-out;
}

.slant-slide.active .slant-img-layer img {
  transform: scale(1.05);
}

.slant-text-layer {
  position: absolute;
  top: 0;
  right: 0;
  bottom: 0;
  width: 35%;
  background: linear-gradient(135deg, #312e81 0%, #1e1b4b 100%);
  clip-path: polygon(80px 0, 100% 0, 100% 100%, 0% 100%);
  z-index: 2;
  display: flex;
  flex-direction: column;
  justify-content: center;
  transition: width 0.4s cubic-bezier(0.25, 0.8, 0.25, 1);
  box-shadow: -10px 0 40px rgba(0,0,0,0.5);
  align-items: flex-start;
  padding-left: 90px;
  padding-right: 40px;
}

.slant-viewport:hover .slant-text-layer {
  width: 42%;
}

@media (max-width: 1024px) {
  .slant-text-layer {
    width: 100%;
    height: 50%;
    top: auto;
    bottom: 0;
    clip-path: none;
    padding: 2.4rem 2.4rem 4.8rem 2.4rem;
    background: linear-gradient(0deg, rgba(30,27,75,1) 0%, rgba(49,46,129,0.95) 100%);
  }
  .slant-viewport:hover .slant-text-layer {
    width: 100%;
  }
  .slant-img-layer {
    width: 100%;
    height: 50%;
    bottom: auto;
    top: 0;
  }
}

.slant-content-wrapper {
  width: 320px;
  flex-shrink: 0;
}

@media (max-width: 640px) {
  .slant-content-wrapper {
    width: 100%;
  }
}

.slant-title-box {
  background: #4338ca;
  padding: 0.8rem 2.4rem;
  margin-bottom: 2.4rem;
  display: inline-block;
  position: relative;
  transform: skewX(-12deg) translateX(-10px);
  border-left: 5px solid #F2BE22;
  box-shadow: 4px 4px 0px rgba(0,0,0,0.3);
  width: fit-content;
}

.slant-title-text {
  font-size: 2.0rem;
  font-weight: 900;
  color: #fff;
  transform: skewX(12deg);
  letter-spacing: 1px;
  text-transform: uppercase;
}

.slant-desc {
  font-size: 2.0rem;
  line-height: 1.6;
  color: #e2e8f0;
  font-weight: 400;
  text-shadow: 0 2px 4px rgba(0,0,0,0.3);
  transform: translateX(20px);
  opacity: 0;
  transition: all 0.6s ease 0.2s;
}

@media (max-width: 640px) {
  .slant-desc {
    font-size: 1.6rem;
  }
}

.slant-slide.active .slant-desc {
  transform: translateX(0);
  opacity: 1;
}

.slant-desc strong {
  color: #F2BE22;
  font-weight: 900;
  font-size: 2.24rem;
  text-shadow: 0 0 10px rgba(242, 190, 34, 0.4);
}

@media (max-width: 640px) {
  .slant-desc strong {
    font-size: 1.76rem;
  }
}

.slant-desc .highlight {
  color: #818cf8;
  font-weight: bold;
  border-bottom: 2px solid rgba(129, 140, 248, 0.3);
}

.slant-nav {
  position: absolute;
  top: 0;
  bottom: 0;
  width: 70px;
  z-index: 20;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.3s;
  color: rgba(255,255,255,0.4);
  font-size: 4.0rem;
}

.slant-nav:hover {
  background: linear-gradient(90deg, rgba(0,0,0,0.3), transparent);
  color: #F2BE22;
}

@media (max-width: 1024px) {
  .slant-nav {
    width: 50px;
    background: none !important;
    bottom: auto;
    top: 50%;
    transform: translateY(-50%);
    height: 60px;
    color: rgba(255,255,255,0.8);
  }
}

.slant-nav.prev {
  left: 0;
}

.slant-nav.next {
  right: 0;
  justify-content: flex-end;
  padding-right: 15px;
}

.slant-nav.next:hover {
  background: linear-gradient(-90deg, rgba(0,0,0,0.3), transparent);
}

.slant-progress-bar {
  position: absolute;
  bottom: 0;
  left: 0;
  height: 4px;
  background: #F2BE22;
  z-index: 30;
  transition: width 0.3s ease;
  box-shadow: 0 0 10px #F2BE22;
}
</style>