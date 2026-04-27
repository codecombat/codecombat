<template>
  <div
    class="page-section section spaced-section"
    style="background: #021e27; text-align: center;"
  >
    <div class="frame constrained-width">
      <div class="heading">
        <span class="title">
          现在开始，为您的学生开启AI时代的大门
        </span>
        <p class="description">
          政策窗口已经打开，越早行动的学校，学生越早受益
        </p>
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
</template>

<script>
export default {
  name: 'CtaSection',
  inject: ['toggleQRModal'],
}
</script>

<style scoped lang="scss">
.spaced-section { padding: 100px 0; }
.constrained-width { max-width: 1100px; margin: 0 auto; width: 100%; padding: 0 20px; }

.heading {
    margin-bottom: 40px;
    .title {
        font-size: 42px;
        color: #fff;
        font-weight: bold;
    }
    .description {
        color: #b4b4b4;
        font-size: 20px;
        margin-top: 20px;
    }
}

.btns-group {
    display: flex;
    gap: 20px;
    justify-content: center;
    margin-top: 40px;
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
    .heading .title { font-size: 32px; }
}
</style>
