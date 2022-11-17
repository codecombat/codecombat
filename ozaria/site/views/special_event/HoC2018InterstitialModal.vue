<template lang="pug">
#modal-base-flat
  #hoc-interstitial-modal.modal-content.style-flat
    .modal-header
      span.glyphicon.glyphicon-remove.button.close(data-dismiss="modal", aria-hidden="true")
      h4(data-i18n="hoc_2018_interstitial.welcome")
    .modal-body
      .row(v-if="showVideo")
        .hoc-video
          <iframe width="560" height="315" src="https://www.youtube.com/embed/k965LUC7oww" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
      .row.buttons
        .col-xs-6
          button.btn.btn-lg.btn-navy(v-on:click="clickTeacher" data-i18n="hoc_2018_interstitial.educator")
          p(data-i18n="hoc_2018_interstitial.show_resources")
        .col-xs-6
          button.btn.btn-lg.btn-navy(v-on:click="clickStudent" data-i18n="hoc_2018_interstitial.student")
          p(data-i18n="hoc_2018_interstitial.ready_to_code")
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
    },
    showVideo: {
      type: Boolean
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
    h4, span
      color: white

  .modal-body .buttons div p
    padding-top: 7px

</style>
