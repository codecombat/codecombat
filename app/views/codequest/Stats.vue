<template>
  <div class="stats">
    <div class="overlap">
      <div class="bg-image" />
      <StatsContent />
    </div>
  </div>
</template>

<script>
import StatsContent from './StatsContent'

export default {
  name: 'StatsComponent',
  components: {
    StatsContent
  }
}
</script>

<style scoped lang="scss">

.overlap {
  position: relative;
  z-index: 1;
  .bg-image{
    background-image: url('/images/pages/codequest/bg-image.webp');
    width: 300vw;
    position: absolute;
    top:20px;
    bottom: 20px;
    left:-100vw;
  }
}
</style>
