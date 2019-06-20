<template>
  <div>
    <slot></slot>
    <div id="layout-chrome">
      <img id="corner1" src="/images/ozaria/layout/chrome/Chrome_corner.png" />
      <img id="corner2" src="/images/ozaria/layout/chrome/Chrome_corner.png" />
      <img id="corner3" src="/images/ozaria/layout/chrome/Chrome_corner.png" />
      <img id="corner4" src="/images/ozaria/layout/chrome/Chrome_corner.png" />
      <img id="button-tray" src="/images/ozaria/layout/chrome/Chrome_buttontray.png" />
      <img id="btn-home" src="/images/ozaria/layout/chrome/Chrome_HomeButton.png" />
      <img id="btn-top" src="/images/ozaria/layout/chrome/Chrome_Button.png" />
      <img id="btn-bottom" src="/images/ozaria/layout/chrome/Chrome_Button.png" />
    </div>
  </div>
</template>

<style lang="sass">

#layout-chrome
  border-image: url('/images/ozaria/layout/chrome/Layout-Chrome.png')
  border-image-slice: 60 141 60 62 fill
  border-image-width: 28px 70px 27px 37px
  border-image-repeat: round
  width: 100%
  height: 100%
  position: fixed
  pointer-events: none
  z-index: 10

#corner1
  transform: rotate(180deg) scale(0.59) translate(66px, 38px)
  position: fixed

#corner2
  transform: scaleY(-1) scale(0.59) translate(66px, 37px)
  position: fixed
  top: 0
  right: 0

#corner3
  transform: scale(0.59) translate(66px, 38px)
  position: fixed
  bottom: 0
  right: 0

#corner4
  transform: scaleX(-1) scale(0.59) translate(66px, 38px)
  position: fixed
  bottom: 0
  left: 0

#button-tray
  position: fixed
  right: 0
  top: 50%
  transform: translate(14%, -50%) scale(0.8)

#btn-home
  position: fixed
  right: 0
  top: 50%
  transform: translate(0, -50%) scale(0.5)

#btn-top
  position: fixed
  right: 0
  top: 50%
  transform: translate(0, -50%) translate(-4px, -60px) scale(0.5)

#btn-bottom
  position: fixed
  right: 0
  top: 50%
  transform: translate(0, -50%) translate(-4px, 60px) scale(0.5)

</style>
