<template>
  <div class="podcast">
    <head-component />
    <body-component />
    <footer-component />
  </div>
</template>

<script>
import HeadComponent from './HeadComponent'
import BodyComponent from './BodyComponent'
import FooterComponent from './FooterComponent'
export default {
  name: 'PodcastMainComponent',
  components: {
    HeadComponent,
    BodyComponent,
    FooterComponent
  }
}
</script>

<style scoped lang="scss">
.podcast {
  font-size: 62.5%;

  padding: 5rem;
}
</style>
