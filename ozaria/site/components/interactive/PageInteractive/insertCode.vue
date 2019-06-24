<script>
export default {
   props: {
    interactive: {
      type: Object,
      required: true,
      default: {}
    },
    introLevelId: {
      type: String,
      required: true,
      default: ''
    },
    interactiveSession: {
      type: Object
    },
    codeLanguage: {
      type: String
    }
  }
}
</script>

<template>
<!-- Dummy UI -->
  <div>
    <h1>Insert code interactive</h1>
    <h2>{{ interactive.name }}</h2>
  </div>
</template>

<style scoped>

</style>
