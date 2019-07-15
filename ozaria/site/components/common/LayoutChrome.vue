<script>
export default {
  props: {
    title: {
      type: String,
      required: false,
    },
    chromeOn: {
      type: Boolean,
      required: false,
      default: false
    }
  }
}
</script>

<template>
  <div>
    <slot></slot>
    <div
      id="layout-chrome"
      :class="[chromeOn ? 'chrome-on-slice' : 'chrome-off-slice']"
      >
      <img id="btn-home" src="/images/ozaria/layout/chrome/Chrome_HomeButton.png" />
      <img id="btn-top" src="/images/ozaria/layout/chrome/Chrome_Button.png" />
      <img id="btn-bottom" src="/images/ozaria/layout/chrome/Chrome_Button.png" />
      <div :class="[chromeOn ? 'side-center-on' : 'side-center-off']"></div>
      <div v-if="title">
        <div id="text-tab">
          <div class='text-contents'>
            <span>{{ title }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style lang="sass">

#layout-chrome
  width: 100%
  height: 100%
  position: fixed
  pointer-events: none
  z-index: 10

  &.chrome-on-slice
    border-image: url('/images/ozaria/layout/chrome/Layout-Chrome-on.png')

  &.chrome-off-slice
    border-image: url('/images/ozaria/layout/chrome/Layout-Chrome-off.png')

  &.chrome-off-slice, &.chrome-on-slice
    border-image-slice: 182 194 130 118 fill
    border-image-width: 140px 140px 105px 106px
    border-image-repeat: round

  .side-center-on
    background: url(/images/ozaria/layout/chrome/central_on.png)

  .side-center-off
    background: url(/images/ozaria/layout/chrome/central_off.png)

  .side-center-off, .side-center-on
    width: 67px
    height: 100%
    overflow: hidden
    position: fixed
    right: 0
    background-position: center
    background-size: contain
    background-repeat: no-repeat

  #text-tab
    background: url(/images/ozaria/layout/chrome/Tab-Title.png)
    background-position-x: center
    background-repeat: no-repeat

    .text-contents
      text-align: center
      color: #48FAFC
      padding: 12px 0
      height: 30px

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
