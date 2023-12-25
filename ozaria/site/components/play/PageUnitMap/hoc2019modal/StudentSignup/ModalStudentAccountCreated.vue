<script>
export default {
  computed: {
    username () {
      return me.get('name')
    },
    email () {
      return me.get('email')
    }
  }
}
</script>

<template lang="pug">
  .modal-dialog.style-ozaria#modal-student-account-created
    h2 Create Student Account
    h4.m-y-1 {{$t("signup.account_created")}}

    .confirm_container.text-center.m-y-1
      p.medium-gray {{ $t("signup.confirm_student_blurb") }}

    .signup-info-box-wrapper
      p.medium-gray {{ $t("signup.write_this_down") }}
      .signup-info-box.text-center
        p.large-gray(v-if="username")
          b
            span {{ $t("general.username") }}
            | : {{ username }}
        p.large-gray(v-if="email")
          b
            //- Current assumption is that the email is only retrieved if gplus is used.
            img.m-r-1(src="/images/pages/modal/auth/gplus_small.png")
            span {{ email }}

    .text-center
      button.ozaria-btn.m-t-3(@click="$emit('done')") {{ $t("courses.continue_playing") }}

</template>

<style lang="scss" scoped>
@import "app/styles/mixins";
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/common.scss";

#modal-student-account-created {
  padding: 42px 64px;
  width: 680px;
  border-radius: 8px;
  background-color: rgba(255,255,255,0.95);
  box-shadow: -20px -10px 50px 0 rgba(64,243,228,0.3), 20px 10px 50px 0 rgba(64,243,228,0.3);

  text-align: left;

  h2, h4 {
    color: $pitch;
    text-align: center;
    padding-bottom: 20px;
  }
  h2 {
    margin-top: 0;
  }

  .ozaria-btn {
    text-shadow: unset;
    font-family: Work Sans, "Open Sans", sans-serif;
    font-size: 16px;
    font-weight: 600;
    letter-spacing: 0.32px;
    line-height: 22px;
    min-height: 22px;
    min-width: 261px;
    padding: 10px 20px;

    color: $pitch;
    background-image: unset;
    background-color: $dusk;
    border: unset;

    margin-top: 40px;

    &:hover {
      background-color: $dusk-dark;
    }
  }

  p {
    color: $pitch;
  }

  .confirm_container {
    width: 100%;
  }

  .signup-info-box-wrapper {
    width: 100%;
  }

  .signup-info-box {
    padding: 10px 20px;
    border: 2px solid $dusk;

    p {
      margin: 0;
    }
  }
  .modal-body-content {
    width: 80%;
    margin-left: 10%;
  }
}
</style>
