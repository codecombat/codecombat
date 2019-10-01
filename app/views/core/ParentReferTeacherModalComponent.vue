<template lang="pug">

#refer-teacher-modal.modal-content.style-flat
  .modal-header
    span.glyphicon.glyphicon-remove.button.close(data-dismiss="modal", aria-hidden="true")
    h3(data-i18n="parent_modal.refer_teacher")

  form.modal-body
    .form-group
      label.control-label.text-h4(for="parent-name")
        span(data-i18n="parent_modal.name")
      input.form-control.input-lg(type="text" name="parent-name" required autocomplete="parent-name")
    .form-group
      label.control-label.text-h4(for="parent-email")
        span(data-i18n="parent_modal.parent_email")
      input.form-control.input-lg(type="email" name="parent-email" required autocomplete="parent-email")
    .form-group
      label.control-label.text-h4(for="teacher-email")
        span(data-i18n="parent_modal.teacher_email")
      input.form-control.input-lg(type="email" name="teacher-email" required autocomplete="teacher-email")
    .form-group
      label.control-label.text-h4(for="custom-content")
        span(data-i18n="parent_modal.message")
      textarea#custom-content.form-control(type="text" name="custom-content" rows=6 required autocomplete="custom-content", data-i18n="parent_modal.custom_message")

    .row.footer-btn
      button.send-teacher-email-button.btn.btn-lg.btn-navy(input="Submit")
        span(data-i18n="parent_modal.send")
      img.pull-right(src="/images/pages/parents/anya_reading.png")

</template>

<script lang="coffee">
module.exports = Vue.extend({
})
</script>


<style lang="sass">
@import "app/styles/style-flat-variables"
#refer-teacher-modal
  border-width: 0px
  padding: 0
  padding-bottom: 0

  .modal-header
    background-color: $navy
    text-align: center
    h3, span
      color: white
      
  .footer-btn
    position: relative
    button
      position: absolute
      bottom: 0
      left: 0
      margin: 20px
</style>