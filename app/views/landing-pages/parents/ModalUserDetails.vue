<template>
  <modal
    :title="$t('parents_landing_2.book_your_class')"
    @close="$emit('close')"
  >
    <template v-if="!showSuccessModal">
      <div class="modal-user-details modal-common">
        <div class="header left-location">
          <p class="small-text">{{ $t('parents_landing_2.student_journey_start') }}</p>
          <p class="small-text">{{ $t('parents_landing_2.enter_email_address') }}</p>
        </div>
        <div class="form-input">
          <div class="text-center">
            <input class="email-input form-control" type="text" v-model="email" placeholder="email@example.com" />
          </div>
          <div class="text-center">
            <button type="submit" :disabled="inProgress" class="btn btn-success submit-btn text-center" @click="save">{{ $t('common.submit') }}</button>
          </div>
          <p class="error small-text text-center error-location" v-if="error">{{ error }}</p>
        </div>
        <div class="footer left-location">
          <p class="small-text">{{ $t('parents_landing_2.enter_parent_email_address') }}</p>
        </div>
      </div>
    </template>
    <template v-else>
      <div class="success-modal modal-common">
        <p class="small-text">{{ $t('parents_landing_2.email_sent_success') }}</p>
        <p class="small-text">{{ $t('parents_landing_2.email_schedule_info') }}</p>
        <div class="text-center">
          <button type="submit" class="btn btn-success submit-btn text-center" @click="$emit('close')">{{ $t('modal.close') }}</button>
        </div>
      </div>
    </template>
  </modal>
</template>

<script>
import Modal from "../../../components/common/Modal"
import { scheduleClassEmail } from "../../../core/api/online-classes";
import { validateEmail } from '../../../lib/common-utils'
export default {
  name: 'ModalUserDetails',
  components: {
    Modal
  },
  data () {
    return {
      email: null,
      showSuccessModal: false,
      inProgress: false,
      error: null
    }
  },
  methods: {
    async save () {
      if (!validateEmail(this.email)) {
        this.error = 'Email not valid'
        return
      }
      this.inProgress = true
      this.error = null
      try {
        await scheduleClassEmail({ email: this.email })
        ga('send', {
          hitType: 'event',
          eventCategory: 'Online classes',
          eventAction: 'submit',
          eventLabel: 'Email for booking class'
        })
        this.showSuccessModal = true
      } catch (err) {
        this.error = err?.message || err
      }
      this.inProgress = false
    }
  }
}
</script>

<style scoped lang="scss">
.modal-common {
  width: 450px;
  line-height: 24px;
}
.modal-user-details {
  padding: 5%;
}
.small-text {
  font-size: 80%;
}
.submit-btn {
  margin-top: 10px;
}
.footer {
  margin-top: 25px;
}
.success-modal {
  padding: 5%;
}
.error {
  color: red;
}
.error-location {
  margin-top: 5px;
}
</style>
