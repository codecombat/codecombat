<template>
  <div class="content">
    <International />
    <Domestic />
  </div>
</template>

<script>
import International from './International'
import Domestic from './Domestic'

export default {
  name: 'ContentComponent',
  components: {
    International,
    Domestic
  }
}
</script>

<style scoped lang="scss">
@import 'app/styles/bootstrap/variables';
.content {
  align-items: stretch;
  display: flex;
  gap: 30px;
  position: relative;

  @media (max-width: $screen-md-max) {
    flex-direction: column;
    align-items: center;
  }
}
</style>
