<script>
  import { mapGetters, mapActions, mapMutations } from 'vuex'
  import Modal from '../../common/Modal'
  import SecondaryButton from '../common/buttons/SecondaryButton'
  import TertiaryButton from '../common/buttons/TertiaryButton'

  export default Vue.extend({
    components: {
      Modal,
      SecondaryButton,
      TertiaryButton
    },

    computed: {
      ...mapGetters({
        classroom: 'teacherDashboard/getCurrentClassroom',
        selectedStudentIds: 'baseSingleClass/selectedStudentIds'
      })
    },

    created () {
      if (!Array.isArray(this.selectedStudentIds) || this.selectedStudentIds.length === 0) {
        noty({ text: `You need to select student(s) first before performing that action.`, layout: 'center', type: 'information', killer: true, timeout: 8000 })
        this.$emit('close')
      }
      if (!this.classroom) {
        console.error('Classroom not set')
        this.$emit('close')
      }
    },

    methods: {
      ...mapActions({
        removeMembersFromClassroom: 'classrooms/removeMembersFromClassroom'
      }),
      ...mapMutations({
        clearSelectedStudents: 'baseSingleClass/clearSelectedStudents'
      }),
      async removeStudents () {
        await this.removeMembersFromClassroom({ classroom: this.classroom, memberIds: this.selectedStudentIds })
        this.clearSelectedStudents()
        this.$emit('close')
      }
    }
  })
</script>

<template>
  <modal
    title="Remove Students from Class"
    @close="$emit('close')"
  >
    <div class="remove-students">
      <div class="remove-students-info">
        <span class="sub-title"> Are you sure you want to remove (this student / these students) from your class? </span>
        <ul class="info-list">
          <li class="list-item"> If licenses are applied, remember to revoke them before removing students in order to apply them to other students. </li>
          <li class="list-item"> Student(s) will lose access to this classroom and assigned chapters. </li>
          <li class="list-item"> Student progress will not be lost and can be viewed if the student can be added back to the classroom at any time. </li>
        </ul>
      </div>
      <div class="buttons">
        <tertiary-button
          @click="$emit('close')"
        >
          {{ $t("common.cancel") }}
        </tertiary-button>
        <secondary-button
          @click="removeStudents"
        >
          {{ $t("common.remove") }}
        </secondary-button>
      </div>
    </div>
  </modal>
</template>

<style lang="scss" scoped>
@import "app/styles/ozaria/_ozaria-style-params.scss";

.remove-students {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  margin: 20px;
  width: 600px;
}

.remove-students-info {
  margin-bottom: 170px;
  margin-left: 30px;
}

.sub-title {
  @include font-p-2-paragraph-medium-gray;
  font-weight: 600;
}

.info-list {
  margin: 30px -20px;
}

.list-item {
  @include font-p-3-paragraph-small-gray;
  margin: 15px 0px;
}

.buttons {
  align-self: flex-end;
  display: flex;
  margin-top: 30px;

  button {
    width: 150px;
    height: 35px;
    margin: 0 10px;
  }
}

</style>
