<template>
  <PageSection class="section">
    <template #heading>
      <div>
        我们是全球游戏化编程开创者
      </div>
    </template>
    <template #body>
      <div>
        <div class="grid grid-cols-1 md-grid-cols-4 gap-4 w-full max-w-6xl anim-up">
          <div class="bento-box bento-box-gold md-col-span-1">
            <div class="stat-val text-yellow-600">
              13年
            </div>
            <div class="stat-label text-yellow-800">
              专注于这一件事
            </div>
            <p class="text-xs text-yellow-700 mt-2">
              经得起时间考验的方案
            </p>
          </div>

          <div class="bento-box bento-box-indigo md-col-span-2">
            <div class="flex items-center gap-4">
              <i class="fa-solid fa-users text-4xl opacity-80" />
              <div>
                <div class="stat-val">
                  2000万
                </div>
                <div class="stat-label">
                  全球学习者的选择
                </div>
              </div>
            </div>
            <p class="text-sm text-indigo-100 mt-2">
              你采用的，是一种被大规模验证的学习方法
            </p>
          </div>

          <div
            class="bento-box md-col-span-1"
            style="background: #ecfeff; border-color: #06b6d4;"
          >
            <div class="stat-val text-cyan-600">
              2300+关卡
            </div>
            <div class="stat-label text-cyan-800">
              持续迭代更新
            </div>
            <p class="text-xs text-cyan-700 mt-2">
              从50关到2300+关的陪伴
            </p>
          </div>

          <div class="md-col-span-4 small-stat-grid">
            <div class="small-stat-item">
              <i class="fa-solid fa-code text-indigo-500" />
              <div class="font-bold text-slate-800">
                10 亿
              </div>
              <div class="text-xs text-slate-500 mt-1">
                累计编写的代码行数<br>激发无限可能
              </div>
            </div>
            <div class="small-stat-item">
              <i class="fa-solid fa-earth-americas text-blue-500" />
              <div class="font-bold text-slate-800">
                190+
              </div>
              <div class="text-xs text-slate-500 mt-1">
                覆盖国家<br>带来全球化学习体验
              </div>
            </div>
            <div class="small-stat-item">
              <i class="fa-solid fa-school text-orange-500" />
              <div class="font-bold text-slate-800">
                75,000
              </div>
              <div class="text-xs text-slate-500 mt-1">
                合作学校<br>培养未来的编程人才
              </div>
            </div>
            <div class="small-stat-item">
              <i class="fa-solid fa-chalkboard-user text-green-500" />
              <div class="font-bold text-slate-800">
                320,000
              </div>
              <div class="text-xs text-slate-500 mt-1">
                全球教师信赖之选<br>让编程教学更轻松
              </div>
            </div>
            <div class="small-stat-item">
              <i class="fa-solid fa-gamepad text-purple-600" />
              <div class="font-bold text-slate-800">
                520万
              </div>
              <div class="text-xs text-slate-500 mt-1">
                编程比赛专业选手也在玩<br>编程也能很酷
              </div>
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
      </div>
    </template>
  </PageSection>
</template>
<script>
import PageSection from '../../../../components/common/elements/PageSection'
import CTAButton from '../../../../components/common/buttons/CTAButton.vue'
export default {
  name: 'PageSection6',
  components: {
    PageSection,
    CTAButton,
  },
  data () {
    return {
    }
  },
  computed: {
  },
  methods: {
  },
}
</script>
<style scoped lang="scss">

/* Bento Box Stats */
.bento-box {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 24px;
  padding: 2.4rem;
  transition: all 0.3s;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.bento-box:hover {
  transform: translateY(-3px);
  box-shadow: 0 10px 20px rgba(0,0,0,0.05);
}

.bento-box-indigo {
  background: linear-gradient(135deg, #4f46e5, #4338ca);
  color: white;
  border: none;
}

.bento-box-gold {
  border: 2px solid #F2BE22;
  background: #fffbeb;
}

.stat-val {
  font-size: 4.0rem;
  font-weight: 900;
  line-height: 1;
  margin-bottom: 0.8rem;
}

.stat-label {
  font-size: 1.44rem;
  font-weight: 600;
  opacity: 0.9;
}

.small-stat-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 0.8rem;
}

@media (min-width: 1024px) {
  .small-stat-grid {
    grid-template-columns: repeat(5, 1fr);
    gap: 1.6rem;
  }
}

.small-stat-item {
  background: rgba(255,255,255,0.6);
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  padding: 1.6rem 0.8rem;
  text-align: center;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}

.small-stat-item i {
  font-size: 2.4rem;
  margin-bottom: 0.8rem;
}

.cta-button {
  width: 100% !important;
}

</style>