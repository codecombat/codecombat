<template>
  <div
    class="page-section section spaced-section"
    style="background: #021e27;"
  >
    <div class="frame constrained-width">
      <div class="heading">
        <span class="title">学完之后，孩子能收获什么</span><br>
        <p class="description">
          扣哒宇宙的课程设计围绕六大核心能力展开——每一项都是面向未来的刚需技能
        </p>
      </div>
      <div class="image-container">
        <img
          src="/images/pages/hackstack-new/m.png"
          alt="六大核心能力成长对照图"
          class="outcomes-image"
        >
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'OutcomesSection',
}
</script>

<style scoped lang="scss">
.spaced-section { padding: 100px 0; }
.constrained-width { max-width: 1100px; margin: 0 auto; width: 100%; padding: 0 20px; }

.heading {
    text-align: center;
    .title {
        font-size: 36px;
        font-weight: bold;
        color: #fff;
    }
    .description {
        color: #b4b4b4;
        font-size: 16px;
        margin-top: 15px;
    }
}

.image-container {
    text-align: center;
    margin-top: 50px;
}

.outcomes-image {
    max-width: 100%;
    height: auto;
    border-radius: 12px;
    display: inline-block;
}

@media (max-width: 768px) {
    .heading .title { font-size: 28px; }
}
</style>
