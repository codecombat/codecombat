<script>
import { validationMixin } from 'vuelidate'
import { email, required } from 'vuelidate/lib/validators'
import SecondaryButton from './SecondaryButton'
import Modal from './Modal'
import api from 'core/api'
import contact from 'core/contact'

export default Vue.extend({
  components: {
    Modal,
    SecondaryButton
  },
  mixins: [validationMixin],
  props: {
    subtitle: {
      type: String,
      // default to DT text
      default: 'Let us know if you have any questions or requests regarding our AP CSP curriculum.'
    },
    modalTitle: {
      type: String,
      default: 'Contact Our Classroom Team'
    }
  },
  data: () => ({
    name: '',
    email: '',
    role: '',
    message: '',
    state: '',
    sendingInProgress: false
  }),
  validations: {
    name: {
      required
    },
    role: {
      required
    },
    email: {
      required,
      email
    },
    message: {
      required
    }
  },
  computed: {
    isFormValid () {
      return !this.$v.$invalid
    }
  },
  async mounted () {
    const trialRequests = await api.trialRequests.getOwn()
    const trialRequest = _.last(_.sortBy(trialRequests, (t) => t.id)) || {}
    const props = trialRequest.properties || {}

    if (props.firstName && props.lastName) {
      this.name = `${props.firstName} ${props.lastName}`
    } else {
      this.name = me.get('name')
    }

    this.state = props.state

    this.email = me.get('email') || props.email

    this.message = ''
  },
  methods: {
    closeModal () {
      window.location.href = '#license-interest'
      this.$emit('close')
    },
    async onClickSubmit () {
      if (this.isFormValid) {
        const sendObject = {
          name: this.name,
          email: this.email,
          role: this.role,
          message: this.message
        }
        this.sendingInProgress = true
        try {
          await contact.sendAPCSPContactMail(sendObject)
          this.sendingInProgress = false
          noty({
            text: 'Our team has received your request and will reach out to you shortly.',
            type: 'success',
            layout: 'center',
            timeout: 2000
          })
          this.$emit('close')
        } catch (e) {
          this.sendingInProgress = false
          noty({ text: 'Couldnt send the message', type: 'error', layout: 'center', timeout: 2000 })
        }
      }
    }
  }
})
</script>

<template>
  <modal
    :title="modalTitle"
    @close="closeModal"
  >
    <div class="style-ozaria teacher-form">
      <span class="sub-title"> {{ subtitle }} </span>
      <form
        class="form-container"
        @submit.prevent="onClickSubmit"
      >
        <div
          class="form-group row name"
          :class="{ 'has-error': $v.name.$error }"
        >
          <div class="col-xs-12">
            <span class="control-label"> {{ $t('general.name') }} </span>
            <input
              v-model="$v.name.$model"
              type="text"
              class="form-control"
            >
            <span
              v-if="!$v.name.required"
              class="form-error"
            > {{ $t('form_validation_errors.required') }} </span>
          </div>
        </div>
        <div
          class="form-group row email"
          :class="{ 'has-error': $v.email.$error }"
        >
          <div class="col-xs-12">
            <span class="control-label"> {{ $t('general.email') }} </span>
            <input
              v-model="$v.email.$model"
              type="text"
              class="form-control"
            >
            <span
              v-if="!$v.email.required"
              class="form-error"
            > {{ $t('form_validation_errors.required') }} </span>
            <span
              v-if="!$v.email.email"
              class="form-error"
            > {{ $t('form_validation_errors.invalidEmail') }} </span>
          </div>
        </div>

        <div
          class="form-group row role"
          :class="{ 'has-error': $v.role.$error }"
        >
          <div class="col-xs-12">
            <span class="control-label"> {{ $t('apcsp_curriculum.role') }} </span>
            <input
              v-model="$v.role.$model"
              type="text"
              class="form-control"
            >
            <span
              v-if="!$v.role.required"
              class="form-error"
            > {{ $t('form_validation_errors.required') }} </span>
          </div>
        </div>
        <div
          class="form-group row message"
          :class="{ 'has-error': $v.message.$error }"
        >
          <div class="col-xs-12">
            <span class="control-label"> {{ $t('general.message') }} </span>
            <textarea
              v-model="$v.message.$model"
              rows="10"
              class="form-control"
            />
            <span
              v-if="!$v.message.required"
              class="form-error"
            > {{ $t('form_validation_errors.required') }} </span>
          </div>
        </div>
        <div class="form-group row">
          <div class="col-xs-12 buttons">
            <secondary-button
              v-if="!sendingInProgress"
              type="submit"
              :inactive="!isFormValid"
            >
              {{ $t('common.submit') }}
            </secondary-button>
            <secondary-button
              v-else-if="sendingInProgress"
              type="submit"
              :inactive="true"
            >
              {{ $t('common.sending') }}
            </secondary-button>
          </div>
        </div>
      </form>
    </div>
  </modal>
</template>

<style lang="scss" scoped>
$form-width: min(600px, 100vw - 60px);
@import "../../styles/modal";

.teacher-form {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  margin: 15px 15px 0px 15px;
  max-width: $form-width;
}

.sub-title {
  @include font-p-2-paragraph-medium-gray;
  font-weight: 600;
  color: $pitch;
}

.form-container {
  width: 100%;
  min-width: $form-width;
  margin-top: 10px;
}

.buttons {
  display: flex;
  flex-direction: row;
  justify-content: flex-end;
  align-items: flex-end;
  margin-top: 30px;

  button {
    width: 150px;
    height: 35px;
    margin: 0 10px;
  }
}
</style>
