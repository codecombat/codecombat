<template>
  <PageSection class="section">
    <template #heading>
      <div>
        玩一款游戏，解锁多种编程语言
      </div>
      <div class="description">
        按兴趣选择不同的学习路线，在闯关中逐步掌握 Python、JavaScript、Lua、C++、Java等主流语言
      </div>
    </template>
    <template #body>
      <div class="grid grid-cols-1 md-grid-cols-3 gap-3 max-w-5xl mx-auto w-full items-center">
        <div class="flex flex-col gap-3 md-gap-4 anim-left order-2 md-order-1">
          <div class="skill-card">
            <div class="skill-header">
              <div class="skill-icon bg-yellow-100 text-yellow-500">
                <i class="fa-brands fa-js" />
              </div><span class="skill-title">JavaScript</span>
            </div>
            <p class="skill-desc">
              网页交互与动态效果，前端开发必备。
            </p>
          </div>
          <div class="skill-card">
            <div class="skill-header">
              <div class="skill-icon bg-orange-100 text-orange-500">
                <i class="fa-brands fa-html5" />
              </div><span class="skill-title">HTML+CSS</span>
            </div>
            <p class="skill-desc">
              网页结构搭建与样式设计，入门网页开发第一步。
            </p>
          </div>
          <div class="skill-card">
            <div class="skill-header">
              <div class="skill-icon bg-blue-100 text-blue-500">
                <i class="fa-solid fa-moon" />
              </div><span class="skill-title">Lua</span>
            </div>
            <p class="skill-desc">
              可以开发游戏模组或插件，比如：蛋仔派对、roblox。
            </p>
          </div>
        </div>
        <div class="flex flex-col items-center justify-center anim-zoom order-1 md-order-2">
          <div class="python-orbit">
            <i class="fa-brands fa-python python-orbit-icon" />
            <h3>Python</h3>
            <p>人工智能与数据分析的首选<br>最简单易学，应用最广。</p>
          </div>
        </div>
        <div class="flex flex-col gap-3 md-gap-4 anim-right order-3 md-order-3">
          <div class="skill-card ai-card-bg">
            <div class="skill-header mb-1">
              <div class="skill-icon bg-indigo-100 text-indigo-600">
                <i class="fa-solid fa-robot" />
              </div><span class="skill-title text-indigo-900">AI编程</span>
            </div>
            <p class="skill-desc text-slate-700 font-medium">
              学会指挥AI写代码，一个人顶一个团队
            </p>
          </div>
          <div class="skill-card">
            <div class="skill-header">
              <div class="skill-icon bg-blue-100 text-blue-700">
                <i class="fa-solid fa-c" />
              </div><span class="skill-title">C++</span>
            </div>
            <p class="skill-desc">
              高性能系统开发，游戏开发，底层核心技术。
            </p>
          </div>
          <div class="skill-card">
            <div class="skill-header">
              <div class="skill-icon bg-red-100 text-red-500">
                <i class="fa-brands fa-java" />
              </div><span class="skill-title">Java</span>
            </div>
            <p class="skill-desc">
              企业级应用开发，安卓开发，稳定可靠。
            </p>
          </div>
        </div>
      </div>
      <CTAButton
        class="cta-button"
        href="/play"
        target="_self"
      >
        立即免费体验
      </CTAButton>
    </template>
  </PageSection>
</template>
<script>
import PageSection from '../../../../components/common/elements/PageSection'
import CTAButton from '../../../../components/common/buttons/CTAButton.vue'
export default {
  name: 'PageSection5',
  components: {
    PageSection,
    CTAButton,
  },
}
</script>
<style scoped lang="scss">
/* Skills Section */
.skill-card {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 20px;
  padding: 1.6rem;
  transition: all 0.3s ease;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
  display: flex;
  flex-direction: column;
  justify-content: center;
  height: 100%;
  min-height: 100px;
}

.skill-card:hover {
  transform: translateY(-3px);
  border-color: #F2BE22;
  box-shadow: 0 10px 15px -3px rgba(242, 190, 34, 0.1);
}

.skill-header {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 6px;
}

.skill-title {
  font-size: 1.76rem;
  font-weight: 800;
  color: #1e293b;
}

.skill-desc {
  font-size: 1.28rem;
  color: #64748b;
  line-height: 1.4;
  font-weight: 500;
}

.skill-icon {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.6rem;
  flex-shrink: 0;
}

.python-orbit {
  width: 260px;
  height: 260px;
  background: linear-gradient(135deg, #ffffff 0%, #fffbeb 100%);
  border: 4px solid #F2BE22;
  border-radius: 50%;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  text-align: center;
  box-shadow: 0 0 50px rgba(242, 190, 34, 0.2);
  position: relative;
  z-index: 10;
}

@media (max-width: 768px) {
  .python-orbit {
    width: 200px;
    height: 200px;
    margin: 20px 0;
  }
}

.python-orbit h3 {
  font-size: 3.52rem;
  color: #b45309;
  font-weight: 900;
  margin: 0;
  line-height: 1;
}

.python-orbit p {
  font-size: 1.36rem;
  font-weight: bold;
  color: #d97706;
  margin-top: 8px;
  line-height: 1.3;
  max-width: 85%;
}

.python-orbit-icon {
  font-size: 6.4rem;
  color: #d97706;
  margin-bottom: 8px;
}

.ai-card-bg {
  background: linear-gradient(to right, #f5f3ff, #eef2ff);
  border-left: 4px solid #F2BE22;
}

</style>