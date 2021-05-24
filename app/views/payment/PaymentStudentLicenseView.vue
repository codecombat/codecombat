<template>
	<span>
		<div class="container-fluid text-center p-t-2">
			<div class="container">
			<div class="top-section">
				<h1>{{$t(`payments.${this.i18nName}`)}}</h1>
				<h4>{{$t('payments.great_courses')}}:</h4>
				<div class="row info-row">
					<div class="col-xs-4">
						<div class="text-center">
							<img src='/images/pages/home/computer-science-2.png' />
							<p>{{$t('payments.computer_science')}}</p>
						</div>
					</div>
					<div class="col-xs-4">
						<div class="text-center">
							<img src='/images/pages/home/web-development-1.png' />
							<p>{{$t('payments.web_development')}}</p>
						</div>
					</div>
					<div class="col-xs-4">
						<div class="text-center">
							<img src='/images/pages/home/game-development-1.png' />
							<p>{{$t('payments.game_development')}}</p>
						</div>
					</div>
				</div>
			</div>
			<div class="middle-section">
				<h3>{{$t('payments.just')}} {{this.getCurrency()}}{{this.getUnitPrice()}} {{$t('payments.per_student')}}</h3>
				<ul class="information">
					<li class="light-text">Up to {{this.licenseCap}} student licenses, <a href="#" @click="this.enableContactModal">Contact Us</a> to purchase more</li>
					<li class="light-text">Licenses are active for {{this.licenseValidityPeriodInDays}} days from the day of purchase</li>
					<li class="light-text">Teacher account licenses are free with purchase</li>
				</ul>
			</div>
			</div>
		</div>
		<modal-get-licenses
				v-if="showContactModal"
				@close="showContactModal = false"
		/>
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
	background-color: aliceblue;
}

.top-section {
	.info-row {
		padding-top: 10px;
	}
}

.middle-section {
	padding-top: 10px;
	.purchase-more {
		padding-top: 10px;
	}
}

.light-text {
	font-weight: 200!important;
	margin: 0;
	font-size: small;
}

h1, h3 {
	font-weight: bold;
}
.information {
	list-style-position: inside;
	text-align: initial;
	padding-left: 35%;
}
</style>
