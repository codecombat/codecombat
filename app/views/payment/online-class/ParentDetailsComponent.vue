<template>
  <div class="parent-details">
    <hr />
    <h4 class="parent-details-text">Parent Details</h4>
    <div class="form-group">
      <label for="parent-email">Email<span class="required-field"> *</span></label>
      <input type="text" :class="`form-control ${this.emailErrorClass}`" id="parent-email" placeholder="Enter Email" @keydown="updateEmail" @keyup="updateEmail" :value="email" />
    </div>
    <div class="form-group">
      <label for="parent-firstname">First Name<span class="required-field"> *</span></label>
      <input type="text" class="form-control" id="parent-firstname" placeholder="Enter First Name" @keydown="updateFirstName" @keyup="updateFirstName" :value="firstName" />
    </div>
    <div class="form-group">
      <label for="parent-lastname">Last Name</label>
      <input type="text" class="form-control" id="parent-lastname" placeholder="Enter Last Name" @keydown="updateLastName" @keyup="updateLastName" :value="lastName" />
    </div>
    <hr />
  </div>
</template>

<script>
import { validateEmail } from '../../../lib/common-utils'
export default {
  name: "PaymentOnlineClassesParentDetailsView",
  data () {
    return {
      email: me.get('email'),
      firstName: me.get('firstName'),
      lastName: me.get('lastName'),
      emailErrorClass: null,
    };
  },
  created() {
    // update parent details if user is logged in
    if (me.get('email')) {
      this.updateParentDetails()
    }
  },
  methods: {
    updateEmail(e) {
      this.emailErrorClass = '';
      const val = e.target.value;
      this.email = val;
      if (!validateEmail(val)) {
        this.emailErrorClass = 'error-border';
        return;
      }
      this.updateParentDetails();
    },
    updateFirstName(e) {
      this.firstName = e.target.value;
      this.updateParentDetails();
    },
    updateLastName(e) {
      this.lastName = e.target.value;
      this.updateParentDetails();
    },
    updateParentDetails() {
      // maybe use watch or something better to trigger this method
      if (this.email && this.firstName && !this.emailErrorClass) {
        this.$emit('updateParentDetails', {
          email: this.email,
          firstName: this.firstName,
          lastName: this.lastName
        });
      } else {
        this.$emit('updateParentDetails', null);
      }
    }
  },
}
</script>

<style lang="scss" scoped>
.parent-details-text {
  font-weight: bold;
  padding-bottom: 5px;
}
.error-border {
  border-color: red;
}
.required-field {
  color: red;
}
</style>
