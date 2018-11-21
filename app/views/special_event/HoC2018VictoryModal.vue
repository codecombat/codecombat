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
          .col-xs-8
            .form-group
              input.form-control#shareable(
                v-model="shareURL"
                type="text"
                readonly="readonly")
          .col-xs-4
            button.btn-block.btn-navy(v-on:click="copyShareURL") Copy URL
        .row
          .col-xs-12
            h5 Get a certificate of completion to celebrate with your class!
        form(v-on:submit.prevent="getCertificate")
          .row
            .col-xs-5
              input.form-control(
                v-model.trim="firstName"
                type="text"
                placeholder="First Name"
                required)
            .col-xs-3
              input.form-control(
                v-model.trim="lastInitial"
                type="text"
                placeholder="Last Initial"
                maxlength="1"
                dir="auto"
                required)
            .col-xs-4
              button.btn-block.btn-navy Get Certificate
          .row
            .col-xs-8
              input.form-control(
                v-model.trim="teacherEmail"
                type="email"
                placeholder="Teacher's email address")
</template>

<script>
module.exports = Vue.extend({
  props: {
    navigateCertificate: {
      type: Function,
      required: true
    },
    shareURL: {
      type: String,
      required: true
    },
  },
  data: function() {
    return {
      firstName: "",
      lastInitial: "",
      teacherEmail: "",
    };
  },
  methods: {
    getCertificate: function(e) {
      alert(`${this.firstName} - ${this.lastInitial}`);
      this.navigateCertificate();
    },
    copyShareURL: function() {
      document.querySelector("#shareable").select();
      try {
        document.execCommand("copy");
      } catch (err) {
        message = "Oops, unable to copy";
        noty({
          text: message,
          layout: "topCenter",
          type: "error",
          killer: false
        });
      }
    }
  }
});
</script>

<style lang="sass">
@import "app/styles/style-flat-variables"

#hoc-completion-modal
  text-align: center
  border-width: 0px
  padding: 0
  padding-bottom: 0
  .modal-header
    background-color: $navy
    h5
      margin-top: 7px
      margin-bottom: 7px
    h4, span
      color: white
  .modal-body
    .buttons div p
      padding-top: 7px

</style>
