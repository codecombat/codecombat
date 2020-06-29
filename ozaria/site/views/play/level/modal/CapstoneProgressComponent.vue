<template>
  <div>
    <h1>Nice work!</h1>
    <p>For level: {{ levelSlug }}</p>
    <p>Stage: {{ capstoneStage }}</p>
    <p>Known goals left: {{ remainingGoals }}</p>
    <a :href="cinematicLink">Onwards!</a>
  </div>
</template>

<script>
  export default Vue.extend({
    name: 'CapstoneProgressModal',
    props: {
      levelSlug: {
        type: String,
        required: true
      },
      capstoneStage: {
        type: Number,
        required: true
      },
      remainingGoals: {
        type: Array,
        required: true
      }
    },
    computed: {
      cinematicLink: function () {
        if (this.levelSlug) {
          return `/cinematicplaceholder/${this.levelSlug}`
        } else {
          return ''
        }
      }
    }
  })
</script>

<style scoped>
  div {
    background-color: white;
  }
</style>
