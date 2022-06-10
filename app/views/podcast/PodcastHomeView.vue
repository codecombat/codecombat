<template>
  <div>
    <div class="podcast">
      <head-component />
      <body-component />
      <footer-component />
    </div>
  </div>
</template>

<script>
import HeadComponent from './HeadComponent'
import BodyComponent from './BodyComponent'
import FooterComponent from './FooterComponent'
export default {
  name: 'PodcastHomeView',
  components: {
    HeadComponent,
    BodyComponent,
    FooterComponent
  },
  data () {
    return {
      keyVal: Date.now(),
      componentKey: 0
    }
  },
  created () {
    console.log('update called')
    this.keyVal = Date.now()
    this.componentKey = Math.random()
  },
  methods: {
    forceRerender() {
      this.componentKey += 1;
    }
  }
}
</script>

<style scoped lang="scss">
.podcast {
  font-size: 62.5%;

  padding: 5rem;
}
</style>
