<template>
	<span>
		<div class="container-fluid text-center p-t-2">
			<div class="container">
			<div class="top-section">
        <div class="heading-row">
          <h1>{{$t(`payments.${this.i18nName}`)}}</h1>
          <h5>{{$t('payments.great_courses')}}</h5>
        </div>
        <div class="row info-row">
          <div class="col-md-3">
            <div class="text-center">
              <img src="/images/pages/home/type_real_code.png" />
            </div>
          </div>
          <div class="col-md-3 info-data">
            <h2>CodeCombat</h2>
            <ul class="info-list">
              <li>Computer Science 1-6</li>
              <li>Web Development 1-2</li>
              <li>Game Development 1-2</li>
            </ul>
          </div>
          <div class="col-md-3">
            <div class="text-center">
              <img src="/images/pages/home/ozaria_acodus.png" />
            </div>
          </div>
          <div class="col-md-3 info-data">
            <h2>Ozaria</h2>
            <ul class="info-list">
              <li>Comprehensive Introduction to Computer Science</li>
              <li>Chapters 1-4</li>
            </ul>
          </div>
        </div>
			</div>
			</div>
		</div>
		<modal-get-licenses
				v-if="showContactModal"
				@close="showContactModal = false"
		/>
    <div class="middle-section">
      <h3 class="per-student text-center">{{$t('payments.just')}} {{this.getCurrency()}}{{this.getUnitPrice()}} {{$t('payments.per_student')}}</h3>
      <ul class="information">
        <li class="light-text">Up to {{this.licenseCap}} student licenses, <a href="#" @click="this.enableContactModal">Contact Us</a> to purchase more</li>
        <li class="light-text">Licenses are active for {{this.licenseValidityPeriodInDays}} days from the day of purchase</li>
        <li class="light-text">Teacher account licenses are free with purchase</li>
      </ul>
    </div>
	</span>
</template>

<script>
import ModalGetLicenses from "../../components/common/ModalGetLicenses";
export default {
	name: "PaymentStudentLicenseView",
	data () {
		return {
			showContactModal: false
		}
	},
	components: {
		ModalGetLicenses
	},
	props: {
		currency: {
			type: String,
			required: true,
		},
		unitAmount: {
			type: Number,
			required: true,
		},
		priceId: {
			type: String,
			required: true,
		},
		licenseCap: {
			type: Number,
			required: true,
		},
		licenseValidityPeriodInDays: {
			type: Number,
			required: true,
		},
		i18nName: String,
	},
	methods: {
		getUnitPrice() {
			return this.unitAmount / 100;
		},
		getCurrency() {
			return this.currency === 'usd' ? '$' : this.currency;
		},
		enableContactModal(e) {
			e.preventDefault()
			this.showContactModal = true
		}
	}
}
</script>

<style lang="scss" scoped>
.container-fluid {
  background: linear-gradient(118.13deg, #0E4C60 0%, #20572B 100%);
  color: white;
}

.top-section {
  .info-row {
		padding-top: 20px;
	}
  padding: 20px 20px 50px;
}

.middle-section {
	padding-top: 15px;
	
  .purchase-more {
		padding-top: 10px;
	}
  
  .information {
    list-style-position: inside;
    text-align: initial;
    padding-left: 38%;
  }
  
  .per-student {
    font-weight: bold;
  }
}

.light-text {
	font-weight: 200!important;
	margin: 0;
	font-size: small;
}

.top-section {
  h1, h3, h5 {
    font-weight: bold;
    color: white;
  }
}

.info-row {
  padding: 5px;
  img {
    max-width:100%;
    max-height:100%;
  }
}
.info-data {
  text-align: left;
  
  h2 {
    color: lawngreen;
    font-weight: bold;
  }
  padding-left: 0;
}
</style>
