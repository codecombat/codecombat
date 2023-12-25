<template>
  <div
    :class="pointLeft ? 'point-left' : ''"
    @click="$emit('click')"
  />
</template>

<script>
export default {
  props: {
    pointLeft: {
      type: Boolean,
      default: false
    }
  }
}
</script>

<style scoped>
div {
  width: 40px;
  height: 40px;
  display: inline-block;

  background: url(/images/pages/parents/arrow_right.svg) no-repeat 50% 50%;
  background-size: 90%;
  cursor: pointer;
}

div.point-left {
  transform: rotateZ(180deg);
}

div:hover {
  background: url(/images/pages/parents/arrow_right_hover.svg) no-repeat 50% 50%;
  background-size: 90%;
}
</style>
