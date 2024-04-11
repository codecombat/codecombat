<template>
  <div class="accessibility-rep">
    <div class="image">
      <img
        class="img"
        alt="Image"
        src="/images/pages/codequest/rep-img.jpeg"
      >
    </div>
    <div class="content">
      <div class="title">
        {{ $t('codequest_page.accessibility_title') }}
      </div>
      <ul class="flexcontainer">
        <li class="text">
          <span class="text-wrapper">
            {{ $t('codequest_page.accessibility_text_1') }}
            <br>
          </span>
        </li>
        <li class="text">
          <span class="text-wrapper">
            {{ $t('codequest_page.accessibility_text_2') }}
            <br>
          </span>
        </li>
        <li class="text">
          <span class="text-wrapper">
            {{ $t('codequest_page.accessibility_text_3') }}
            <br>
          </span>
        </li>
        <li class="text">
          <span class="text-wrapper">
            {{ $t('codequest_page.accessibility_text_4') }}
          </span>
        </li>
      </ul>
    </div>
  </div>
</template>

<script>
export default {
  name: 'AccessibilityRep'
}
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";

.accessibility-rep {
  align-items: flex-start;
  display: flex;
  gap: 30px;
  margin: 160px 40px;
  position: relative;
  @media (max-width: $screen-md-max) {
    flex-direction: column;
    align-items: center;
    gap: 60px;
  }
}

.accessibility-rep .image {
  flex: 1;
  flex-grow: 1;
  object-fit: cover;
  position: relative;

  .img {
    width: 100%;
    border-radius: 24px;
    box-shadow: 0px 6px 22px 0px rgba(0, 0, 0, 0.10);
  }
}

.accessibility-rep .content {
  align-items: flex-start;
  display: flex;
  flex: 1;
  flex-direction: column;
  flex-grow: 1;
  gap: 40px;
  justify-content: center;
  position: relative;
}

.accessibility-rep .title {
  align-self: stretch;
  color: #0a2239;
  font-family: "Plus Jakarta Sans-Medium", Helvetica;
  font-size: 36px;
  font-weight: 500;
  letter-spacing: 0;
  line-height: 45px;
  margin-top: -1px;
  position: relative;
}

.accessibility-rep .flexcontainer {
  align-items: flex-start;
  display: flex;
  flex-direction: column;
  gap: 30px;
}

.accessibility-rep .text {
  align-self: stretch;
  color: #000000;
  font-family: "Plus Jakarta Sans-Medium", Helvetica;
  font-size: 18px;
  font-weight: 500;
  letter-spacing: 0;
  line-height: 24px;
  position: relative;
}

.accessibility-rep .text-wrapper {
  color: #000000;
  font-family: "Plus Jakarta Sans-Medium", Helvetica;
  font-size: 18px;
  font-weight: 500;
  letter-spacing: 0;
  line-height: 24px;
}
</style>
