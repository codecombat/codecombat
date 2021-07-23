<template>
  <div class="container-fluid home-school-body">
    <div class="container">
      <div class="tabs">
        <div
          :class="['home-school', 'common-tab', 'selected-tab']"
        >
          <h2 class="title">Homeschooling</h2>
          <div>
            For at home learning groups with 5 or less kids
          </div>
        </div>
      </div>
      <div class="body-content text-center">
        <div class="purchase-widget same-row">
          <payment-student-license-purchase-component
            :price-info="priceInfo"
            :payment-group-id="paymentGroupId"
            :includes-text-array="includesText"
          />
        </div>
        <div class="online-classes-widget same-row">
          <payment-student-licenses-online-classes-component />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import PaymentStudentLicensePurchaseComponent from "./PaymentStudentLicensePurchaseComponent";
import PaymentStudentLicensesOnlineClassesComponent from "./PaymentStudentLicensesOnlineClassesComponent";
export default {
  name: "PaymentStudentLicenseHomeSchoolBodyComponent",
  components: {
    PaymentStudentLicensePurchaseComponent,
    PaymentStudentLicensesOnlineClassesComponent,
  },
  data() {
    return {
      includesText: [
        'Full access to CodeCombat and Ozaria',
        'Teacher Dashboard for record keeping and progress tracking',
        'Curriculum guide to help you understand what your child is learning and assist them',
      ],
    }
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
}
</script>

<style scoped lang="scss">
.home-school-body {
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
.selected-tab {
  border: 5px solid #1fbab4;
}
.purchase-widget {
  width: 35%;
  margin: auto;
  vertical-align: top;
}
.same-row {
  display: inline-block;
}
.online-classes-widget {
  width: 35%;
  background-color: white;
  vertical-align: top;
}
.body-content {
  padding-top: 20px;
}
</style>
