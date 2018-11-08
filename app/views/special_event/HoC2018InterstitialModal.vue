<template lang="jade">
#hoc-interstitial-modal.modal-content.style-flat
  .modal-header
    span.glyphicon.glyphicon-remove.button.close(data-dismiss="modal", aria-hidden="true")
    h3 Welcome to CodeCombat's Hour of Code 2018!
  .modal-body
    .row
      h3 What's inside?
      .hoc-video
        <iframe width="560" height="315" src="https://www.youtube.com/embed/SzZiOkZ-vRk" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
    .row.buttons
      .col-xs-6
        button.btn.btn-lg.btn-navy(v-on:click="clickTeacher") I'm an educator
        p Show me teacher resources!
      .col-xs-6
        button.btn.btn-lg.btn-navy(v-on:click="clickStudent") I'm a student
        p I'm ready to code!
</template>

<script>
module.exports = Vue.extend({
  props: {
    clickStudent: {
      type: Function,
      required: true
    },
    clickTeacher: {
      type: Function,
      required: true
    }
  }
});
</script>

<style lang="sass">
@import "app/styles/style-flat-variables"

#hoc-interstitial-modal
  text-align: center
  border-width: 0px
  padding: 0
  padding-bottom: 0
  .hoc-video
    padding: 7px
  .modal-header
    background-color: $navy
    h3, span
      color: white

  .modal-body .buttons div p
    padding-top: 7px

</style>
