<script>
  export default {
    props: {
      interactiveTitle: {
        type: String,
        required: true
      }
    }
  }
</script>

<template>
  <div class="title-container">
    {{ interactiveTitle }}
  </div>
</template>

<style scoped>
  .title-container {
    padding: 30px;
    margin-bottom: 20px;

    width: 100%;

    border: 1px solid black;

    text-align: center;

    font-size: 30px;
    line-height: 30px;
  }
</style>
