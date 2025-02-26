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
      studentsNumber: null,
      successMsg: ''
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
      classroomAPI.createStudentsForCodeNinja({ classroomID: this.classroom._id, num: this.studentsNumber })
        .then(response => {
          const students = response.userLogin
          let csvContent = 'userName,password\n'
          for (const student of students) {
            csvContent += `${student.name},${student.password}\n`
          }
          const file = new Blob([csvContent], { type: 'text/csv;charset=utf-8' })
          const filename = `StudentsCredentials-${this.classroom.name}-${Date.now()}.csv`

          // Create temporary link element to trigger download
          const link = document.createElement('a')
          link.href = URL.createObjectURL(file)
          link.download = filename
          document.body.appendChild(link)
          link.click()
          document.body.removeChild(link)
          URL.revokeObjectURL(link.href)

          this.successMsg = `Students credentials downloaded in ${filename}`
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
  <div class="create-students-modal">
    <div class="form-container">
      <p class="form-label">
        Create Students
      </p>
      <div class="form-group">
        <div class="form-input">
          <input
            v-model="studentsNumber"
            type="number"
            :placeholder="$t('teachers.create_students_prompt')"
            class="form-control"
          >
        </div>
        <span class="sub-text">
          students login credentials would be downloaded in a CSV file
        </span>
        <primary-button
          class="submit-button"
          @click="submit"
        >
          {{ $t('common.create') }}
        </primary-button>
        <div
          v-if="successMsg"
          class="success-msg sub-text"
        >
          <p>
            {{ successMsg }}
          </p>
          <p>
            Refresh the page to see the students in the class.
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/ozaria/_ozaria-style-params.scss";

.create-students-modal {
  margin-top: 20px;
}

.form-label {
  @include font-h-4-nav-uppercase-black;
  text-align: left;
}

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

.success-msg {
  color: green;
  margin-top: 10px;

  p {
    color: inherit;
  }
}
</style>