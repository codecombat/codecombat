<template>
  <div class="add-user">
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
          {{ $t('related_accounts.related_email') }}
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
          {{ $t('related_accounts.relation') }}
        </label>
        <select
          id="u-form-relation"
          v-model="relation"
          class="form-control"
        >
          <option value="" selected disabled>Please select</option>
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
          {{ $t('related_accounts.bi_directional') }} <span class="u-form__bi-dir-help">({{ $t('related_accounts.bi_directional_help_text') }})</span>
        </label>
      </div>
      <div class="form-group row auth">
        <div
          v-if="accountExists"
          class="auth__exists"
        >
          <div class="auth__exists-text">
            {{ $t('related_accounts.account_exists') }}
          </div>
          <div class="form-group">
            <div class="form-check">
              <input class="form-check-input" type="radio" name="exampleRadios" id="exampleRadios1" value="authAndPass" v-model="existsAuthType">
              <label class="form-check-label" for="exampleRadios1">
                {{ $t('related_accounts.auth_using_pass', { email }) }}
              </label>
            </div>
            <div class="form-check auth__additional" v-if="existsAuthType === 'authAndPass'">
              <input class="form-control" type="password" v-model="relatedPass" placeholder="Enter related user password">
            </div>
            <div class="form-check">
              <input class="form-check-input" type="radio" name="exampleRadios" id="exampleRadios2" value="authAndEmail" v-model="existsAuthType">
              <label class="form-check-label" for="exampleRadios2">
                {{ $t('related_accounts.link_using_email') }}
              </label>
            </div>
            <div class="form-check auth__additional" v-if="existsAuthType === 'authAndEmail'">
              <p>
                {{ $t('related_accounts.link_using_email_blurb', { email }) }}
              </p>
            </div>
          </div>
        </div>
        <div
          v-else-if="accountExists === false"
          class="auth__not-exists"
        >
          <div class="auth__exists-text auth__not-exists-text">
            {{ $t('related_accounts.account_not_exist') }}
          </div>
          <div class="form-group">
            <div class="form-group">
              <label
                for="u-form-relation"
                class="u-form__label"
              >
                {{ $t('related_accounts.account_type') }}
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
              <input class="form-check-input" type="radio" name="exampleRadios" id="exampleRadios1" value="option1" checked disabled>
              <label class="form-check-label" for="exampleRadios1">
                {{ $t('related_accounts.create_account_and_email') }}
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
              {{ $t('related_accounts.authenticate') }} / {{ $t('related_accounts.invite') }}
            </label>
          </div>
        </div>
      </div>
      <div class="form-group row u-form__submit">
        <span
          v-if="errMsg"
          class="error"
        >
          {{ errMsg }}
        </span>
        <button
          type="submit"
          class="btn btn-lg btn-success"
          :disabled="accountCheckedEmail !== email"
        >
          {{ $t('common.submit') }}
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
      relation: '',
      isBidirectional: true,
      accountExists: null,
      accountTypes: [
        'Individual',
        'Student',
        'Teacher'
      ],
      accountType: 'Individual',
      existsAuthType: '',
      relatedPass: '',
      errMsg: '',
      accountCheckedEmail: null
    }
  },
  methods: {
    showAddUserForm () {
      this.showAddForm = true
    },
    onFormSubmit () {
      if (!this.validate()) return
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
    validate () {
      this.errMsg = null
      if (!this.email) {
        this.errMsg = 'Email required'
        return false
      }
      if (!this.relation) {
        this.errMsg = 'Relation required'
        return false
      }
      if (this.accountCheckedEmail !== this.email) {
        this.errMsg = 'Checking if account exists, try again in few seconds'
        return false
      }
      if (me.get('email') === this.email) {
        this.errMsg = 'Cannot add your own account'
        return false
      }
      if (this.accountExists) {
        if (!this.existsAuthType) {
          this.errMsg = 'Authenticate using one of the options!!'
          return false
        }
      }
      return true
    },
    async validateEmail () {
      this.accountExists = null
      if (utils.isValidEmail(this.email)) {
        const resp = await User.checkEmailExists(this.email)
        this.accountExists = resp?.exists
        this.accountCheckedEmail = this.email
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

  &__check {
    margin-left: 5px;
  }

  &__bi-dir-help {
    color: #a9a9a9;
    font-size: 1.5rem;
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

.error {
  font-size: 1.5rem;
  color: #ff0000;
  padding-right: 3px;
}
</style>
