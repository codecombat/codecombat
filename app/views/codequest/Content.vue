<template>
  <div class="content">
    <div class="title">
      The Student Experience
    </div>
    <CoreCurriculum />
  </div>
</template>

<script>
import CoreCurriculum from './CoreCurriculum.vue'
export default {
  name: 'ContentComponent',
  components: {
    CoreCurriculum
  }
}
</script>

<style scoped>
.content {
    align-items: center;
    display: flex;
    flex-direction: column;
    gap: 80px;
    justify-content: center;
    padding: 160px 0 0 ;
    position: relative;
}

.content .title {
    color: #0a2239;
    font-family: "Plus Jakarta Sans-Medium", Helvetica;
    font-size: 36px;
    font-weight: 500;
    letter-spacing: 0;
    line-height: 45px;
    margin-top: -1px;
    position: relative;
    text-align: center;
    width: 100%;
}
</style>
