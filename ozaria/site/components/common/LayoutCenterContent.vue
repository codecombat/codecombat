<template>
  <div id="layout-center">
    <slot></slot>
  </div>
</template>

<style lang="sass">

#layout-center
  height: 100%
  width: 100%
  background-size: 100%

  display: flex
  flex-direction: column

  align-items: center
  justify-content: center

@media only screen and (min-device-width: 481px) and (max-device-width: 1024px) and (orientation:portrait)
  // On ipad or smaller devices shifts view to top making space for the virtual keyboard.
  #layout-center
    justify-content: flex-start
    padding-top: 30px

</style>
