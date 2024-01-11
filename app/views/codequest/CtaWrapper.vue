<template>
  <div class="cta-wrapper">
    <div class="jumbotron">
      <p class="supporting-text supporting-text-normal">
        The specifics regarding the planned series of activities are subject to changes due. We commit to keeping you informed of such changes as much as possible, although they may occur without advance notice.
      </p>
    </div>
    <ButtonA
      class="contact-modal button-a-instance"
      text="Contact Our Team"
    />
    <p class="supporting-text">
      If you have any questions
    </p>
  </div>
</template>

<script>
import ButtonA from './ButtonA'

export default {
  name: 'CtaComponent',
  components: {
    ButtonA
  }
}
</script>

<style scoped lang="scss">
.cta-wrapper {
  align-items: center;
  display: flex;
  flex-direction: column;
  gap: 8px;
  justify-content: center;
  padding: 80px 0px 160px;
  position: relative;

  .button-a-instance {
    flex: 0 0 auto !important;
    width: 258px !important;
  }

  .jumbotron {
    box-shadow: 0px 0px 22px rgba(0, 0, 0, 0.1490196078);
    background: linear-gradient(90deg, rgb(245, 255, 255) 0%, rgb(255, 255, 255) 100%);
    border-radius: 24px;
  }

  .supporting-text {
    color: #4799A9;
    font-family: "Plus Jakarta Sans-Bold", Helvetica;
    font-size: 14px;
    font-weight: 700;
    letter-spacing: 0;
    line-height: 32px;
    position: relative;
    white-space: nowrap;
    &.supporting-text-normal {
      font-weight: 400;
      line-height: 30px;
      white-space: normal;
    }
  }
}
</style>
