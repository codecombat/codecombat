<script>
  import LicensesCarouselContainer from './common/LicensesCarouselContainer'
  import PrimaryButton from 'ozaria/site/components/teacher-dashboard/common/buttons/PrimaryButton'
  export default {
    components: {
      PrimaryButton,
      LicensesCarouselContainer
    },
    methods: {
      trackEvent (eventName) {
        if (eventName) {
          window.tracker?.trackEvent(eventName, { category: 'SchoolAdmin' })
        }
      }
    }
  }
</script>

<template>
  <div class="no-licenses-page">
    <div class="row license-carousel-div">
      <div class="flex-row">
        <div class="flex-col carousel-text-div">
          <span class="subtitle-24 yellow-text"> {{ $t("no_licenses_page.looking_for_engaging") }} </span>
          <div class="yellow-bar" />
          <p class="p-medium-text">
            {{ $t("no_licenses_page.licenses_are_required") }}
          </p>
          <primary-button
            class="get-licenses-btn"
            @click="$emit('getLicenses')"
            @click.native="trackEvent('Admin Licenses: Get Licenses Clicked #1')"
          >
            {{ $t("no_licenses_page.get_licenses") }}
          </primary-button>
        </div>
        <licenses-carousel-container class="carousel-div" />
      </div>
    </div>
    <div class="row full-access-div">
      <div class="flex-col">
        <span class="subtitle-large-twilight"> {{ $t("no_licenses_page.get_full_access_to_ozaria") }} </span>
        <span class="subtitle-uppercase-twilight"> {{ $t("no_licenses_page.unlock_all_dsa") }} </span>
        <div class="yellow-bar" />
        <div class="flex-row full-access-icons-div">
          <div class="flex-col">
            <img src="/images/ozaria/teachers/dashboard/my_licenses/IconDashboard.svg">
            <span> {{ $t("no_licenses_page.comprehensive_dashboards") }} </span>
          </div>
          <div class="flex-col">
            <img src="/images/ozaria/teachers/dashboard/my_licenses/IconLessonPlans.svg">
            <span> {{ $t("no_licenses_page.lesson_plans_rubrics_guides") }} </span>
          </div>
          <div class="flex-col">
            <img src="/images/ozaria/teachers/dashboard/my_licenses/IconCustomerSuccess.svg">
            <span> {{ $t("no_licenses_page.dedicated_customer_success_manager") }} </span>
          </div>
          <div class="flex-col">
            <img src="/images/ozaria/teachers/dashboard/my_licenses/IconAutomaticAccess.svg">
            <span> {{ $t("no_licenses_page.automatic_access") }} </span>
          </div>
        </div>
      </div>
    </div>
    <div class="row quote-div">
      <div class="flex-col">
        <img src="/images/ozaria/teachers/dashboard/my_licenses/IconQuote.svg">
        <span class="subtitle-24 quote-text text-center"> {{ $t("no_licenses_page.license_quote") }} </span>
        <div class="flex-row quote-portrait">
          <div class="portrait">
            <img src="/images/ozaria/teachers/dashboard/my_licenses/QuotePortrait_Chris.jpg">
          </div>
          <div class="flex-col portrait-title">
            <span class="name"> Chris Beckwith </span>
            <span class="role"> Technology Instructor </span>
            <span class="school"> Reeds Brook Middle School </span>
          </div>
        </div>
      </div>
    </div>
    <div class="row join-community-div">
      <div class="flex-col">
        <span class="subtitle-large-twilight"> {{ $t("no_licenses_page.join_our_community") }} </span>
        <div class="yellow-bar" />
        <span class="p-medium-text twilight-text text-center"> {{ $t("no_licenses_page.join_our_community_desc") }} </span>
        <primary-button
          class="get-licenses-btn"
          @click="$emit('getLicenses')"
          @click.native="trackEvent('Admin Licenses: Get Licenses Clicked #2')"
        >
          {{ $t("no_licenses_page.get_licenses") }}
        </primary-button>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

.row {
  width: 100%;
  margin: 0px;
  padding: 50px;
  overflow: hidden;
}

.flex-col {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}

.flex-row {
  display: flex;
  flex-direction: row;
  justify-content: space-around;
  align-items: center;
}

.yellow-bar {
  background: linear-gradient(3.22deg, #D1B147 -5.07%, #D1B147 16.64%, #F7D047 93.04%, #F7D047 103.46%);
  width: 150px;
  height: 5px;
  margin: 20px 0px;
}

// carousel div

.license-carousel-div {
  background: linear-gradient(89.93deg, #476FB1 0.02%, #476FB1 20.01%, #5DB9AC 90.38%, #5DB9AC 99.98%);
  min-height: 460px;
}

.carousel-text-div {
  width: 30%;
  align-items: flex-start;
  margin-right: 30px;
}

.carousel-div {
  display: flex;
  width: 70%;
  // min-width: 900px;
}

// full access div

.full-access-div {
  min-height: 350px;
}

.full-access-icons-div {
  margin: 10px;
  div {
    max-width: 300px;
    min-width: 200px;
  }
  span {
    @include font-p-3-paragraph-small-gray;
    text-align: center;
    margin-top: 17px;
  }
}

// quote and portrait div

.quote-div {
  min-height: 335px;
  background: #355EA0;
}

.portrait {
  position: relative;
  background: linear-gradient(3.22deg, #D1B147 -5.07%, #D1B147 16.64%, #F7D047 93.04%, #F7D047 103.46%);
  height: 88px;
  width: 30%;
  border-radius: 50%;
  -moz-border-radius: 50%;
  -webkit-border-radius: 50%;
  margin: 0px 20px;
  img {
    position: absolute;
    width: 85%;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    border-radius: 50%;
    -moz-border-radius: 50%;
    -webkit-border-radius: 50%;
  }
}

.quote-portrait {
  width: auto;
}

.portrait-title {
  align-items: flex-start;
  width: 360px;
  .name {
    @include font-p-3-small-button-text-black;
    color: #FFFFFF;
  }
  .role, .school {
    @include font-p-3-paragraph-small-gray;
    color: #FFFFFF;
  }
}

// join community div

.join-community-div {
  min-height: 315px;
}

// texts/subtitles

.subtitle-24 {
  @include font-h-2-subtitle-white-24;
  line-height: 28px;
  letter-spacing: 0.56px;
}

.subtitle-large-twilight {
  @include font-h-2-subtitle-twilight;
}

.subtitle-uppercase-twilight {
  @include font-h-3-subtitle-uppercase-twilight;
  font-size: 18px;
}

.yellow-text {
  color: $moon;
}

.quote-text {
  margin: 30px;
  width: 800px;
}

.p-medium-text {
  @include font-p-2-paragraph-medium-white;
}

.twilight-text {
  color: $twilight;
}

.text-center {
  text-align: center;
}

// button

.get-licenses-btn {
  width: 220px;
  height: 50px;
  margin: 20px 0px;
}
</style>
