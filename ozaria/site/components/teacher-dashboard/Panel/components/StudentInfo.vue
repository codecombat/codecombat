<script>
  export default {
    props: {
      name: {
        type: String,
        required: true
      },
      completed: {
        type: String,
        default: ''
      }
    }
  }
</script>
<template>
  <div id="student-info">
    <p>{{ name }}</p>
    <span v-if="completed">Completed: {{ completed }}</span>
  </div>
</template>

<style lang="scss" scoped>
  @import "app/styles/bootstrap/variables";
  @import "ozaria/site/styles/common/variables.scss";
  @import "app/styles/ozaria/_ozaria-style-params.scss";

  #student-info {
    height: 35px;
    width: 100%;

    display: flex;
    flex-direction: row;

    justify-content: space-between;
    align-items: center;

    padding: 0 20px;

    background-color: #dee8ef;

    p {
      @include font-p-3-paragraph-small-gray;
      color: #131b25;
      margin: 0;
    }

    span {
      @include font-p-5-fine-print;
      color: #131b25;
    }
  }
</style>
