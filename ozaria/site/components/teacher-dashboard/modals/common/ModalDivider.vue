
<template>
  <div class="divider">
    <div class="divider-1" />
    <div class="or-text">
      <span> {{ $t("general.or") }} </span>
    </div>
    <div class="divider-2" />
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

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

.or-text {
  width: 54px;
  text-align: center;
}
</style>
