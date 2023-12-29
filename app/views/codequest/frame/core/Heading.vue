<template>
  <div>
    <p class="heading">
      <span class="text-wrapper">This Opportunity is Open to </span>
      <span class="span">International</span>
      <span class="text-wrapper"> and </span>
      <span class="span">Domestic</span>
      <span class="text-wrapper"> Participants</span>
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
