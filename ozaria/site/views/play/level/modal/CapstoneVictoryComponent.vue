<template>
  <div>
    <h1>All done! Much victory, very celebration!</h1>
    <p>For level: {{ levelSlug }}</p>
    <p>Stage: {{ capstoneStage }}</p>
    <a :href="cinematicLink">Celebrate!</a>
  </div>
</template>

<script>
  export default Vue.extend({
    name: 'CapstoneVictoryModal',
    props: {
      levelSlug: {
        type: String,
        required: true
      },
      capstoneStage: {
        type: Number,
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
