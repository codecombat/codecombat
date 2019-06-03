<template>
  <div>
    <slot></slot>
    <div id="layout-chrome"></div>
  </div>
</template>

<style lang="sass">

#layout-chrome
  border-image: url('/images/ozaria/layout/Layout-Chrome.png')
  border-image-slice: 30 70 30 30 fill
  border-image-width: 30px 70px 30px 30px
  border-image-repeat: round
  width: 100%
  height: 100%
  position: fixed

</style>
