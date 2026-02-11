<template>
  <div class="china-subscribe-modal">
    <base-game-modal @close="$emit('close')">
      <template #header>
        <img
          :src="dynamicBackground"
          class="background"
        >
        <div class="main-title">
          开启你的编程进化之旅
        </div>
      </template>
      <template #body>
        <div class="sub-title">
          解锁 2300+ 关卡 · AI 老师 24h 答疑
        </div>
        <div class="plans-container">
          <div class="card">
            <div class="corner-ribbon ribbon-gray">
              体验尝鲜
            </div>
            <div class="card-title">
              月度会员
            </div>
            <div class="price-row">
              <span class="symbol">¥</span><span class="amount">99</span><span class="unit"> / 1个月</span>
            </div>

            <div class="info-box warning-box">
              <span class="warning-main">短期体验，适合试用</span>
              <span class="warning-sub">⚠️ 30 天通常无法完成完整学习路径</span>
            </div>

            <ul class="check-list">
              <li class="positive">
                可体验基础关卡与玩法
              </li>
              <li class="positive">
                感受游戏化学编程方式
              </li>
              <li class="negative">
                无法完成完整学习路径
              </li>
              <li class="negative">
                学习进度容易中断
              </li>
              <li class="negative">
                不包含阶段性成长反馈
              </li>
            </ul>

            <div style="font-size:10px; color:#999; margin-top:5px;">
              不确定是否适合？可以从体验开始<br>
              <span style="color:#d35400; font-weight:bold;">多数用户1 个月后还想继续学</span>
            </div>
            <button
              class="btn btn-gray"
              @click="$emit('month')"
            >
              立即体验
            </button>
          </div>

          <div class="card featured">
            <div class="gold-badge">
              官方推荐 · 更多人选择
            </div>

            <div class="shimmer-mask" />

            <div class="featured-content">
              <div class="featured-header">
                <img
                  src="/images/pages/subscribe/AnyaPose.png"
                  alt="Anya"
                  class="anya-icon"
                >
                <h2>完整编程成长计划</h2>
              </div>

              <div class="price-row">
                <span class="symbol">¥</span><span class="amount">269</span><span class="unit"> / 3个月</span>
              </div>

              <div style="margin-top:-2px; margin-bottom:5px; font-size:11px; color:#999;">
                <span style="text-decoration:line-through;">原价¥299</span> <span style="color:#e74c3c; font-weight:bold;">限时立省 30元</span>
                <br><span class="deadline-text">⏰ 3月1日恢复原价299元</span>
              </div>

              <div class="hot-pot-tag">
                🔥 一顿火锅钱，从零基础到真正掌握编程基础
              </div>

              <ul class="check-list">
                <li class="positive">
                  解锁全部关卡与完整内容
                </li>
                <li class="positive">
                  连续学习解锁专属成就
                </li>
                <li class="positive">
                  完整学习周期，获得官方学习记录
                </li>
                <li
                  class="positive"
                  style="color:#2980b9;"
                >
                  赠送价值90元的 9000 宝石
                </li>
              </ul>

              <button
                class="btn btn-gold"
                @click="$emit('season')"
              >
                我将系统学习编程
              </button>
              <div class="sub-btn-text">
                💡 90% 的长期用户从这个方案开始
              </div>
            </div>
          </div>

          <div class="card">
            <div class="corner-ribbon ribbon-purple">
              长期成长计划
            </div>
            <div class="card-title">
              年度会员
            </div>
            <div class="price-row">
              <span class="symbol">¥</span><span class="amount">999</span><span class="unit"> / 365天</span>
            </div>
            <div style="font-size:11px; color:#888; margin-bottom:5px;">
              8.3 折 · 平均每天仅 2.7元
            </div>

            <div
              class="info-box"
              style="background:#f3e5f5; color:#8e44ad;"
            >
              <span style="font-weight:bold; display:block; font-size:12px;">最佳投资，专注成长</span>
              <span style="font-size:10px;">给真正想学会编程的人</span>
            </div>

            <ul class="check-list">
              <li class="positive">
                包含季度会员全部权益
              </li>
              <li class="positive">
                年度专属学习报告
              </li>
              <li class="positive">
                年度知识点系统总结
              </li>
              <li class="positive">
                客服优先答疑
              </li>
              <li
                class="positive"
                style="color:#2980b9;"
              >
                赠送价值 420元 的 42000 宝石
              </li>
            </ul>

            <button
              class="btn btn-green"
              @click="$emit('year')"
            >
              开启年度学习计划
            </button>
          </div>
        </div>
      </template>
      <template #footer>
        <div class="testimonial-container">
          <div class="testimonial-icon">
            📜
          </div>
          <div
            class="testimonial-text"
            :style="testimonialStyles"
            v-html="currentTestimonial"
          />
        </div>

        <div
          class="redeem-code-container"
          v-html="redeemText"
        />
      </template>
    </base-game-modal>
    <div class="mobile-fixed-btn">
      <button
        class="mobile-btn-inner"
        @click="$emit('season')"
      >
        我将系统学习编程 (269元)
      </button>
    </div>
  </div>
</template>
<script>
import BaseGameModal from 'app/components/common/BaseGameModal'
export default {
  name: 'ChinaSbuscribe',
  components: {
    BaseGameModal,
  },
  data () {
    return {
      testimonials: [
        '“学了三个月，孩子现在对编程没那么怕了” <span class="testimonial-author">— 高二学生爸爸</span>',
        '“我是文科生，也能跟得上，没想象中那么难” <span class="testimonial-author">— 大一女生</span>',
        '“比老师照本宣科讲课好懂多了” <span class="testimonial-author">— 大二计科男生</span>',
        '“不用催，孩子自己会打开学，这点挺难得的” <span class="testimonial-author">— 小学生家长</span>',
        '“一关一关来，不会一下子把人劝退” <span class="testimonial-author">— 编程小白</span>',
        '“之前完全不懂代码，现在起码知道在写什么了” <span class="testimonial-author">— 转码打工人</span>',
        '“一次学一段时间，比试试看的感觉踏实” <span class="testimonial-author">— 长期学习用户</span>',
        '“完整学下来，比零零散散看视频强” <span class="testimonial-author">— 理性型家长</span>',
        '“有问题能马上问AI，半夜学也不慌” <span class="testimonial-author">— 熬夜学习的学生</span>',
        '“从啥都不懂到能看懂代码，还挺有成就感的” <span class="testimonial-author">— 零基础学员</span>',
      ],
      testIndex: 0,
      testTimer: null,
      testimonialStyles: {},
    }
  },
  computed: {
    dynamicBackground () {
      const mq = window.matchMedia('(max-width: 768px)')
      if (mq.matches) {
        return '/images/pages/subscribe/announcement_modal_bg-2.png'
      }
      return '/images/pages/subscribe/announcement_modal_bg.png'
    },
    redeemText () {
      return $.i18n.t('subscribe.having_activation_code')
    },
    currentTestimonial () {
      return this.testimonials[this.testIndex]
    },
  },
  mounted () {
    this.testTimer = setInterval(this.updateTicker, 3500)
  },
  methods: {
    updateTicker () {
      this.testimonialStyles = {
        opacity: 0,
        transform: 'translateY(10px)',
      }
      setTimeout(() => {
        this.testIndex = (this.testIndex + 1) % this.testimonials.length
        this.testimonialStyles = {
          opacity: 1,
          transform: 'translateY(0)',
        }
      }, 500)
    },
  },
  beforeUnmounted () {
    if (this.testTimer) {
      clearInterval(this.testTimer)
    }
  },
}
</script>
<style lang="scss" scoped>
/* =========================================
   全局变量与基础设置
   ========================================= */
$--green: #2ecc71;
$--green-dark: #27ae60;
$--gold: #f1c40f;
$--gold-dark: #d35400;
$--red: #e74c3c;
$--gray-btn-bg: #dfe6e9;
$--gray-btn-text: #636e72;
$--text-dark: #2c3e50;
$--text-light: #7f8c8d;
$--card-bg: #fdfefe;
$--card-bg-highlight: #fffbf0;

.china-subscribe-modal {
  ::v-deep {
    .game-modal-content {
      justify-content: flex-start;
    }

    .modal-container {
      width: 1050px;
      height: 732px;
    }
    .close-button {
      left: 799px;
      top: 44px;
      width: 84px;
      height: 84px;
      font-size: 42px;
    }
    .modal-header {
      padding-top: 50px;
    }
    .modal-body {
      padding-top: 10px;
      justify-content: space-between;
    }
    .modal-footer {
      position: relative;
    }

    @media (max-width: 768px) {
      .modal-container {
        width: 92%;
        height: 90vh;
        overflow-y: scroll;
        margin-left: auto;
        margin-right: auto;
        margin-bottom: 20px;
      }
      .background {
        width: 100%;
        height: 1400px;
      }
      .modal-body {
        justify-content: flex-start;
      }
      .close-button {
        left: 75%;
        top: 16px;
        width: 42px;
        height: 42px;
        font-size: 21px;
      }
    }
  }
}
.background {
  width: 1050px;
}
/* 触发按钮 (演示用) */
.trigger-btn {
  position: fixed;
  top: 20px;
  left: 20px;
  padding: 10px 20px;
  font-size: 16px;
  color: white;
  background-color: $--green;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  z-index: 100;
}

/* =========================================
   2. 标题区域
   ========================================= */
.header-area {
  margin-top: 0;
  margin-bottom: 15px;
  position: relative;
  z-index: 10;
}

/* 第一行：主标题 */
.main-title {
  font-family: "Arial Black", "Impact", sans-serif;
  font-size: 48px;
  color: $--gold;
  text-transform: uppercase;
  -webkit-text-stroke: 2px #000;
  text-shadow: 3px 3px 0 #000;
  transform: scaleX(0.9);
  display: inline-block;
  margin-bottom: 5px;
}

/* 第二行：副标题 (带背景) */
.sub-title {
  font-size: 22px;
  color: #ecf0f1;
  font-weight: bold;
  text-shadow: 1px 1px 1px #000;
  background-color: rgba(93, 64, 55, 0.8);
  padding: 4px 15px;
  border-radius: 20px;
  display: inline-block;
}

/* =========================================
   3. 卡片布局 (保持紧凑)
   ========================================= */
.plans-container {
  display: flex;
  justify-content: center;
  align-items: flex-start;
  gap: 12px;
  width: 900px;
  height: 420px;
}

.card {
  background-color: $--card-bg;
  border-radius: 12px;
  padding: 12px 8px;
  width: 29%;
  position: relative;
  box-shadow: 0 5px 15px rgba(0,0,0,0.2);
  border: 1px solid #bdc3c7;
  text-align: center;
  display: flex;
  flex-direction: column;
  margin-top: 20px;
}

/* 顶部角标 */
.corner-ribbon {
  position: absolute;
  top: 0;
  padding: 3px 10px;
  color: white;
  font-size: 13px;
  font-weight: bold;
}
.ribbon-gray { left: 0; background: #95a5a6; border-radius: 12px 0 10px 0; }
.ribbon-purple { right: 0; background: #8e44ad; border-radius: 0 12px 0 10px; }

.card-title {
  font-size: 22px;
  font-weight: bold;
  color: $--text-dark;
  margin: 10px 0 2px 0;
}

.price-row { margin: 2px 0; color: $--text-dark; }
.symbol { font-size: 16px; font-weight: bold; vertical-align: top; }
.amount { font-size: 28px; font-weight: 900; line-height: 1; }
.unit { font-size: 13px; color: $--text-light; }

/* 通用描述框 */
.info-box {
  padding: 5px;
  border-radius: 6px;
  margin: 5px 0;
  line-height: 1.3;
  font-size: 13px;
}

.warning-box {
  background: #fff3cd;
  color: #856404;
  border: 1px solid #ffeeba;
  text-align: center;
}
.warning-main { font-weight: bold; font-size: 14px; display: block; margin-bottom: 0px;}
.warning-sub { font-size: 12px; opacity: 0.9; display: block; }

/* 列表样式 */
.check-list {
  list-style: none;
  text-align: left;
  padding: 0 5px;
  margin-bottom: auto;
  font-size: 13px;
  color: #666;
  line-height: 1.4;
}
.check-list li {
  position: relative;
  padding-left: 16px;
  margin-bottom: 3px;
}

.check-list li.positive::before {
  content: "✔";
  position: absolute;
  left: 0;
  color: $--green;
  font-weight: bold;
}
.check-list li.negative { color: #95a5a6; }
.check-list li.negative::before {
  content: "✖";
  position: absolute;
  left: 2px;
  color: $--red;
  font-weight: bold;
  font-size: 12px;
  top: 2px;
}

/* 按钮通用 */
.btn {
  width: 100%;
  border: none;
  border-radius: 6px;
  padding: 8px;
  font-size: 16px;
  font-weight: bold;
  cursor: pointer;
  margin-top: 5px;
  transition: all 0.2s;
  position: relative;
  z-index: 2;
}
.btn-gray { background: $--gray-btn-bg; color: $--gray-btn-text; border: 1px solid #ced6e0; }
/* 绿色按钮的悬停效果 */
.btn-green { background: $--green; color: white; box-shadow: 0 3px 0 #1e8449; }
.btn-green:hover { background: $--green-dark; }

/* =========================================
   4. 中间卡片 (核心重构)
   ========================================= */
.card.featured {
  width: 36%;
  background-color: $--card-bg-highlight;
  border: 3px solid $--gold;
  z-index: 5;
  box-shadow: 0 15px 40px rgba(241, 196, 15, 0.4);
  margin-top: 0;
  transform: scale(1.01);
  animation: breathe 3s infinite ease-in-out;
  overflow: visible;
}

.shimmer-mask {
  position: absolute;
  top: 0; left: 0; width: 100%; height: 100%;
  border-radius: 9px; overflow: hidden; z-index: 0; pointer-events: none;
}
.featured-content { position: relative; z-index: 1; }
.shimmer-mask::after {
  content: ""; position: absolute; top: -50%; left: -50%; width: 200%; height: 200%;
  background: linear-gradient(to right, rgba(255, 255, 255, 0) 0%, rgba(255, 255, 255, 0.3) 50%, rgba(255, 255, 255, 0) 100%);
  transform: rotate(30deg); animation: shimmer 6s infinite linear;
}

@keyframes breathe {
  0% { box-shadow: 0 15px 40px rgba(241, 196, 15, 0.3); border-color: #f1c40f; }
  50% { box-shadow: 0 20px 50px rgba(241, 196, 15, 0.6); border-color: #f39c12; }
  100% { box-shadow: 0 15px 40px rgba(241, 196, 15, 0.3); border-color: #f1c40f; }
}
@keyframes shimmer {
  0% { transform: translateX(-150%) rotate(30deg); }
  20% { transform: translateX(150%) rotate(30deg); }
  100% { transform: translateX(150%) rotate(30deg); }
}

.gold-badge {
  position: absolute;
  top: -14px;
  left: 50%;
  transform: translateX(-50%);
  background: $--gold;
  color: #d35400;
  font-weight: 900;
  padding: 4px 20px;
  font-size: 15px;
  clip-path: polygon(0 0, 100% 0, 95% 50%, 100% 100%, 0 100%, 5% 50%);
  box-shadow: 0 2px 5px rgba(0,0,0,0.2);
  white-space: nowrap;
  z-index: 100;
}

.featured-header {
  display: flex;
  justify-content: center;
  align-items: center;
  margin-top: 20px;
  margin-bottom: 2px;
}
.anya-icon {
  width: 30px;
  height: auto;
  margin-right: 5px;
  transform: scaleX(-1) rotate(-10deg);
}
.featured-header h2 {
  font-size: 20px;
  font-weight: 900;
  color: #d35400;
}

.featured .amount { color: #d35400; font-size: 38px; }

.hot-pot-tag {
  font-size: 12px;
  color: #e67e22;
  font-weight: bold;
  margin: 5px 0 10px 0;
  background: #fff3e0;
  display: inline-block;
  padding: 3px 12px;
  border-radius: 20px;
  border: 1px solid #ffe0b2;
  box-shadow: 0 2px 5px rgba(230, 126, 34, 0.2);
}

/* --- [黄色按钮交互修改区域] --- */
.btn-gold {
  background: linear-gradient(to bottom, #f1c40f, #f39c12);
  color: white;
  font-size: 16px;
  padding: 10px;
  box-shadow: 0 4px 0 #d35400;
  text-shadow: 1px 1px 0 rgba(0,0,0,0.2);
  /* 添加过渡效果，让变色平滑 */
  transition: all 0.2s ease;
}
.btn-gold:active { transform: translateY(2px); box-shadow: 0 2px 0 #d35400; }

/* 【修改说明 - 黄色按钮鼠标悬停效果】 */
.btn-gold:hover {
  /* 提高亮度，使其看起来发光 */
  filter: brightness(1.15);
  /* 稍微向上移动 1像素 */
  transform: translateY(-1px);
  /* 增强阴影 */
  box-shadow: 0 5px 0 #d35400;
}

.sub-btn-text {
  font-size: 12px;
  color: #d35400;
  margin-top: 5px;
  font-weight: bold;
}

.deadline-text {
  color: #c0392b;
  font-size: 12px;
  font-weight: bold;
  display: inline-block;
  margin-top: 2px;
  background: rgba(231, 76, 60, 0.1);
  padding: 2px 5px;
  border-radius: 4px;
}

/* =========================================
   5. 底部信息行
   ========================================= */
.footer-row {
  display: flex;
  justify-content: center; /* 评价居中 */
  align-items: center;
  width: 100%;
  margin-top: 15px;
  gap: 15px;
  flex-wrap: wrap;
  /* 修改：增加 relative 定位，方便子元素绝对定位 */
  position: relative;
}

/* 滚动评价区 */
.testimonial-container {
  background: rgba(0,0,0,0.3);
  border-radius: 20px;
  padding: 5px 20px;
  display: inline-flex;
  align-items: center;
  width: 480px;
  max-width: 100%;
  height: 34px;
  overflow: hidden;
  position: relative;
}
.testimonial-icon { margin-right: 10px; font-size: 14px; }
.testimonial-text {
  color: #fff;
  font-size: 12px;
  white-space: nowrap;
  transition: opacity 0.5s ease-in-out, transform 0.5s ease-in-out;
  width: 100%;
  text-align: left;
}
.testimonial-author {
  color: #f1c40f;
  font-weight: bold;
  margin-left: 5px;
  font-size: 11px;
}

/* 兑换码区域 */
.redeem-code-container {
  font-size: 13px;
  color: #000000;
  font-weight: bold;
  white-space: nowrap;
  background: rgba(255,255,255,0.4);
  padding: 6px 15px;
  border-radius: 20px;
  /* 修改：绝对定位到右侧 */
  position: absolute;
  right: 40px;
  top: 50%;
  transform: translateY(-50%);
}
.redeem-btn {
  background: transparent;
  border: none;
  color: #2980b9;
  font-weight: bold;
  cursor: pointer;
  text-decoration: underline;
  font-size: 13px;
  padding: 0 0 0 5px;
}
.redeem-btn:hover { color: #3498db; }

/* =========================================
   6. 移动端适配 (核心修改区域)
   ========================================= */
.mobile-fixed-btn { display: none; }

::v-deep() {
  .china-subscribe-modal {
    @media (max-width: 768px) {
      /* --- [移动端关闭按钮] --- */
      .close-button {
        /* [位置] 控制叉叉的上下左右 */
        top: 20px;
        right: 20px;

        width: 30px;
        height: 30px;
        font-size: 21px;
      }

      /* --- [移动端标题区域] --- */
      .header-area {
        /* [位置] 控制标题区域的上下间距 */
        margin-top: 0;
        margin-bottom: 15px;
      }
    }
  }
}
@media (max-width: 768px) {
  .main-title {
    /* [修改点] 字体变小，防止换行 */
    font-size: 24px;
    -webkit-text-stroke: 1px #000;
    transform: none;
    white-space: normal;
    line-height: 1.2;
  }
  .sub-title {
    /* [副标题] 字体大小 */
    font-size: 13px;
    margin-bottom: 20px;
  }

  /* --- [移动端卡片布局] --- */
  /* 保持垂直排列，上下显示 */
  .plans-container {
    flex-direction: column;
    align-items: center;
    width: unset;
    height: unset;
  }

  .card {
    width: 100%; /* 卡片宽度占满 */
    margin-top: 15px; /* 卡片之间的间距 */
  }

  /* 移动端排序逻辑：269 -> 999 -> 99 */
  .card.featured {
    order: 1; /* 269元排第一 */
    width: 100%;
    min-height: auto;
    margin-top: 0;
    justify-content: center;
  }

  .card:nth-child(3) {
    order: 2; /* 999元排第二 */
  }

  .card:nth-child(1) {
    order: 3; /* 99元排第三 */
  }

  .featured .amount { font-size: 56px; }
  .featured .check-list { font-size: 14px; margin: 15px 0; }

  /* --- [移动端底部布局调整] --- */
  .footer-row { flexDirection: column; gap: 10px; margin-top: 20px; }

  /* [修改点] 评价容器高度自适应，允许换行 */
  .testimonial-container {
    width: 95%;
    height: auto; /* 自动高度 */
    min-height: 40px;
    padding: 10px 15px;
    align-items: flex-start; /* 对齐顶部 */
  }
  /* [修改点] 评价文字允许换行 */
  .testimonial-text {
    white-space: normal;
    line-height: 1.4;
  }
  .testimonial-icon { margin-top: 2px; }

  /* [修改点] 重置兑换码位置，使其在评价下方 */
  .redeem-code-container {
    position: static;
    transform: none;
    margin-top: 10px;
  }

  .mobile-fixed-btn {
    display: flex; justify-content: center; align-items: center;
    position: fixed; bottom: 0; left: 0; width: 100%;
    background: white; padding: 15px;
    box-shadow: 0 -5px 20px rgba(0,0,0,0.1);
    z-index: 19000;
  }
  .mobile-btn-inner {
    width: 100%;
    background: linear-gradient(to right, #f1c40f, #d35400);
    color: white; font-weight: bold; font-size: 18px;
    padding: 12px; border-radius: 30px; border: none;
    box-shadow: 0 4px 10px rgba(211, 84, 0, 0.4);
    text-align: center;
    animation: pulse-btn 2s infinite;
  }
  @keyframes pulse-btn {
    0% { transform: scale(1); }
    50% { transform: scale(1.03); }
    100% { transform: scale(1); }
  }
}
</style>