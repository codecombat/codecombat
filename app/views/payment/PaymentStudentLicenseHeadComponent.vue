<template>
  <div class="container-fluid text-center p-t-2">
    <div class="container">
      <div class="top-section">
        <div class="heading-row">
          <h1>{{ title || $t(`payments.${this.i18nHeadingName}`)}}</h1>
          <p class="dsh-info" v-if="isDshPartner"><b>Digital Schoolhouse</b> has partnered with CodeCombat to offer the entirety of the Ozaria story-based computer science adventure game (all 4 Chapters, and over 70 hours of comprehensive instruction) as well as our original game CodeCombat (11 courses spanning Computer Science, Game Development and Web Development) for the <b>discounted rate of $25 USD per annual license (normally $30 USD)</b>. Happy coding!</p>
          <h5>{{ subTitle || $t('payments.great_courses')}}</h5>
        </div>
        <div class="row info-row">
          <template v-if="isDshPartner">
            <ozaria-head-info-component />
            <coco-head-info-component />
          </template>
          <template v-else>
            <coco-head-info-component />
            <ozaria-head-info-component />
          </template>

        </div>
      </div>
    </div>
  </div>
</template>

<script>
import CocoHeadInfoComponent from './student-licenses/CocoHeadInfoComponent'
import OzariaHeadInfoComponent from './student-licenses/OzariaHeadInfoComponent'
export default {
  name: "PaymentStudentLicenseHeadComponent",
  components: {
    CocoHeadInfoComponent,
    OzariaHeadInfoComponent
  },
  props: {
    i18nHeadingName: String,
    title: String,
    subTitle: String,
    isDshPartner: {
      type: Boolean,
      default: false
    }
  },
}
</script>

<style scoped lang="scss">
.container-fluid {
  background: linear-gradient(118.13deg, #0E4C60 0%, #20572B 100%);
  color: white;
}

.top-section {
  padding: 20px 20px 50px;

  h1, h3, h5 {
    font-weight: bold;
    color: white;
  }

  .info-row {
    padding: 20px 5px 5px;
  }
}
.dsh-info {
  color: white;
  font-size: small;
}
</style>
