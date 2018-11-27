<template lang="pug">
#modal-base-flat
  #hoc-completion-modal.modal-content.style-flat
    .modal-header
      span.glyphicon.glyphicon-remove.button.close(data-dismiss="modal", aria-hidden="true")
      h4 Congratulations on completing Hour of Code!
    .modal-body
        .row
          h5.headings Send your Code, Play, Share game to friends and family!
        .row
          .col-xs-8
            .form-group
              input.form-control#shareable(
                v-model="shareURL"
                type="text"
                readonly="readonly")
          .col-xs-4
            button.teacher-btn.btn.btn-primary.btn-block(v-on:click="copyShareURL") Copy URL
        .row
          h5.headings Get a certificate of completion to celebrate with your class!
        form(v-on:submit.prevent="getCertificate")
          template(v-if="!fullName")
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
                button.teacher-btn.btn.btn-primary.btn-lg.btn-block Get Certificate
            .row.teacher-email
              .col-xs-8
                input.form-control(
                  v-model.trim="teacherEmail"
                  type="email"
                  placeholder="Teacher's email address")
          template(v-else)
            .row
              .col-xs-12
                button.teacher-btn.btn.btn-primary.btn-lg.btn-block Get Certificate
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
    fullName: {
      type: String
    }
  },
  data: function() {
    return {
      firstName: "",
      lastInitial: "",
      teacherEmail: ""
    };
  },
  methods: {
    getCertificate: function(e) {
      this.navigateCertificate(this.name);
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
  },
  computed: {
    name: function() {
      return this.fullName || `${this.firstName} ${this.lastInitial}`;
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
    
    .headings
      font-family: Open Sans
      font-size: 18px

    .teacher-email
      margin-top: 10px
</style>
