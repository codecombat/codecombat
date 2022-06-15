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
        A: 'A'
}
},
    methods: {
      go() {
        application.router.navigate("/testb", {trigger: true})
}
},
    mounted() {

}
}
</script>