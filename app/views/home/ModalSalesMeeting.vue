<script>
import ModalDynamicContent from 'ozaria/site/components/teacher-dashboard/modals/ModalDynamicContent'
import trackable from 'app/components/mixins/trackable.js'
import CTAButton from 'app/components/common/buttons/CTAButton.vue'
import CountDown from './CountDownComponent'
import MixedColorLabel from 'app/components/common/labels/MixedColorLabel'
import { mapGetters, mapActions } from 'vuex'

export default Vue.extend({
  components: {
    ModalDynamicContent,
    CTAButton,
    CountDown,
    MixedColorLabel,
  },
  mixins: [trackable],
  computed: {
    ...mapGetters({
      isPaidTeacher: 'me/isCurrentPaidTeacher',
    }),
    showPromotion () {
      const now = new Date()
      const Oct2026 = new Date(2026, 9, 1) // Months are 0-indexed in JavaScript
      return me.isTeacher() && !this.isPaidTeacher && (now < Oct2026)
    },
  },
  async created () {
    if (me?.isTeacher()) {
      await this.fetchPrepaids({ teacherId: me.get('_id') })
    }
  },
  methods: {
    ...mapActions({
      fetchPrepaids: 'prepaids/fetchPrepaidsForTeacher',
    }),
    onMeetTeam () {
      this.$refs.modal.onClose()
      this.trackEvent('Fall Sales Meeting Promo Modal: Get Start clicked', { category: 'Teachers' })
    },
  },
})
</script>

<template>
  <ModalDynamicContent
    v-if="showPromotion"
    ref="modal"
    modal-type="newModal"
    seen-promotions-property="fall-2026-sales-meeting-promotion"
  >
    <template #content>
      <div class="sales-modal-content-container">
        <div class="eyebrow">
          {{ $t('new_home.sales_modal_eyebrow') }}
        </div>
        <h2
          id="sales-modal-title"
          class="text-h2"
        >
          {{ $t('new_home.sales_modal_headline') }}
        </h2>
        <div class="main-body">
          <MixedColorLabel :text="$t('new_home.sales_modal_body_countdown')" />
          <CountDown
            class="count-down"
            ddl="2026-10-01"
          />
        </div>
        <p class="text-p">
          <span>{{ $t('new_home.sales_modal_deadline') }}</span>
          <b>{{ $t('new_home.sales_modal_ddl_date') }}</b>
        </p>
        <CTAButton
          href="/schools?openContactModal=true&utm_medium=modal&utm_campaign=2026_back_to_school_thank_you"
          @clickedCTA="onMeetTeam()"
        >
          {{ $t('new_home.sales_modal_cta') }}
        </CTAButton>
      </div>
    </template>
  </ModalDynamicContent>
</template>

<style lang="scss" scoped>
@import 'app/styles/core/variables.scss';
@import 'app/styles/common/_button.scss';
@import 'app/styles/component_variables.scss';

.sales-modal-content-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  margin: 10px 30px;
  text-align: center;
  position: relative;

  .text-h2#sales-modal-title {
    font-family: $main-font-family;
    font-weight: bold;
    margin: 10px auto;
    margin-top: 5px;
  }

  ::v-deep {
    .mixed-color-label__highlight {
      font-weight: 600;
    }
  }

  >* {
    max-width: 800px;
  }

  .img {
    margin-bottom: 10px;
    width: 600px;
    position: relative;
  }

  .count-down {
    margin: 10px;
  }
}
</style>
