<template>
  <div>
    <div class="form">
      <div class="form-group">
        <label
          class="required"
          for="studentName"
        >
          Student Name:
        </label>
        <input
          v-model="studentName"
          type="text"
          class="form-control"
        >
      </div>
      <div class="form-group">
        <label for="studentEmail">
          Student Email:
        </label>
        <input
          v-model="studentEmail"
          type="email"
          class="form-control"
        >
      </div>
      <div class="form-group">
        <label for="guardianName">
          Guardian Name:
        </label>
        <input
          v-model="guardianName"
          type="text"
          class="form-control"
        >
      </div>
      <div class="form-group">
        <label
          class="required"
          for="guardianEmail"
        >
          Guardian Email:
        </label>
        <input
          v-model="guardianEmail"
          type="email"
          class="form-control"
        >
      </div>
      <div class="form-group">
        <label for="guardianPhone">
          Guardian Cell Phone:
        </label>
        <input
          v-model="guardianPhone"
          type="tel"
          class="form-control"
        >
      </div>
      <div class="tips">
        <p>
          <!-- make it a checkbox -->
          Please confirm the booking by clicking on the link sent to the parent's email.
        </p>
      </div>

      <div class="buttons">
        <button
          class="btn btn-secondary"
          @click="back"
        >
          Back
        </button>
        <button
          class="btn btn-primary"
          @click="emitInfo"
        >
          Confirm
        </button>
      </div>
    </div>
  </div>
</template>
<script>
export default {
  name: 'StudentInfo',
  data () {
    return {
      studentName: '',
      studentEmail: '',
      guardianName: '',
      guardianEmail: '',
      guardianPhone: ''
    }
  },
  methods: {
    back () {
      this.$emit('back')
    },
    emitInfo () {
      this.$emit('change-student-info', {
        studentName: this.studentName,
        studentEmail: this.studentEmail,
        guardianName: this.guardianName,
        guardianEmail: this.guardianEmail,
        guardianPhone: this.guardianPhone
      })
    }
  }
}
</script>

<style lang="scss" scoped>
@import "common";
.buttons {
  display: flex;
  justify-content: space-between;
}
.tips {
  margin-top: 20px;
}
</style>
