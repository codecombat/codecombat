<template>
  <ModalDynamicContent
    ref="modal"
    seen-promotions-property="end-of-trial-promotion-modal"
    name="end-of-trial-promotion-modal"
  >
    <template #content>
      <div class="modal-content-container">
        <h3 class="text-h3">
          {{ $t('teachers.near_end_trial') }}
        </h3>
        <p class="schedule-demo">
          {{ $t('teachers.schedule_demo_subheading') }}
        </p>
        <div class="purple-separator"></div>
        <div class="subheadings">
            <div class="subheading-container">
                <p class="subheading">{{ $t('schools_page.core_curriculum') }}</p>
            </div>
            <div class="subheading-container">
                <p class="subheading">{{ $t('teachers.practice_and_application') }}</p>
            </div>
        </div>
        <div class="experiences">
            <div class="experiences-box">
                <div class="card-row">
                    <div class="card">
                        <img src="/images/common/modal/ozaria_promo.webp">
                        <div class="card-title">{{ $t('schools_page.core_curriculum_1_title') }}</div>
                    </div>
                    <div class="card">
                        <img src="/images/common/modal/coco_promo.webp">
                        <div class="card-title">{{ $t('schools_page.core_curriculum_2_title') }}</div>
                    </div>
                </div>
                <div class="card-row center">
                    <div class="card">
                        <img src="/images/common/modal/coco_junior_promo.webp">
                        <div class="card-title">{{ $t('schools_page.young_learners_1_title_classroom') }}</div>
                    </div>
                </div>
            </div>
            <div class="experiences-box">
                <div class="card-row">
                    <div class="card">
                        <img src="/images/common/modal/ai_league_promo.webp">
                        <div class="card-title">{{ $t('nav.ai_league_esports') }}</div>
                    </div>
                    <div class="card">
                        <img src="/images/common/modal/ccw_promo.webp">
                        <div class="card-title">{{ $t('schools_page.codecombat_worlds') }}</div>
                    </div>
                </div>
                <div class="card-row center">
                    <div class="card">
                        <img src="/images/common/modal/hackstack_promo.webp">
                        <div class="card-title">{{ $t('schools_page.ai_hackstack') }}</div>
                    </div>
                </div>
            </div>
        </div>
        <p class="text-p">
          {{ $t('teachers.schedule_demo_description') }}
        </p>
        <CTAButton
            class="request-demo"
            @clickedCTA="showContactModal = true"
          >
            {{ $t('schools_page.request_a_demo') }}
        </CTAButton>
      </div>
    </template>
  </ModalDynamicContent>
</template>

<script>
import ModalDynamicContent from 'ozaria/site/components/teacher-dashboard/modals/ModalDynamicContent.vue'
import CTAButton from 'app/components/common/buttons/CTAButton.vue'
import { mapGetters } from 'vuex'
export default {
  name: 'EndOfTrialModal',
  components: {
    ModalDynamicContent,
    CTAButton,
  },
  computed: {
    ...mapGetters({
        activeClassrooms: 'teacherDashboard/getActiveClassrooms',
        sharedClassrooms: 'teacherDashboard/getSharedClassrooms',
        activeLicenses: 'teacherDashboard/getActiveLicenses',
        loadingLicenses: 'teacherDashboard/getLoadingState'
    }),
    hasLicense () {
        return !this.loadingLicenses && this.activeLicenses.length > 0
    },
    showModal () {
        return !this.hasLicense // THIS NEEDS UPDATING: 
    },
  },
  methods: {
    openModal () {
      this.$refs.modal.openModal()
    },
    close () {
      this.$refs.modal.onClose()
    },
  },
}
</script>

<style lang="scss" scoped>
@import 'app/styles/core/variables.scss';
@import 'app/styles/common/_button.scss';
.modal-content-container {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 10px 60px;
    text-align: center;
    .text-h2 {
        font-weight: bold;
    }

    >* {
        max-width: 800px;
    }
    .subheadings{
        display: flex;
        width: 100%;
    }
    .subheading-container {
        width: 50%;
    }
    .request-demo {
        display: flex;
        justify-content: center;
        margin-top: 15px;
    }
    .purple-separator {
        display: block;
        width: 100%;
        height: 2px;
        background-color: var(--color-primary-1);
        margin-bottom: 10px;
    }
    .schedule-demo{
        margin-top: 15px;
    }
    .experiences {
        gap: 40px; 
        margin-top: 20px;
        width: 100%;
        display: flex;
    }
    .experiences-box{
        flex-direction: column;
        align-items: center;
        width: 50%;
        gap: 20px;             
        flex: 1;                
        max-width: 360px;
    }
    .subheading{
        font-weight: 600;
    }
    .card-row {
        display: flex;
        gap: 20px;
        justify-content: center;
        width: 100%;
    }
    .card-row.center {
        justify-content: center;
    }
    .card {
        border-radius: 8px;
        overflow: hidden;
        box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        background: var(--color-primary-1);
        flex: 1 1 0; 
        width: 150px; 
        height: 140px;
        max-height: 140px;
        max-width: 150px;
        margin-bottom: 10px;
    }
    .card img {
        width: 100%;
        height: auto;
        display: block;
    }
    .card-title {
        background-color: var(--color-primary-1);
        color: $white;
        font-size: 12px;
        font-weight: 500;
        padding: 12px;
        display: flex;           
        align-items: flex-start;
        height: 40px;
        justify-content: center; 
    }
}
</style>
