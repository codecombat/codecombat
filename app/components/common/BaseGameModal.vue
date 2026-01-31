<script>
import BaseModalContainer from './BaseModalContainer'

export default {
  components: {
    BaseModalContainer,
  },
  props: {
    backboneDismissModal: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    backboneClose () {
      return this.backboneDismissModal ? 'modal' : undefined
    },
    vueClose () {
      return !this.backboneDismissModal ? 'click' : null
    },
  },
}
</script>

<template>
  <base-modal-container
    class="modal"
    @dismiss="$emit('close')"
  >
    <div class="game-modal-content">
      <div class="modal-header">
        <slot name="header" />
        <div
          class="close-button"
          :data-dismiss="backboneClose"
          @[vueClose]="$emit('close')"
        >
          <span class="glyphicon glyphicon-remove" />
        </div>
      </div>
      <div class="modal-body">
        <slot name="body" />
      </div>
      <div class="modal-footer">
        <slot name="footer" />
      </div>
    </div>
  </base-modal-container>
</template>

<style lang="sass" scoped>
  .modal
    align-items: flex-start
    ::v-deep .modal-container
       width: 746px
       height: 520px
       background: unset

    ::v-deep .container
       width: 100%
       height: 100%

       padding: 25px
       border-radius: 10px
    ::v-deep .background
       z-index: -999
       position: absolute
       top: -61px
       left: 0
    .close-button
      position: absolute
      left: 568px
      top: 17px
      width: 60px
      height: 60px
      color: white
      text-align: center
      font-size: 30px
      padding-top: 15px
      cursor: pointer
      transform: rotate(-3deg)

      &:hover
        color: yellow

  .game-modal-content
    width: 100%
    height: 100%
    display: flex
    justify-content: center
    align-items: center
    flex-direction: column

    .modal-header, .modal-body, .modal-footer
      display: flex
      flex-direction: column
      justify-content: center
      align-items: center
      width: inherit
      padding: 5px

    .modal-header
      font-weight: bold
      font-size: 30px
      position: relative

    .modal-body
      font-size: 20px
      flex-grow: 1
      padding-top: 30px
      padding-left: 40px
      padding-right: 40px
</style>
