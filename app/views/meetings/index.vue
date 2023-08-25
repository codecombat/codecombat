<template>
  <div class="coco-meeting">
    <daily-home />
  </div>
</template>

<script>
import DailyHome from './daily/components/Home.vue'

export default {
  name: 'CoCoMeeting',
  components: {
    DailyHome
  }
}

</script>

<style scoped>
:root {
  --grey-lightest: #f7f9fa;
  --white: #ffffff;
  --grey: #c8d1dc;
  --dark-grey: #6b7785;
  --dark-blue: #1f2d3d;
  --dark-blue-border: #2b3f56;
  --teal: #1bebb9;
  --red-dark: #bb0c0c;
  --font-family: GraphikRegular, "Helvetica Neue", Sans-Serif;
}

.coco-meeting {
  height: 70vh;
  font-family: Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  overflow: scroll;
  display: flex;
  flex-direction: column;
  background-color: #121a24;
}
a {
  text-decoration: none;
  color: #2c3e50;
  display: flex;
  align-items: center;
}
</style>
