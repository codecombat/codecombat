
<script>
import ButtonImportClassroom from './ButtonImportClassroom'
export default Vue.extend({
  name: 'ButtonGoogleClassroom',
  components: {
    ButtonImportClassroom
  },
  props: {
    inactive: {
      type: Boolean,
      default: false
    },
    inProgress: {
      type: Boolean,
      default: false
    },
    text: {
      type: String,
      required: true,
      default: 'Link Google Classroom'
    },
  }
})
</script>

<template>
  <ButtonImportClassroom
    :inactive="inactive"
    :in-progress="inProgress"
    :text="text"
    :inactive-message="$t('teachers.google_classroom_disabled_text')"
    icon-src="/images/ozaria/teachers/dashboard/svg_icons/IconGoogleClassroom.svg"
    icon-src-inactive="/images/ozaria/teachers/dashboard/svg_icons/IconGoogleClassroom_inactive.svg"
    @click="$emit('click')"
  />
</template>
