<script>
  export default Vue.extend({
    props: {
      title: {
        type: String,
        required: true,
        default: ''
      }
    }
  })
</script>

<template>
  <div class="style-flat title-container">
    <p class="text-center text-capitalize title">
      {{ title }}
    </p>
  </div>
</template>

<style scoped>
.title-container{
  padding: 2%;
  position: absolute;
  min-width: 200px;
  top: 5%;
  left: 40%;
  z-index: 2;
  line-height: 10px;
}
.title{
  font-size: 1em;
  margin: 0;
}

</style>
