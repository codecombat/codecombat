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
    courseInstanceId: {
      type: String
    }
  }
}
</script>

<template>
<!-- Dummy UI -->
  <div>
    <h1>Draggable statement completion interactive</h1>
    <h2>{{ interactive.name }}</h2>
  </div>
</template>

<style scoped>

</style>
