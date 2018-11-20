<template lang="pug">
#modal-base-flat
  #hoc-completion-modal.modal-content.style-flat
    .modal-header
      span.glyphicon.glyphicon-remove.button.close(data-dismiss="modal", aria-hidden="true")
      h4 Congratulations on completing Hour of Code!
    .modal-body
      .row
        .col-xs-12
          h5 Send your Code, Play, Share game to friends and family!
      .row
        .col-xs-9.shareable
          input(type="text")
        .col-xs-3
          button Copy URL
      .row
        .col-xs-12
          h5 Get a certificate of completion to celebrate with your class!
      .row
        .col-xs-6
          
          input(type="text" placeholder="First Name")
          input(type="text" placeholder="Last Initial")
          input(type="email" placeholder="Teacher's email address")
        .col-xs-6
          button Get Certificate
</template>

<script>
module.exports = Vue.extend({
  // props: {
  //   // clickStudent: {
  //   //   type: Function,
  //   //   required: true
  //   // },
  //   // clickTeacher: {
  //   //   type: Function,
  //   //   required: true
  //   // },
  //   // showVideo: {
  //   //   type: Boolean
  //   // }
  // }
});
</script>

<style lang="sass">
@import "app/styles/style-flat-variables"

#hoc-completion-modal
  text-align: center
  border-width: 0px
  padding: 0
  padding-bottom: 0
  .hoc-video
    padding: 7px
  .modal-header
    background-color: $navy
    h4, span
      color: white

  .modal-body .buttons div p
    padding-top: 7px

</style>
