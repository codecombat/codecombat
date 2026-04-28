<template>
  <div class="page-section section hero-section">
    <div class="frame">
      <div class="heading">
        <span>
          <span class="text-white">让每一个学生</span>
          <span class="text-teal">拥有AI时代的创造力</span>
        </span>
      </div>
      <div class="body">
        <div class="video-box box">
          <video
            src="https://assets.koudashijie.com/videos/hackstack-iframe.mp4"
            autoplay
            loop
            muted
            playsinline
            class="video"
          />
        </div>
      </div>
      <div class="tail">
        <p class="content">
          扣哒宇宙是面向中小学的生成式人工智能教学平台。学生在安全沙盒中动手体验DeepSeek、通义千问等国内主流大模型，通过"学习—二创—创造"三阶闯关，完成从AI认知到AI创造的进阶。
        </p>
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

        <div class="hero-stats constrained-width">
          <div class="hero-stat-card">
            <h3><span class="text-teal">10</span>大课程系列</h3>
            <p>从AI入门到智能体设计</p>
          </div>
          <div class="hero-stat-card">
            <h3><span class="text-teal">324</span>个闯关关卡</h3>
            <p>学习·二创·创造三阶递进</p>
          </div>
          <div class="hero-stat-card">
            <h3><span class="text-teal">182</span>节标准课时</h3>
            <p>每节课配备完整教案</p>
          </div>
          <div class="hero-stat-card">
            <h3>小学<span class="text-teal">3</span>年级到高中</h3>
            <p>全覆盖适配所有学段</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'HeroSection',
  inject: ['toggleQRModal'],
}
</script>

<style scoped lang="scss">
.hero-section {
    background:
        linear-gradient(to bottom, rgba(2, 30, 39, 0) 0vw, rgba(2, 30, 39, 0) 20vw, #021e27 45vw),
        url('/images/pages/hackstack-new/cubes-up.png') center top / 100% auto no-repeat,
        #021e27 !important;
    padding: 100px 20px 80px;
    text-align: center;
}

.heading {
    margin-bottom: 40px;
    span {
        font-size: 48px;
        font-weight: bold;
    }
}

.text-white { color: #fff; }
.text-teal { color: #4decf0; margin-left: 10px; }

.video-box {
    max-width: 900px;
    margin: 0 auto 50px auto;
    border-radius: 12px;
    overflow: hidden;
    box-shadow: 0 20px 50px rgba(0,0,0,0.6);
}

.video {
    position: relative;
    aspect-ratio: 16 / 9;
  width: 100%;
}

.hero-video {
    border: none;
    width: 100%;
    height: 100%;
    display: block;
    object-fit: cover;
}

.content {
    max-width: 900px;
    margin: 0 auto 40px auto;
    font-size: 18px;
    color: #e5e7eb;
    line-height: 1.8;
}

.btns-group {
    display: flex;
    gap: 20px;
    justify-content: center;
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

.hero-stats {
    display: flex;
    gap: 20px;
    justify-content: center;
    margin-top: 40px;
    flex-wrap: wrap;
    max-width: 1100px;
    margin-left: auto;
    margin-right: auto;
}

.hero-stat-card {
    background: rgba(255,255,255,0.05);
    border: 1px solid rgba(77,236,240,0.3);
    border-radius: 12px;
    padding: 20px;
    text-align: center;
    flex: 1;
    min-width: 200px;
    h3 {
        color: #fff;
        font-size: 18px;
        margin: 0 0 10px 0;
        font-weight: normal;
        span {
            font-size: 32px;
            font-weight: bold;
        }
    }
    p {
        color: #b4b4b4;
        font-size: 14px;
        margin: 0;
        line-height: 1.5;
    }
}

@media (max-width: 768px) {
    .heading span {
        font-size: 36px;
    }
}
</style>
