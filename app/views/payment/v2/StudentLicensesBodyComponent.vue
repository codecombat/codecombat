<template>
  <div class="student-licenses-body">
    <div class="header">
      <div class="header__heading">{{ $t('payments.student_licenses') }}</div>
      <div class="header__subheading">
        {{ $t('payments.purchase_licenses_2') }}. {{ $t('new_home.learn_more') }} {{ $t('payments.about') }}
        <a href="javascript:;" @click="onApplyLicenseClicked">{{ $t('payments.applying_licenses') }}</a>
      </div>
    </div>
    <div class="row">
      <div class="col-md-6" v-if="numStudents === '<=10'">
        <div class="license small-class" @click="onSmallClassClicked">
          <div class="license__header">
            <div class="license__header-heading">
              Small Classroom
            </div>
            <div class="license__header-subheading">
              For clubs, after-school programs and small classrooms with 5-9 students.
            </div>
          </div>

          <div class="license__body small-class__body">
            <div class="license__body-1 small-class__body-1">
              <div class="license__price">
                $50
              </div>
              <div class="license__per">
                <span class="license__per-student">per student</span>
                <span class="license__per-year">per year</span>
              </div>
              <div class="license__licenses clearfix">
                <span class="license__licenses-num">5-9</span>
                <span class="license__licenses-lic">licenses</span>
              </div>
            </div>

            <includes-body-component class-type="small-class" />

            <addon-body-component class-type="small-class" />
          </div>

          <body-footer-component :class-type="'small-class'"/>
        </div>
      </div>
      <div :class="{'col-md-6': numStudents === '<=10', 'col-md-12': numStudents !== '<=10'}">
        <div class="license school-district" @click="onSchoolDistrictClicked">
          <div class="license__header">
            <div class="license__header-heading">
              Schools or Districts
            </div>
            <div class="license__header-subheading">
              For classrooms, schools and districts with 10 or more students
            </div>
          </div>

          <div
            v-if="numStudents === '<=10'"
            class="school-district__body"
          >
            <div class="school-district__body-1">
              <div class="license__price">
                Bulk
              </div>
              <div class="license__per">
                <span class="license__per-student">discounts</span>
                <span class="license__per-year">available</span>
              </div>
              <div class="license__licenses clearfix">
                <span class="license__licenses-num">10+</span>
                <span class="license__licenses-lic">licenses</span>
              </div>
            </div>

            <includes-body-component class-type="school-district" />

            <addon-body-component class-type="school-district" />
          </div>
          <div
            v-else
            class="school-district__body row school-district__body-only"
          >
            <div class="col-md-6">
              <includes-body-component class-type="school-district" />
            </div>
            <div class="col-md-6">
              <addon-body-component class-type="school-district" />
            </div>
          </div>
          <body-footer-component :class-type="'school-district'" :num-students="numStudents" />
        </div>
      </div>
    </div>
    <div class="footer">
      <div class="footer__text">
        See also our <a href="https://www.ozaria.com/funding" target="_blank">Funding Resources Guide</a> for how to leverage CARES Act funding sources like ESSER and GEER.
      </div>
    </div>
    <modal-get-licenses
      v-if="openLicenseModal"
      @close="openLicenseModal = false"
    />
    <purchase-license-modal
      :payment-group="paymentGroup"
      v-if="openPurchaseModal"
      @close="openPurchaseModal = false"
    />
    <backbone-modal-harness
      :open="openApplyLicenseModal"
      :modal-view="HowToEnrollModal"
      @close="openApplyLicenseModal = false"
    />
  </div>
</template>

<script>
import IncludesBodyComponent from './student-license/IncludesBodyComponent'
import AddonBodyComponent from './student-license/AddonBodyComponent'
import BodyFooterComponent from './student-license/BodyFooterComponent'
import ModalGetLicenses from '../../../components/common/ModalGetLicenses'
import PurchaseLicenseModal from './student-license/PurchaseLicenseModal'
import BackboneModalHarness from '../../common/BackboneModalHarness'
import HowToEnrollModal from '../../teachers/HowToEnrollModal'
export default {
  name: 'StudentLicensesBodyComponent',
  components: {
    IncludesBodyComponent,
    AddonBodyComponent,
    BodyFooterComponent,
    ModalGetLicenses,
    PurchaseLicenseModal,
    BackboneModalHarness
  },
  data () {
    return {
      openLicenseModal: false,
      openPurchaseModal: false,
      openApplyLicenseModal: false,
      HowToEnrollModal
    }
  },
  props: {
    numStudents: {
      type: String,
      required: true,
      validator: (v) => {
        return [ '<=10', '10+' ].includes(v)
      }
    },
    paymentGroup: {
      type: Object
    }
  },
  methods: {
    onSchoolDistrictClicked () {
      this.openLicenseModal = true
    },
    onSmallClassClicked () {
      this.openPurchaseModal = true
    },
    onApplyLicenseClicked () {
      this.openApplyLicenseModal = true
    }
  }
}
</script>

<style scoped lang="scss">
.student-licenses-body {
  font-size: 62.5%;
}
.license {
  background: #FFFFFF;
  /* Gray 3 */

  border: 1px solid #D8D8D8;
  box-sizing: border-box;
  /* Drop Shadow (Box) */

  box-shadow: 3px 0 8px rgba(0, 0, 0, 0.15), -1px 0 1px rgba(0, 0, 0, 0.06);
  border-radius: 2.4rem;

  overflow: hidden;

  font-family: 'Work Sans', serif;
  font-style: normal;

  cursor: pointer;

  &:hover {
    box-shadow: 7px 0 8px rgba(0, 0, 0, 0.15), -5px 0 1px rgba(0, 0, 0, 0.06);
  }

  &__header {
    background: #6AE8E3;
    /* Drop Shadow (Box) */

    box-shadow: 3px 0 8px rgba(0, 0, 0, 0.15), -1px 0 1px rgba(0, 0, 0, 0.06);
    text-align: center;

    padding: 2rem;

    &-heading {
      font-weight: 700;
      font-size: 3.6rem;
      line-height: 3.2rem;
      /* or 89% */

      letter-spacing: 0.56px;

      /* Teal Dark */

      color: #0E4C60;
    }

    &-subheading {
      font-weight: 400;
      font-size: 1.6rem;
      line-height: 2.6rem;
      /* or 162% */

      /* Teal Dark */

      color: #0E4C60;
    }
  }

  &__price {
    font-weight: 700;
    font-size: 5rem;
    line-height: 3.2rem;
    /* identical to box height, or 53% */

    letter-spacing: 0.56px;

    /* Teal Dark */

    color: #0E4C60;

    display: inline-block;
  }

  &__per {
    display: inline-block;

    text-transform: uppercase;

    font-weight: 600;
    font-size: 1.6rem;
    line-height: 2.1rem;
    /* or 122% */

    letter-spacing: 0.56px;
    color: #0E4C60;

    &-student {
      display: block;
    }

    &-year {
      display: block;
    }
  }

  &__licenses {
    font-weight: 600;
    font-size: 1.6rem;
    line-height: 2.1rem;
    /* or 122% */

    letter-spacing: 0.56px;
    text-transform: uppercase;

    /* Teal Dark */

    color: #0E4C60;

    display: inline-block;

    float: right;

    &-num {
      display: block;
    }

    &-lic {
      display: block;
    }
  }
}

.small-class {
  &::v-deep &__body {
    padding: 2rem;

    &-1 {
      padding-bottom: 2rem;
    }

    &-2 {
      padding-bottom: 11.5rem;
    }

    &-3 {
      padding-bottom: 26.3rem;
    }
  }
}

.school-district {
  &::v-deep &__body {
    padding: 2rem;

    &-1 {
      padding-bottom: 2rem;
    }

    &-2 {
      padding-bottom: 4rem;
    }

    &-3 {
      padding-bottom: 5rem;
    }
  }
}

.footer {
  padding-top: 3rem;

  &__text {
    font-family: 'Work Sans', serif;
    font-style: italic;
    font-weight: 400;
    font-size: 1.6rem;
    line-height: 2.2rem;
    /* identical to box height, or 138% */

    align-items: center;

    color: #000000;
    text-align: center;
  }
}

.header {

  padding-bottom: 2rem;
  font-family: 'Work Sans', serif;
  font-style: normal;

  &__heading {
    font-weight: 700;
    font-size: 4rem;
    line-height: 3.2rem;
    /* or 80% */

    letter-spacing: 0.56px;

    color: #000000;

    margin-bottom: 1rem;
  }

  &__subheading {
    font-weight: 400;
    font-size: 2.2rem;
    line-height: 3rem;
    /* identical to box height, or 136% */


    color: #000000;
  }
}
</style>
