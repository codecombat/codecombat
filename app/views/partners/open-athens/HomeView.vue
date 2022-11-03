<template>
  <div class="open-athens">
    <div class="open-athens__heading">OpenAthens</div>
    <div id="wayfinder"></div>
  </div>
</template>

<script>
import { getUserInfo } from '../../../core/api/open-athens'
export default {
  name: 'HomeView',
  props: {
    code: {
      type: String
    },
    state: {
      type: String
    }
  },
  async mounted () {
    console.log('mounted', this.code, this.state)
    if (this.code) {
      console.log('codeee', this.code, this.state)
      // how to know its only houston library user and not other library
      const resp = await getUserInfo({
        code: this.code,
        state: this.state
      })
      const { eduPersonUniqueId } = resp.data
      console.log('edu', eduPersonUniqueId)
      return
    }
    this.loadWayFinder()
  },
  loadWayFinder () {
    /* eslint-disable */
    (function(w,a,y,f){
        w._wayfinder=w._wayfinder||function(){(w._wayfinder.q=w._wayfinder.q||[]).push(arguments)};
        const p={oaDomain:'codecombat.com',oaAppId:'6a0d8c7e-3577-41e0-9e6b-220da4c8e8c6'};
        w._wayfinder.settings=p;const h=a.getElementsByTagName('head')[0];const s=a.createElement('script');s.async=1;
        const q=Object.keys(p).map(function(key){return key+'='+p[key]}).join('&');
        s.src=y+'v1'+f+"?"+q;h.appendChild(s);}
    )(window,document,'https://wayfinder.openathens.net/embed/','/loader.js')
  }
}
</script>

<style scoped>

</style>
