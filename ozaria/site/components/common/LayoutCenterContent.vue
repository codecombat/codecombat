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
    <div class="middle">
      <slot></slot>
    </div>
  </div>
</template>

<style lang="sass">
// Method for centering div:
// https://stackoverflow.com/questions/396145/how-to-vertically-center-a-div-for-all-browsers#6182661
#layout-center
  display: table
  position: absolute
  top: 0
  left: 0
  height: 100%
  width: 100%
  background-color: #F4E4AC
  background-size: 100%

.middle
  display: table-cell
  vertical-align: middle

</style>


