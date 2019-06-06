<template>
  <div id="layout-center-cinematic">
    <div class="middle">
      <slot></slot>
    </div>
  </div>
</template>

<style lang="sass">
// Method for centering div:
// https://stackoverflow.com/questions/396145/how-to-vertically-center-a-div-for-all-browsers#6182661
#layout-center-cinematic
  display: table
  position: absolute
  top: 0
  left: 0
  height: 100%
  width: 100%
  background-image: url("/images/ozaria/cinematic/background.png")
  background-color: #F4E4AC
  background-size: 100%

.middle
  display: table-cell
  vertical-align: middle

</style>


