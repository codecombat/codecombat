<template>
  <div class="tab" :class="{read: announcement.read}">
    <div class="title">
      {{announcement.name}}
    </div>
  </div>
</template>

<script>
  export default {
    name: 'announcement-tab',
    props: ['announcement']
  }
</script>

<style scoped>

  .tab {
    width: 80%;
    height: 60px;
    border: 1px solid black;
    border-radius: 20px;
  }

  .tab.read {
    background-color: #aaabbb;
    background-blend-mode: multiply;
  }

  .title {
    font-size: 24px;
    line-height: 60px;
    text-align: center;
  }

</style>