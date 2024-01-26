<template>
  <div class="stat">
    <img
      class="vector"
      alt="Vector"
      :src="imgSrc"
    >
    <div class="content">
      <div class="text-wrapper">
        {{ text }}
      </div>
      <div class="description">
        {{ description }}
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'StatCard',
  props: {
    imgClass: {
      type: String,
      required: true
    },
    imgSrc: {
      type: String,
      default: ''
    },
    text: {
      type: String,
      default: ''
    },
    description: {
      type: String,
      default: ''
    }
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/component_variables.scss";
.stat {
  align-items: center;
  display: flex;
  gap: 12px;
  position: relative;
  width: 226px;
}

.vector {
  position: relative;
}

.vector {
  height: 49.11px;
  width: 60px;
}

.content {
  align-items: flex-start;
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-right: -8px;
  position: relative;
  width: 162px;
}

.text-wrapper {
  @extend %font-24-34;
  font-weight: 500;
  letter-spacing: 0;
  position: relative;
  width: 162px;
}

.description {
  @extend %font-16;
  color: $light-grey;
  font-weight: 300;
  position: relative;
  width: 162px;
}
</style>
