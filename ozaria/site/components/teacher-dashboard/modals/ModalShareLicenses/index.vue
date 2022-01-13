<script>
  import { validationMixin } from 'vuelidate'
  import { required, email } from 'vuelidate/lib/validators'
  import Modal from '../../../common/Modal'
  import PrimaryButton from '../../common/buttons/PrimaryButton'
  import SecondaryButton from '../../common/buttons/SecondaryButton'
  import SharedPoolRow from './SharedPoolRow'
  import ModalDivider from '../../../common/ModalDivider'
  import { mapActions, mapGetters } from 'vuex'
  import User from 'app/models/User'

  export default Vue.extend({
    components: {
      Modal,
      PrimaryButton,
      SecondaryButton,
      SharedPoolRow,
      ModalDivider
    },
    mixins: [validationMixin],
    props: {
      prepaid: {
        type: Object,
        default: () => {},
        required: true
      }
    },

    data: () => ({
      teacherEmailInput: ''
    }),

    validations: {
      teacherEmailInput: {
        required,
        email
      }
    },

    computed: {
      ...mapGetters({
        getJoinersForPrepaid: 'prepaids/getJoinersForPrepaid',
        getUserById: 'users/getUserById',
        getTrackCategory: 'teacherDashboard/getTrackCategory'
      }),

      sharedPoolForPrepaid () {
        const owner = this.getUserById(this.prepaid.creator) || {}
        const joiners = this.getJoinersForPrepaid(this.prepaid._id).concat(owner)

        const licensesUsedMap = {}
        const redeemers = this.prepaid.redeemers || []
        redeemers.forEach((r) => {
          const teacherId = r.teacherID || this.teacherId
          if (!licensesUsedMap[teacherId]) {
            licensesUsedMap[teacherId] = 1
          } else {
            licensesUsedMap[teacherId] = licensesUsedMap[teacherId] + 1
          }
        })

        joiners.forEach((j) => {
          j.licensesUsed = licensesUsedMap[j._id] || 0
        })

        joiners.sort((a, b) => (a.licensesUsed > b.licensesUsed) ? -1 : 1) // sort by descending order of licenses used

        return joiners
      }
    },

    methods: {
      ...mapActions({
        addJoinerForPrepaid: 'prepaids/addJoinerForPrepaid'
      }),

      broadName(teacher) {
        return User.broadName(teacher);
      },

      async addTeacher () {
        if (!this.$v.$invalid) {
          window.tracker?.trackEvent('My Licenses: Add Teacher Clicked from Share modal', { category: this.getTrackCategory })
          try {
            await this.addJoinerForPrepaid({ prepaidId: this.prepaid._id, email: this.teacherEmailInput })
            window.tracker?.trackEvent('My Licenses: Add Teacher Success from Share modal', { category: this.getTrackCategory })
          } catch (err) {
            console.error("Error in adding teacher:", err)
            noty({ text: "Error in adding teacher", type: "error", layout: "topCenter", timeout: 5000 })
          }
        }
      }
    }
  })
</script>

<template>
  <modal
    :title="$t('share_licenses.share_licenses')"
    @close="$emit('close')"
  >
    <div class="share-licenses">
      <div class="share-licenses-info">
        <span class="sub-title"> {{$t('share_licenses.modal_subtitle')}} </span>
        <ul class="info-list">
          <li class="list-item"> {{$t('share_licenses.modal_list_item_1')}} </li>
          <li class="list-item"> {{$t('share_licenses.modal_list_item_2')}} </li>
        </ul>
      </div>
      <div class="style-ozaria teacher-form">
        <div class="form-container">
          <div
            class="form-group row teacher-email-input"
            :class="{ 'has-error': $v.teacherEmailInput.$error }"
          >
            <div class="col-xs-12">
              <span class="control-label"> {{ $t("share_licenses.add_teacher_label") }} </span>
              <input
                v-model="$v.teacherEmailInput.$model"
                type="text"
                class="form-control"
              >
              <span
                v-if="!$v.teacherEmailInput.email"
                class="form-error"
              > {{ $t("form_validation_errors.invalidEmail") }} </span>
            </div>
          </div>
          <div class="form-group row add-button">
            <div class="col-xs-12">
              <primary-button
                @click="addTeacher"
              >
                {{ $t("share_licenses.add_teacher_button") }}
              </primary-button>
            </div>
          </div>
        </div>
      </div>
      <modal-divider
        :with-or-text="false"
      />
      <div class="shared-pool-div">
        <span class="sub-title"> {{ $t("share_licenses.shared_pool_label") }} </span>
        <shared-pool-row
          v-for="teacher in sharedPoolForPrepaid"
          :key="teacher._id"
          class="shared-pool-div-row"
          :name="broadName(teacher)"
          :email="teacher.email"
          :licenses-used="teacher.licensesUsed"
          :prepaid="prepaid"
        />
      </div>
      <div class="buttons">
        <secondary-button
          @click="$emit('close')"
        >
          {{ $t("common.done") }}
        </secondary-button>
      </div>
    </div>
  </modal>
</template>

<style lang="scss" scoped>
@import "app/styles/ozaria/_ozaria-style-params.scss";
@import "ozaria/site/styles/common/variables.scss";

.share-licenses {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  margin: 20px;
  width: 600px;
}

.sub-title {
  @include font-p-2-paragraph-medium-gray;
  font-weight: 600;
  color: $pitch;
}

.info-list {
  margin: 15px -20px;
}

.list-item {
  @include font-p-3-paragraph-small-gray;
  margin: 5px 0px;
}

.teacher-form {
  width: 100%;
}

.form-container {
  width: 100%;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}

.teacher-email-input {
  width: 100%;
}

.add-button {
  align-self: flex-start;

  button {
    width: 200px;
    height: 35px;
    margin: 0 10px;
  }
}

.shared-pool-div {
  width: 100%;
  margin-top: 20px;
}

.shared-pool-div-row {
  margin: 10px 0px;
}

.buttons {
  align-self: flex-end;
  display: flex;
  margin-top: 30px;

  button {
    width: 200px;
    height: 35px;
    margin: 0 10px;
  }
}

</style>
