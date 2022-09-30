<template>
  <modal
      title="Schedule a Free Class"
      @close="$emit('close')"
  >
    <form @submit.prevent="onFormSubmit" class="schedule-free-class-form">
      <p>
        {{ $t('modal_free_class.paragraph_1') }}
      </p>

      <p>
        {{ $t('modal_free_class.paragraph_2') }}
      </p>

      <p>
        {{ $t('modal_free_class.paragraph_3') }}
      </p>
      <div class="form-group">
        <label for="name">{{ $t('modal_free_class.name') }}</label>
        <input type="text" id="name" placeholder="Enter name" v-model="name" class="form-control"/>
      </div>
      <div class="form-group">
        <label for="phone">{{ $t('modal_free_class.phone_number') }}</label>
        <input type="text" id="phone" placeholder="Enter phone number" v-model="phone" class="form-control"/>
      </div>
      <div class="form-group">
        <label for="org">{{ $t('modal_free_class.available') }}</label>
        <div class="form-check">
          <label class="form-check-label">
            <input type="radio" class="form-check-input" name="available" value="yes" v-model="available">
            {{ $t('modal_free_class.yes') }}
          </label>
        </div>
        <div class="form-check">
          <label class="form-check-label">
            <input type="radio" class="form-check-input" name="available" value="no" v-model="available">
            {{ $t('modal_free_class.no') }}
          </label>
        </div>
      </div>
      <div class="form-group">
        <label for="role">{{ $t('modal_free_class.preferred_time') }}</label>
        <select class="form-control" v-model="preferredTime">
          <option value="Anytime">{{ $t('modal_free_class.anytime') }}</option>
          <option value="Morning (8AM - 12PM)">{{ $t('modal_free_class.morning') }}</option>
          <option value="Afternoon (12PM - 4PM)">{{ $t('modal_free_class.afternoon') }}</option>
          <option value="Evening (4PM - 8PM)">{{ $t('modal_free_class.evening') }}</option>
        </select>
      </div>
      <div class="form-group">
        <label for="userTimeZone">{{ $t('modal_free_class.time_zone') }}</label>
        <input type="text" id="userTimeZone" placeholder="Enter time zone" v-model="timeZone" class="form-control"/>
      </div>
      <div class="form-group">
        <label for="email">{{ $t('modal_free_class.email') }}</label>
        <input type="email" id="email" placeholder="Enter email" v-model="email" class="form-control"/>
      </div>
      <div class="form-group pull-right">
        <span
            v-if="isSuccess"
            class="success-msg"
        >
          Success
        </span>
        <button
            v-if="!isSuccess"
            class="btn btn-success btn-lg"
            type="submit"
            :disabled="inProgress"
        >
          Submit
        </button>
      </div>
    </form>
  </modal>
</template>

<script>
import Modal from 'app/components/common/Modal'
import { sendFormEntry } from 'core/api/parents'
import moment from 'moment'

export default {
  name: 'ModalScheduleFreeClass',
  components: {
    Modal
  },
  data () {
    const timeZone = moment.tz.guess()
    const timeZoneCode = moment.tz(timeZone).format('zz')
    return {
      name: me.get('firstName') || me.get('name'),
      phone: null,
      available: 'yes',
      preferredTime: 'Anytime',
      timeZone: `${timeZoneCode} (${timeZone})`,
      email: me.get('email'),
      isSuccess: false,
      inProgress: false
    }
  },
  methods: {
    async onFormSubmit () {
      this.inProgress = true
      this.isSuccess = false
      const details = {
        ...this.$data
      }
      try {
        await sendFormEntry(details)
        this.isSuccess = true
      } catch (err) {
        console.error('schedule free class err', err)
        noty({
          text: 'Failed to contact server, please reach out to support@codecombat.com',
          type: 'error',
          timeout: 5000,
          layout: 'topCenter'
        })
      }
      this.inProgress = false
    }
  }
}
</script>

<style scoped lang="scss">
.schedule-free-class-form {
  text-align: initial;
  padding: 2rem;
  max-width: 650px;

  p {
    font-size: 18px;
  }

  .form-check-label {
    font-size: 16px;
    font-weight: normal;
  }
}

::v-deep .title {
  padding-top: 10px;
}

.success-msg {
  font-size: 1.6rem;
  color: #0B6125;
  display: inline-block;
  margin-right: 1rem;
}
</style>
