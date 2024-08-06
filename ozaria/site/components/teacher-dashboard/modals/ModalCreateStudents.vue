<script>
import { mapGetters } from 'vuex'
import Modal from '../../common/Modal'

export default Vue.extend({
  components: {
    Modal,
  },
  props: {
    classroom: {
      type: Object,
      required: true
    }
  },
  data: () => {
    return {
      studentsNumber: 0
    }
  },
  computed: {
    ...mapGetters({
      // TODO: Almost certain this can be cut, but leaving in as this will be quickly merged
      // for HoC and there's no one around to review... :)
      selectedStudentIds: 'baseSingleClass/selectedStudentIds'
    }),
    showClassInfoModal () {
      return !this.showInviteStudentsModal
    },
    showGoogleClassroom () {
      return me.showGoogleClassroom() && (this.classroom.googleClassroomId || '').length > 0
    },
    modalTitle () {
      return 'Create Students'
    }
  },
  created () {
    if (!this.classroom) {
      console.error('Classroom not set')
      this.$emit('close')
    }
  },
  methods: {
    submit () {

    }
  }
})
</script>

<template>
  <modal
    :title="modalTitle"
    @close="$emit('close')"
  >
    <div class="style-ozaria teacher-form">
      <div class="form-container">
        <span class="sub-title">
          {{ $t('teachers.create_students_prompt') }}
        </span>
        <div class="form-group">
          <input
            v-modal="studentsNumber"
            type="number"
          >
          <button
            class="btn btn-primary"
            @click="submit"
          >
            {{ $t('play.confirm') }}
          </button>
        </div>
      </div>
    </div>
  </modal>
</template>
