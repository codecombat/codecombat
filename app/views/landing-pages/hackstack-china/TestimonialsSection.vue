<template>
  <div
    class="page-section section spaced-section"
    style="background:#193640; border-top: 1px solid rgba(255,255,255,0.05);"
  >
    <div class="heading constrained-width">
      <span class="title">来自一线教育者的声音</span>
    </div>

    <div class="container constrained-width">
      <div class="testimonial-slider">
        <div
          v-for="(slide, index) in slides"
          :key="index"
          :class="['testimonial-slide', currentSlide === index ? 'active' : '']"
        >
          <p class="quote">
            “{{ slide.quote }}”
          </p>
          <div class="testimonial-author">
            <img
              :src="slide.avatar"
              :alt="slide.name"
              class="avatar"
            >
            <div>
              <span class="author-name">{{ slide.name }}</span>
              <span class="separator">/</span>
              <span class="author-title">{{ slide.school }}</span>
            </div>
          </div>
        </div>

        <div class="slider-dots">
          <span
            v-for="(slide, index) in slides"
            :key="'dot-' + index"
            :class="['dot', currentSlide === index ? 'active' : '']"
            @click="switchSlide(index)"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'TestimonialsSection',
  data () {
    return {
      currentSlide: 0,
      slides: [
        {
          quote: '扣哒世界寓教于乐，教学设计循序渐进，并且有AI世青赛全球官方竞赛，我和同学们都非常喜欢，我推荐老师们用这个平台开展编程兴趣班入门和进阶教学。',
          name: '魏老师',
          school: '华中师大一附中',
          avatar: '/images/pages/hackstack-new/avatar_wei.png',
        },
        {
          quote: '我不是计算机专业出身，之前一直担心自己教不了AI课。没想到AI HackStack的教案和操作指引做得这么细致，我跟着流程走就能完整上完一堂课，学生的反应比我预期好太多了。',
          name: '张老师',
          school: '成都某重点中学',
          avatar: '/images/pages/hackstack-new/avatar_zhang.png',
        },
        {
          quote: '我们班用AI HackStack上了一学期AI通识课后，有三个学生在AI世青赛中拿了全国一等奖。最让我意外的是，这三个孩子之前并不是成绩最好的，但他们在平台上的创造力完全被激发出来了。',
          name: '陈老师',
          school: '上海某实验小学',
          avatar: '/images/pages/hackstack-new/avatar_chen.png',
        },
      ],
      slideInterval: null,
    }
  },
  mounted () {
    this.startAutoSlide()
  },
  beforeDestroy () {
    this.stopAutoSlide()
  },
  methods: {
    switchSlide (index) {
      this.currentSlide = index
      this.resetInterval()
    },
    startAutoSlide () {
      this.slideInterval = setInterval(() => {
        this.currentSlide = (this.currentSlide + 1) % this.slides.length
      }, 5000)
    },
    stopAutoSlide () {
      clearInterval(this.slideInterval)
    },
    resetInterval () {
      this.stopAutoSlide()
      this.startAutoSlide()
    },
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
}

.testimonial-slider {
    position: relative;
    max-width: 900px;
    margin: 0 auto;
    overflow: hidden;
}

.testimonial-slide {
    display: none;
    background: #effafb;
    border: none;
    padding: 50px 60px;
    border-radius: 16px;
    text-align: left;
    color: #111;
    &.active {
        display: block;
        animation: fadeIn 0.5s ease-in-out;
    }
}

.quote {
    font-size: 20px;
    line-height: 1.8;
    margin-bottom: 30px;
    font-weight: 500;
}

.testimonial-author {
    display: flex;
    align-items: center;
    margin-top: 30px;
    padding-top: 25px;
    border-top: 1px solid rgba(0, 0, 0, 0.1);
}

.avatar {
    width: 60px;
    height: 60px;
    border-radius: 50%;
    margin-right: 20px;
    object-fit: cover;
}

.author-name {
    color: #111;
    font-weight: bold;
    font-size: 18px;
}

.separator {
    color: #555;
    margin: 0 10px;
}

.author-title {
    color: #333;
    font-size: 16px;
}

.slider-dots {
    text-align: center;
    margin-top: 30px;
}

.dot {
    display: inline-block;
    width: 12px;
    height: 12px;
    margin: 0 8px;
    background: #6b7280;
    border-radius: 50%;
    cursor: pointer;
    transition: all 0.3s ease;
    &.active {
        background: #4decf0;
        transform: scale(1.3);
    }
}

@keyframes fadeIn {
    from { opacity: 0; transform: translateY(10px); }
    to { opacity: 1; transform: translateY(0); }
}

@media (max-width: 768px) {
    .testimonial-slide { padding: 30px; }
    .heading .title { font-size: 28px; }
    .quote { font-size: 16px; }
}
</style>
