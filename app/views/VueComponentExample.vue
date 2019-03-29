<template lang="pug">
  div.test-component
    a(href="/") Go to home page
    h3 Yay! This is the example Vue Component routed to directly (in background, this is rendered by the generic backbone view 'VueComponentView.js'!
    h3 Value of id passed in by the URL is - {{ id }}
    h3 Computed value of testState (which is registered by the vuex module on this page) is - {{ testState }}
    h3 Using a different vue component pie-chart here:
    pie-chart.pie(
        :percent='10',
        :stroke-width="10",
        color="#000000",
        :opacity="1"
      )
</template>

<script>

import PieChart from 'core/components/PieComponent'

module.exports = Vue.extend({
  props: {  // props data should be passed in from the router
    id: {
      type: Number
    }
  },
  components: {
    'pie-chart': PieChart   //using another vueComponent inside this
  },
  beforeCreate() {
    // Register a vuex store module for this page, which will be destroyed when navigating away from the page
    this.$store.registerModule('page', {
      namespaced: true,
      state: {
        testState: 'testValue'
      }
    })
  },
  created() {
    console.log("Created vue component. Value of id passed in by the URL is ", this.id)
    console.log("Computed value of testState:", this.testState)
  },
  computed: Vuex.mapState('page', ['testState']) //this means this.testState = store.state.page.testState which was registered in beforeCreate()
})
</script>

<style lang="sass">
  .test-component
    display: inline-block
    background-color: #ffffff
    width: 100%
    height: 100%
  .pie
    width: 100px
</style>