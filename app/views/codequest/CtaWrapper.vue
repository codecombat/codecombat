<template>
  <div class="cta-wrapper">
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

  .supporting-text {
    color: #4799A9;
    font-family: "Plus Jakarta Sans-Bold", Helvetica;
    font-size: 14px;
    font-weight: 700;
    letter-spacing: 0;
    line-height: 32px;
    position: relative;
    white-space: nowrap;
    width: fit-content;
  }
}
</style>
