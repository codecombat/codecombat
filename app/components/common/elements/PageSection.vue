<template>
  <div class="page-section">
    <div class="frame">
      <div class="heading">
        <slot name="heading" />
      </div>
      <div class="body">
        <slot name="body" />
      </div>
      <div class="tail">
        <slot name="tail" />
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'PageSection',
  props: {
    styles: {
      type: Object,
      required: false,
      default: () => ({})
    }
  },
}
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";
@import "app/styles/component_variables.scss";

.page-section {
  align-items: center;
  display: flex;
  flex-direction: column;
  gap: 40px;
  justify-content: center;
  padding: 100px 135px;
  position: relative;

  @media (max-width: $screen-md-max) {
    padding: 100px 40px;
  }

  .frame {
    align-items: center;
    display: inline-flex;
    flex: 0 0 auto;
    flex-direction: column;
    gap: 80px;
    justify-content: center;
    position: relative;
    width: 100%;
  }

  .heading {
    @extend %font-36;
    position: relative;
    text-align: center;
  }

  .body {
    align-items: flex-start;
    display: inline-flex;
    flex: 0 0 auto;
    flex-direction: column;
    gap: 0;
    position: relative;
    width: 100%;
  }

  .tail {
    @extend %font-28;
    position: relative;
    text-align: center;
  }
}
</style>
