<template>
  <div class="school-district-body">
    <div class="column pd-training">
      <div class="pd">
        <div class="info">
          <p class="heading">Professional Development Available</p>
          <p class="small-text">
            Comprehensive 40-hour online course that allows you to learn anytime, anywhere and at any pace. It provides teachers of all experience levels with the skills knowledge and confidence to teach computer science.
          </p>
        </div>
        <button type="button" class="btn btn-default btn-lg more-info-btn" @click="moreInfo">More info</button>
      </div>
      <div class="training">
        <div class="info">
          <p class="heading">Implementation Training Options</p>
          <p class="small-text">
            Educators can be provided with a 60 min Onboarding Training and guidance on how to use CodeCombat or Ozaria to support specific institutional and instructional goals. Contact us for more information and pricing.
          </p>
        </div>
        <button type="button" class="btn btn-primary btn-lg contact-us-btn" @click="showImplementationModal">Contact Us</button>
      </div>
    </div>
    <div class="column quote-column">
      <div class="request-quote">
        <div class="info">
          <p class="heading">Bulk Discounts Available</p>
          <p class="small-text">Minimum 10 licenses</p>
        </div>
        <button type="button" class="btn btn-success btn-lg" @click="showLicenseModal">Request a Quote</button>
        <div class="feature-list">
          <p class="include">Includes</p>
          <ul>
            <li>Full access to CodeCombat and Ozaria</li>
            <li>Dedicated school success manager available via phone or email for implementation support</li>
            <li>Technical support via email or chat</li>
            <li>Purchase order plus other payment options available</li>
            <li>Administrator dashboard with actionable data and insights</li>
            <li>Site licenses, bulk discounts and multi-year discounts available</li>
          </ul>
        </div>
      </div>
    </div>
    <modal-get-licenses
      v-if="openLicenseModal"
      @close="openLicenseModal = false"
    />
    <modal-get-licenses
      email-message="Hi! I want to learn more about options for educators training on how to use CodeCombat or Ozaria"
      v-if="openImplementationModal"
      @close="openImplementationModal = false"
    />
  </div>
</template>

<script>
import ModalGetLicenses from "../../components/common/ModalGetLicenses";
export default {
  name: "PaymentSchoolDistrictBodyView",
  components: {
    ModalGetLicenses,
  },
  data() {
    return {
      openLicenseModal: false,
      openImplementationModal: false,
    }
  },
  methods: {
    moreInfo() {
      window.open('https://www.ozaria.com/professional-development#license-interest', '_blank')
    },
    showLicenseModal(e) {
      e.preventDefault()
      this.openLicenseModal = true
    },
    showImplementationModal(e) {
      e.preventDefault()
      this.openImplementationModal = true
    }
  }
}
</script>

<style scoped lang="scss">
.school-district-body {
  padding-top: 20px;
  text-align: center;

  p {
    margin: 0 0 1px;
  }
}
.column {
  display: inline-block;
  text-align: initial;
  width: 30%;
  vertical-align: top;
}
.quote-column {
  width: 32%;
}
.request-quote {
  background-color: white;
  text-align: center;
  padding: 30px 15px 15px;
  box-shadow: 0px 2px 4px rgba(0, 0, 0, 0.5);
}
.heading {
  font-weight: bold;
}
.small-text {
  font-size: small;
  color: grey;
}
.feature-list {
  text-align: initial;
  padding-top: 10px;

  li {
    font-size: small;
    color: grey;
  }
}
.include {
  padding-left: 10px;
  font-weight: bold;
}
.training {
  padding-top: 50px;
}
.more-info-btn {
  font-weight: bold;
  border: 1px solid black;
}
.info {
  padding-bottom: 10px;
}
.pd-training {
  margin-right: 15px;
  padding-top: 10px;
}
</style>
