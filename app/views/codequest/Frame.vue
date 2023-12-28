<template>
  <div class="frame">
    <HeadingComponent />
    <ScheduleComponent />
    <CoreCurriculum />
    <ContentComponent />
    <CtaComponent />
  </div>
</template>

<script>
import HeadingComponent from './frame/Heading'
import ScheduleComponent from './frame/Schedule'
import ContentComponent from './frame/Content'
import CtaComponent from './frame/Cta'
import CoreCurriculum from './frame/CoreCurriculum.vue'

export default {
  name: 'FrameComponent',
  components: {
    HeadingComponent,
    ScheduleComponent,
    ContentComponent,
    CtaComponent,
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
