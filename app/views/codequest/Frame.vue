<template>
  <div class="frame">
    <Heading />
    <Schedule />
    <CoreCurriculum />
    <ContentX />
    <Cta />
  </div>
</template>

<script>
import Heading from './frame/Heading'
import Schedule from './frame/Schedule'
import ContentX from './frame/Content'
import Cta from './frame/Cta'
import CoreCurriculum from './frame/CoreCurriculum.vue'

export default {
  name: 'FrameComponent',
  components: {
    Heading,
    Schedule,
    ContentX,
    Cta,
    CoreCurriculum
  }
}
</script>

<style scoped>
.frame {
  align-items: center;
  display: flex;
  flex-direction: column;
  gap: 70px;
  padding: 100px 40px;
  position: relative;
}

.frame .core-curriculum {
  flex: 0 0 auto;
  position: relative;
}
</style>

Components in selection (1)
Button_A
