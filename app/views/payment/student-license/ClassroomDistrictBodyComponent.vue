<template>
  <div class="container-fluid classroom-district-body">
    <div class="container">
      <div class="tabs">
        <div
          :class="['classroom', 'common-tab', (isSmallClassroomSelected ? 'selected-tab' : 'unselected-tab')]"
          @click="() => setClassroomSelected(true)"
        >
          <h2 class="title">Small Classroom</h2>
          <div>
            For clubs, after-school programs and small classrooms with 5-9 students
          </div>
        </div>
        <div
          :class="['district', 'common-tab', (!isSmallClassroomSelected ? 'selected-tab' : 'unselected-tab')]"
          @click="() => setClassroomSelected(false)"
        >
          <h2 class="title">Schools & Districts</h2>
          <div>
            For classrooms, schools and districts with 10 or more students
          </div>
        </div>
      </div>
      <payment-school-district-body-view
        v-if="!isSmallClassroomSelected"
      />
      <payment-small-classroom-body-view
        v-if="isSmallClassroomSelected"
        :price-info="priceInfo"
        :payment-group-id="paymentGroupId"
      />
    </div>
  </div>
</template>

<script>
import PaymentSchoolDistrictBodyView from "./SchoolDistrictBodyView";
import PaymentSmallClassroomBodyView from "./SmallClassroomBodyView";
export default {
  name: "PaymentStudentLicenseClassroomDistrictBodyComponent",
  components: {
    PaymentSchoolDistrictBodyView,
    PaymentSmallClassroomBodyView,
  },
  props: {
    priceInfo: {
      type: Object,
      required: true,
    },
    paymentGroupId: {
      type: String,
      required: true,
    }
  },
  data() {
    return {
      isSmallClassroomSelected: false,
    }
  },
  methods: {
    setClassroomSelected(value) {
      this.isSmallClassroomSelected = value
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
  margin-left: 4%;
}
.classroom {
  margin-right: 4%;
}
.selected-tab {
  border: 10px solid #1fbab4;
}
.unselected-tab {
  box-shadow: 0px 2px 4px rgba(0, 0, 0, 0.5);
}
.unselected-tab:hover {
  border: 5px solid #c4e5e4;
}
</style>
