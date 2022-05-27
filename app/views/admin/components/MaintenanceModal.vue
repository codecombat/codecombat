<script>
  export default Vue.extend({
    data() {
     return {
       hour: 1,
     }
    },
    methods: {
      submit: async function(){
        await fetch('/admin/maintenance-time', {
          method: 'POST',
          body: JSON.stringify({hour: this.hour}),
          headers: {'Content-Type': 'application/json'}
        })
      }
    }
  })
</script>
<template lang="pug">
#modal-base-flat
  .body
    .alert
      p MAINTENANCE MODE MAKES WEBSITE UNVISITABLE!
      p MAINTENANCE MODE MAKES WEBSITE UNVISITABLE!
      p MAINTENANCE MODE MAKES WEBSITE UNVISITABLE!
      p ARE YOU SURE TO CONTINUE ?
    .input
      p set the maintenance hour:
      div
        input(type="number", v-model="hour", min="0.1", step="0.1")
        span Hours
      br
      a.btn.btn-primary.btn-lg(@click="submit") I'm Sure, Go Ahead!
</template>

<style scoped lang="scss">
  .body {
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
</style>