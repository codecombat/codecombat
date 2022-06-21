<template>
  <div>
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

<style>
</style>