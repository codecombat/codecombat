<template>
  <div class="add-user">
<!--    <div class="add-user__head">-->
<!--      <button-->
<!--        class="add-user__head__btn btn btn-moon"-->
<!--        @click="showAddUserForm"-->
<!--      >-->
<!--        Add Related User-->
<!--      </button>-->
<!--    </div>-->
    <form
      v-if="showAddForm"
      class="add-user__form u-form"
      @submit.prevent="onFormSubmit"
    >
      <div class="form-group row">
        <label
          for="u-form-email"
          class="u-form__label"
        >
          Related User Email
        </label>
        <input
          id="u-form-email"
          v-model="email"
          type="email"
          placeholder="Enter email"
          class="form-control"
          @blur="validateEmail"
        />
      </div>
      <div class="form-group row">
        <label
          for="u-form-relation"
          class="u-form__label"
        >
          Relation
        </label>
        <select
          id="u-form-relation"
          v-model="relation"
          class="form-control"
        >
          <option
            v-for="(option) in relationOptions"
            :key="option"
            :selected="relation === option"
          >
            {{ option }}
          </option>
        </select>
      </div>
      <div class="form-group row form-check">
        <input
          id="u-form-check"
          v-model="isBidirectional"
          type="checkbox"
          class="form-check-input"
        >
        <label
          class="u-form__check u-form__label"
          for="u-form-check"
        >
          Bi-directional
        </label>
      </div>
      <div class="form-group row auth">
        <div
          v-if="accountExists"
          class="auth__exists"
        >
          <div class="auth__exists-text">
            Account exists
          </div>
          <div class="form-group">
            <div class="form-check">
              <input class="form-check-input" type="radio" name="exampleRadios" id="exampleRadios1" value="authAndPass" v-model="existsAuthType">
              <label class="form-check-label" for="exampleRadios1">
                Authenticate using {{ email }} password
              </label>
            </div>
            <div class="form-check auth__additional" v-if="existsAuthType === 'authAndPass'">
              <input class="form-control" type="password" v-model="relatedPass" placeholder="Enter related user password">
            </div>
            <div class="form-check">
              <input class="form-check-input" type="radio" name="exampleRadios" id="exampleRadios2" value="authAndEmail" v-model="existsAuthType">
              <label class="form-check-label" for="exampleRadios2">
                Link account using confirmation email
              </label>
            </div>
            <div class="form-check auth__additional" v-if="existsAuthType === 'authAndEmail'">
              <p>
                User will receive a mail on {{ email }}. Please ask the user to confirm linking by pressing on link present in email.
              </p>
            </div>
          </div>
        </div>
        <div
          v-else-if="accountExists === false"
          class="auth__not-exists"
        >
          <div class="auth__exists-text auth__not-exists-text">
            Account does not exist
          </div>
          <div class="form-group">
            <div class="form-group">
              <label
                for="u-form-relation"
                class="u-form__label"
              >
                Account Type
              </label>
              <select
                id="u-form-relation"
                v-model="accountType"
                class="form-control"
              >
                <option
                  v-for="(option) in accountTypes"
                  :key="option"
                  :selected="accountType === option"
                >
                  {{ option }}
                </option>
              </select>
            </div>
            <div class="form-check">
              <input class="form-check-input" type="radio" name="exampleRadios" id="exampleRadios1" value="option1" checked>
              <label class="form-check-label" for="exampleRadios1">
                Create account and send email to link
              </label>
            </div>
          </div>
        </div>
        <div
          v-else
          class="auth__default"
        >
          <div class="form-check">
            <input class="form-check-input" type="radio" name="exampleRadios" id="exampleRadios1" value="option1" disabled>
            <label class="form-check-label" for="exampleRadios1">
              Authenticate / Invite
            </label>
          </div>
        </div>
      </div>
      <div class="form-group row u-form__submit">
        <button
          type="submit"
          class="btn btn-lg btn-success"
        >
          Submit
        </button>
      </div>
    </form>
  </div>
</template>

<script>
const utils = require('../../../core/utils')
const User = require('../../../models/User')
export default {
  name: 'AddUserComponent',
  data () {
    return {
      showAddForm: true,
      relationOptions: [
        'Kid',
        'Student',
        'Other'
      ],
      email: '',
      relation: 'Kid',
      isBidirectional: true,
      accountExists: null,
      accountTypes: [
        'Individual',
        'Student',
        'Teacher'
      ],
      accountType: 'Individual',
      existsAuthType: '',
      relatedPass: ''
    }
  },
  methods: {
    showAddUserForm () {
      this.showAddForm = true
    },
    onFormSubmit () {
      console.log('data', this.$data)
      // add validation code
      const body = {}
      const commonBody = {
        relatedUserEmail: this.email,
        relation: this.relation,
        isBidirectional: this.isBidirectional
      }
      if (this.accountExists) {
        body.verify = commonBody
        if (this.existsAuthType === 'authAndPass') {
          body.verify.relatedUserPassword = this.relatedPass
        } else {
          body.verify.sendLinkConfirmEmail = true
        }
      } else {
        body.unVerify = commonBody
        body.unVerify.userRole = this.accountType
      }
      this.$emit('onAddSwitchAccount', body)
    },
    async validateEmail () {
      this.accountExists = null
      if (utils.isValidEmail(this.email)) {
        const resp = await User.checkEmailExists(this.email)
        console.log('resp', resp)
        this.accountExists = resp?.exists
      }
    }
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/common/button";
.add-user {
  font-size: 1.8rem;

  &__head {
    text-align: center;
  }
}

.u-form {
  margin-top: 2rem;

  &__submit {
    float: right;
  }

  //&__label {
  //  font-size: 1.8rem;
  //}

  &__check {
    margin-left: 5px;
  }
}

.auth {
  &__default {
    color: #808080;
  }

  &__exists {
    &-text {
      color: #73A839;
      font-weight: bold;
      margin-bottom: 5px;
    }
  }

  &__not-exists {
    &-text {
      color: #0b63bc;
    }
  }

  &__additional {
    margin-bottom: 1rem;
  }
}
</style>
