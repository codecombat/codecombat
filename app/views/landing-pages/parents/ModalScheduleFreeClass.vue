<template>
  <modal
      title="Schedule a Free Class"
      @close="$emit('close')"
  >
    <form @submit.prevent="onFormSubmit" class="schedule-free-class-form">
      <p>
        Thank you for choosing CodeCombat.
      </p>

      <p>
        Our team is eager to connect with you to get your child scheduled for a free trial class.
      </p>

      <p>
        Please provide your contact information and one of our learning advisors will call you to gather student
        information, identify a teacher based on your child’s preferred learning style and to schedule the trial class.
      </p>
      <div class="form-group">
        <label for="name">Name</label>
        <input type="text" id="name" placeholder="Enter name" v-model="name" class="form-control"/>
      </div>
      <div class="form-group">
        <label for="phone">Phone Number</label>
        <input type="text" id="phone" placeholder="Enter phone number" v-model="phone" class="form-control"/>
      </div>
      <div class="form-group">
        <label for="org">Are you available to talk now?</label>
        <div class="form-check">
          <label class="form-check-label">
            <input type="radio" class="form-check-input" name="available" value="yes" v-model="available"> Yes
          </label>
        </div>
        <div class="form-check">
          <label class="form-check-label">
            <input type="radio" class="form-check-input" name="available" value="no" v-model="available"> No
          </label>
        </div>
      </div>
      <div class="form-group">
        <label for="role">Preferred time for call if we can't connect now</label>
        <select class="form-control" v-model="preferredTime">
          <option>Anytime</option>
          <option>Morning (8AM - 12PM)</option>
          <option>Afternoon (12PM - 4PM)</option>
          <option>Evening (4PM - 8PM)</option>
        </select>
      </div>
      <div class="form-group">
        <label for="userTimeZone">Your Time Zone</label>
        <input type="text" id="userTimeZone" placeholder="Enter time zone" v-model="timeZone" class="form-control"/>
      </div>
      <div class="form-group">
        <label for="email">Email</label>
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

export default {
  name: 'ModalScheduleFreeClass',
  components: {
    Modal
  },
  data () {
    return {
      name: me.get('firstName') || me.get('name'),
      phone: null,
      available: null,
      preferredTime: null,
      timeZone: new Date().toString().match(/\(([A-Za-z\s].*)\)/)[1],
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
        console.error('podcast contact err', err)
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
