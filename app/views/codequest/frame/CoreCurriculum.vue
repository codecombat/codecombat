S
index.vue
<template>
  <div class="core-curriculum">
    <Heading />
    <ContentComponent />
  </div>
</template>

<script>
import Heading from './core/Heading'
import ContentComponent from './core/Content'

export default {
  name: 'CoreCurriculum',
  components: {
    Heading,
    ContentComponent
  }
}
</script>

<style scoped>
.core-curriculum {
  align-items: center;
  display: inline-flex;
  flex-direction: column;
  gap: 40px;
  padding: 10px 0px;
  position: relative;
}
</style>
