<script>
  import Panel from '../Panel/index.vue'
  export default {
    components: {
      Panel
    },
    metaInfo () {
      return {
        title: 'ADMIN ONLY - Teacher Dashboard'
      }
    }
  }
</script>

<template>
  <div>
    <panel />
    <router-view></router-view>
  </div>
</template>
