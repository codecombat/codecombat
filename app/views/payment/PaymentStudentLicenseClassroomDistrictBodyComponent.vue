<template>
  <div class="container-fluid classroom-district-body">
    <div class="container">
      <div class="tabs center">
        <div
          :class="['classroom', 'common-tab', (isClassroomSelected ? 'selected-tab' : 'unselected-tab')]"
          @click="() => setClassroomSelected(true)"
        >
          <h2 class="title">Small Classroom</h2>
          <div>
            For clubs, after-school programs and small classrooms with 5-9 students
          </div>
        </div>
        <div
          :class="['district', 'common-tab', (!isClassroomSelected ? 'selected-tab' : 'unselected-tab')]"
          @click="() => setClassroomSelected(false)"
        >
          <h2 class="title">Schools & Districts</h2>
          <div>
            For classrooms, schools and districts with over 10 students and test
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: "PaymentStudentLicenseClassroomDistrictBodyComponent",
  data() {
    return {
      isClassroomSelected: true,
    }
  },
  methods: {
    setClassroomSelected(value) {
      this.isClassroomSelected = value
    },
  }
}
</script>

<style scoped lang="scss">
.classroom-district-body {
  background-color: aliceblue;
  padding-top: 20px;
  padding-bottom: 10px;
}
.tabs {
  text-align: center;
}
.common-tab {
  display: inline-block;
  width: 30%;
  padding-top: 50px;
  padding-bottom: 50px;
  background-color: white;
  border-radius: 16px;
  box-shadow: 0px 2px 4px rgba(0, 0, 0, 0.5);
  cursor: pointer;
}
.title {
  color: #1FBAB4;
}
.district {
  margin-left: 10px;
}
.selected-tab {
  border: 5px solid #1fbab4;
}
.unselected-tab {
  border: 5px solid #c4e5e4;
}
</style>
