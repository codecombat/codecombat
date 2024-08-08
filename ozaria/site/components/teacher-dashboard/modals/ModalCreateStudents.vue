<script>
import PrimaryButton from '../common/buttons/PrimaryButton'
import classroomAPI from 'app/core/api/classrooms'
export default Vue.extend({
  components: {
    PrimaryButton
  },
  props: {
    classroom: {
      type: Object,
      required: true
    }
  },
  data: () => {
    return {
      studentsNumber: 1
    }
  },
  computed: {
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
      classroomAPI.createStudents({ classroomID: this.classroom.id, num: this.studentsNumber })
        .then(response => {
          const students = response.data.userLogin
          let csvContent = 'userName,password\n'
          for (const student of students) {
            csvContent += `${student.name},${student.password}\n`
          }
          const file = new Blob([csvContent], { type: 'text/csv;charset=utf-8' })
          window.saveAs(file, 'StudentsLoginCredentials.csv')
          this.$emit('close')
        })
        .catch(error => {
          console.error(error)
          this.$emit('close')
        })
    }
  }
})
</script>

<template>
  <div class="style-ozaria teacher-form">
    <div class="form-container">
      <span class="sub-title">
        {{ $t('teachers.create_students_prompt') }}
      </span>
      <div class="form-group">
        <div class="form-input">
          <input
            v-model="studentsNumber"
            type="number"
          >
        </div>
        <span class="sub-text">
          students login credentials would be downloaded in a CSV file
        </span>
        <primary-button
          class="submit-button"
          @click="submit"
        >
          {{ $t('play.confirm') }}
        </primary-button>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/ozaria/_ozaria-style-params.scss";

.sub-title {
  @include font-p-2-paragraph-medium-gray;
}

.sub-text {
  @include font-p-4-paragraph-smallest-gray;
}

.submit-button {
  display: block;
  width: 190px;
  height: 35px;
  margin-top: 20px;
}
</style>