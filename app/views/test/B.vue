<style>
</style>
<template>
  <div>
    {{A}}
    <div @click="() => go()">go</div>
  </div>
</template>

<script>
  export default {
    data() {
      return {
        A: 'B'
}
},
    methods: {
      go() {
        application.router.navigate("/testa", {trigger: true})
}
},
    mounted() {

}
}
</script>