<template>
  <div>
    <p class="heading">
      <span class="text-wrapper">The paced schedule will fill the days with a mixture of </span>
      <span class="span">learning</span>
      <span class="text-wrapper"> and </span>
      <span class="span">fun</span><span class="text-wrapper-2">.</span>
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
  color: transparent;
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
