<template lang="pug">
.bg
  .modal-dialog
    .modal-content
      img#subscribe-background(src="/images/pages/play/modal/announcement_modal_bg.png")
      block title
        h1 {{announcement.name}}
      block content
        .markdown(v-html="content")
    #close-modal(@click="$emit('close')")
      span.glyphicon.glyphicon-remove
</template>

<script>
import DOMPurify from 'dompurify';

export default Vue.extend({
    name: 'announcement-modal',
    props: ['announcement'],
    computed: {
      content (){
        return DOMPurify.sanitize(marked(this.announcement.content))
      }
    }
})
</script>

<styple lang="sass" scoped>
  .bg
    position: absolute
    width: 100%

  .modal-dialog
    margin: 60px auto 0 auto
    padding: 0
    width: 746px
    height: 520px
    background: none

    .modal-content
      box-shadow: none
      height: 520px

      .markdown
        position: absolute
        top: 120px
        padding: 0 50px

    //- Background
    #subscribe-background
      position: absolute
      top: -61px
      left: 0px

    //- Header
    h1
      position: absolute
      left: 170px
      top: 25px
      margin: 0
      width: 410px
      text-align: center
      color: rgb(254,188,68)
      font-size: 38px
      text-shadow: black 4px 4px 0, black -4px -4px 0, black 4px -4px 0, black -4px 4px 0, black 4px 0px 0, black 0px -4px 0, black -4px 0px 0, black 0px 4px 0, black 6px 6px 6px
      font-variant: normal
      text-transform: uppercase


    //- Close modal button
    #close-modal
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

      &:hover
        color: yellow
</styple>
