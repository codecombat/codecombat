<script>
import ModalDynamicPromotion from './ModalDynamicContent'
import trackable from 'app/components/mixins/trackable.js'
import { mapGetters } from 'vuex'

export default Vue.extend({
  components: {
    ModalDynamicPromotion
  },
  mixins: [trackable],
  computed: {
    ...mapGetters({
      activeClassrooms: 'teacherDashboard/getActiveClassrooms',
      sharedClassrooms: 'teacherDashboard/getSharedClassrooms',
      activeLicenses: 'teacherDashboard/getActiveLicenses',
      loadingLicenses: 'teacherDashboard/getLoadingState'
    }),
    allClassrooms () {
      return [...this.activeClassrooms, ...this.sharedClassrooms]
    },
    showModal () {
      const threeDaysAgo = new Date(new Date() - 3 * 24 * 60 * 60 * 1000)
      const startDate = new Date('2024-08-16')
      const currentDate = new Date()
      return currentDate > startDate && new Date(me.get('dateCreated')) < threeDaysAgo && this.allClassrooms.length > 0
    },
    hasLicense () {
      return !this.loadingLicenses && this.activeLicenses.length > 0
    }
  },
  methods: {
    onTryItNow () {
      this.$refs.modal.onClose()
      this.trackEvent('Test as student Promo Modal: Try It Now clicked', { category: 'Teachers' })
    }
  }
})
</script>

<template>
  <div>
    <ModalDynamicPromotion
      v-if="showModal"
      ref="modal"
      seen-promotions-property="test-as-student-promotion-modal"
    >
      <template #content>
        <div class="ai-modal-content-container">
          <p class="text-p">
            {{ $t('teachers.test_student_promotion_1') }}
          </p>
          <img
            src="/images/pages/teachers/dashboard/teacher_test_as_student.png"
            alt="test as student"
          >
          <p class="text-p">
            {{ $t('teachers.test_student_promotion_2') }}
          </p>
          <p
            v-if="!hasLicense"
            class="text-p"
          >
            {{ $t('teachers.test_student_promotion_3') }}
          </p>

          <a
            id="nav-student-mode"
            class="btn btn-primary btn-lg btn-moon"
            href="#"
            @click="onTryItNow"
          >
            {{ $t('home_v3.try_it_now') }}
          </a>
        </div>
      </template>
    </ModalDynamicPromotion>
  </div>
</template>

<style lang="scss" scoped>
@import 'app/styles/core/variables.scss';
@import 'app/styles/common/_button.scss';

.ai-modal-content-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 5px 20px;
  text-align: center;

  .text-h2 {
    font-weight: bold;
  }

  .text-p {
    font-size: 18px;
  }

  >* {
    max-width: 800px;
  }

  img {
    width: 100%;
    max-width: 600px;
    margin: 10px auto;
  }
}
</style>
