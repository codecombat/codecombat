<template>
  <div class="CTA">
    <ButtonA
      class="button-a-instance"
      property1="default"
      text="Download Schedule"
    />
    <p class="supporting-text">
      All experience details are subject to change.
    </p>
  </div>
</template>

<script>
import ButtonA from '../ButtonA'

export default {
  name: 'CtaComponent',
  components: {
    ButtonA
  }
}
</script>

<style scoped>
.CTA {
    align-items: center;
    display: inline-flex;
    flex-direction: column;
    gap: 8px;
    justify-content: center;
    position: relative;
}

.CTA .button-a-instance {
    flex: 0 0 auto !important;
    width: 258px !important;
}

.CTA .supporting-text {
    color: #4799A9;
    font-family: "Plus Jakarta Sans-Bold", Helvetica;
    font-size: 14px;
    font-weight: 700;
    letter-spacing: 0;
    line-height: 32px;
    position: relative;
    width: fit-content;
}
</style>
