<script>
  export default Vue.extend({
    props: {
      withOrText: {
        type: Boolean,
        default: true
      }
    }
  })
</script>

<template>
  <div
    v-if="withOrText"
    class="divider"
  >
    <div class="divider-1" />
    <div class="or-text">
      <span> {{ $t("general.or") }} </span>
    </div>
    <div class="divider-2" />
  </div>
  <div
    v-else
    class="divider divider-3"
  />
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "app/styles/core/variables";

.divider {
  display: flex;
  flex-direction: row;
  align-items: center;
  margin-bottom: 10px;
  margin-top: 21px;
  span {
    font-family: Work Sans;
    font-size: 28px;
    line-height: 33px;
    color: $goldenlight;
    font-weight: 600;
  }
}

.divider-1, .divider-2 {
  height: 8px;
  width: 230px;
  display: inline-block;
}

.divider-1 {
  background: linear-gradient(to left, #efc947 0%, #F7D047 80.4%, #F7D047 100%);
}

.divider-2 {
  background: linear-gradient(to left, #D1B147 0%, #D1B147 40%, #efc947 100%);
}

.divider-3 {
  height: 8px;
  width: 511px;
  display: inline-block;
  background: linear-gradient(0.95deg, #D1B147 -5.07%, #D1B147 16.64%, #F7D047 93.04%, #F7D047 103.46%);
}

.or-text {
  width: 54px;
  text-align: center;
}
</style>
