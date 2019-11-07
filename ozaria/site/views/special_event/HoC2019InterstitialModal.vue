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
  })
</script>

<template lang="pug">
#modal-base-flat
  #hoc-interstitial-modal.modal-content.style-flat
    .modal-header
      span.glyphicon.glyphicon-remove.button.close(v-on:click="$emit('close')", aria-hidden="true")
      h4 {{ $t("hoc_2018_interstitial.ozaria_hoc_welcome") }}
    .modal-body
      .row(v-if="showVideo")
        .hoc-video
          <iframe width=100% height=100% src="https://www.youtube.com/embed/prJJvvI3WJM" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
      .row.buttons
        .col-xs-6
          button.btn.btn-lg.btn-navy(v-on:click="clickTeacher") {{ $t("hoc_2018_interstitial.educator") }}
          p {{ $t("hoc_2018_interstitial.show_resources") }}
        .col-xs-6
          button.btn.btn-lg.btn-navy(v-on:click="clickStudent") {{ $t("hoc_2018_interstitial.student") }}
          p {{ $t("hoc_2018_interstitial.ready_to_code") }}
</template>

<style lang="sass">
@import "app/styles/style-flat-variables"

#hoc-interstitial-modal
  text-align: center
  border-width: 0px
  padding: 0
  padding-bottom: 0
  .hoc-video
    padding: 7px
    max-width: 560px
    height: 315px
    margin: auto
  .modal-header
    background-color: $navy
    h4, span
      color: white

  .modal-body .buttons div p
    padding-top: 7px
  .buttons
    padding-top: 10px

</style>
