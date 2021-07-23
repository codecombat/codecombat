<template>
  <div class="container-fluid home-school-body">
    <div class="container">
      <div class="tabs">
        <div
          :class="['home-school', 'common-tab', 'selected-tab']"
        >
          <h2 class="title">HomeSchooling</h2>
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
          <div class="text-center learning">
            <img src="/images/pages/parents/personal_learning.png" class="learning-image" />
          </div>
          <div class="learning-text">
            <p class="bold">Online Classes Available</p>
            <p class="small">Combining the power of gameplay and personalized instruction, our live online classes deliver an experience your student will love.
            Our dedicated instructors offer individualized attention with a structured curriculum that teacher real Python and JavaScript. Try a 60 min trial class for free!</p>
          </div>
          <button type="button" class="btn btn-default more-info-btn" @click="moreInfo">More info</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import PaymentStudentLicensePurchaseComponent from "./PaymentStudentLicensePurchaseComponent";
export default {
  name: "PaymentStudentLicenseHomeSchoolBodyComponent",
  components: {
    PaymentStudentLicensePurchaseComponent,
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
  methods: {
    moreInfo() {
      window.open('https://codecombat.com/parents', '_blank')
    },
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
  padding-top: 20px;
  width: 35%;
  margin: auto;
}
.same-row {
  display: inline-block;
}
.online-classes-widget {
  width: 36%;
  background-color: white;
  padding: 10px;
}
.learning {
  width: 60%;
  display: table-cell;
}
.learning-image {
  max-width: 100%;
  max-height: 100%;
  width: 65%;
}
.small {
  font-size: small;
  color: grey;
  margin-bottom: 5px;
}
.bold {
  font-weight: bold;
}
.learning-text {
  padding-top: 15px;
}
.more-info-btn {
  font-weight: bold;
  border: 1px solid black;
}
</style>
