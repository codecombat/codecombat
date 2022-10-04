<script>
  const fetchJson = require("../../../core/api/fetch-json")
  export default Vue.extend({
    props: ['hide'],
    data() {
     return {
       hours: 0,
       pending: 10,
     }
    },
    methods: {
      submit: async function(){
        await fetchJson('/admin/maintenance-time', {json: {hours: this.hours}, method: 'POST' })
      },
      countDown () {
        this.pending -= 1
        if(this.pending) {
          setTimeout(this.countDown, 1000)
        }
      }
    },
    mounted() {
      this.pending = 10
      this.countDown()
    }
  })
</script>
<template lang="pug">
#modal-base-flat
  .body
    .alert
      p MAINTENANCE MODE MAKES CODECOMBAT INACCESSIBLE!
      p MAINTENANCE MODE MAKES CODECOMBAT INACCESSIBLE!
      p MAINTENANCE MODE MAKES CODECOMBAT INACCESSIBLE!
      p ARE YOU SURE YOU WANT TO CONTINUE ?
    .input
      p if you're not sure, ask the #eng in slack
      p set the maintenance hours:
      div
        input(type="number", v-model="hours", min="0", step="0.1")
        span Hours
      br
      .buttons
        a.btn.btn-danger.btn-lg(@click="submit" :class="{disabled: pending}") I'm Sure, Go Ahead!
          span(v-if="pending") ({{pending}})
        a.btn.btn-primary.btn-lg(@click="hide") I dunno
</template>

<style scoped lang="scss">
  .body {
    width: 800px;
    margin-left: -100px;
    background: #F4FAFF;
    box-shadow: 2px 2px 2px 2px #777;
    padding: 5px;
    font-size: 18px;
  }
  .alert {
    background: #fac748;
    color: red;
    font-size: 24px;
    border-radius: 10px;
    text-align: center;
  }
  .input {
    display: flex;
    flex-direction: column;
    align-items: center;
  }
  .buttons {
    width: 600px;
    display: flex;
    justify-content: space-between;
  }
</style>