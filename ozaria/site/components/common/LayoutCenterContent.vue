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

</style>


