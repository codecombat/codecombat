<template>
  <div>
    <p class="heading">
      <span class="text-wrapper">{{ $t('codequest_page.frame_heading_1') }}</span>
      <span class="span">{{ $t('codequest_page.frame_heading_2') }}</span>
      <span class="text-wrapper">{{ $t('codequest_page.frame_heading_3') }}</span>
      <span class="span">{{ $t('codequest_page.frame_heading_4') }}</span>.
    </p>
  </div>
</template>

<script>
export default {
  name: 'LabelComponent'
}
</script>

<style scoped>

.heading {
  font-family: "Plus Jakarta Sans-Medium", Helvetica;
  font-size: 36px;
  font-weight: 500;
  letter-spacing: 0;
  line-height: 45px;
  text-align: center;
}

.text-wrapper {
  color: #0a2239;
}

.span {
  color: #4799A9;
}

.text-wrapper-2 {
  color: #000000;
}
</style>
