<template>
  <div>
    <p class="heading">
      <span class="text-wrapper">{{ $t('codequest_page.frame_core_heading_1') }}</span>
      <span class="span">{{ $t('codequest_page.frame_core_heading_2') }}</span>
      <span class="text-wrapper">{{ $t('codequest_page.frame_core_heading_3') }}</span>
      <span class="span">{{ $t('codequest_page.frame_core_heading_4') }}</span>
      <span class="text-wrapper">{{ $t('codequest_page.frame_core_heading_5') }}</span>
    </p>
  </div>
</template>

<script>
export default {
  name: 'LabelComponent'
}
</script>

<style scoped lang="scss">
.heading {
  color: transparent;
  font-family: "Plus Jakarta Sans-Medium", Helvetica;
  font-size: 28px;
  font-weight: 500;
  letter-spacing: 0;
  line-height: 36px;
  text-align: center;
}

.text-wrapper {
  color: #000000;
}

.span {
  color: #4799A9;
}
</style>
