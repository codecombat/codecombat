<script>
export default {
  props: {
    backgroundImage: {
      type: String,
      default: "/images/ozaria/cinematic/background.png"
    }
  }
}
</script>


<template>
  <div id="layout-center" :style="{ 'background-image': 'url(' + backgroundImage + ')' }">
    <slot></slot>
  </div>
</template>

<style lang="sass">
// Method for centering div:
// https://stackoverflow.com/questions/396145/how-to-vertically-center-a-div-for-all-browsers#6182661
#layout-center
  height: 100%
  width: 100%
  background-color: #F4E4AC
  background-size: 100%

  display: flex
  flex-direction: column

  align-items: center
  justify-content: center

</style>


