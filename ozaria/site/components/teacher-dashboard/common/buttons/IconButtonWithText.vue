
<script>
  export default {
    props: {
      iconName: {
        type: String,
        required: true,
        default: ''
      },
      text: {
        type: String,
        required: true,
        default: ''
      }
    }
  }
</script>

<template>
  <div
    class="btn-icon-text"
    @click="$emit('click')"
  >
    <img :src="'/images/ozaria/teachers/dashboard/svg_icons/'+iconName+'.svg'">
    <span> {{ text }} </span>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

.btn-icon-text {
  display: flex;
  align-items: center;
  cursor: pointer;

  img {
    width: 18px;
    height: 18px;
    margin: 0 4px;
  }

  span {
    @include font-p-3-small-button-text-dusk-dark;
    font-size: 12px;
    font-weight: 500;
    line-height: 12px;
    margin: 0 4px;
    text-align: left;
  }
}
</style>
