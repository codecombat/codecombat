
<script>
  import PrimaryButton from './PrimaryButton'
  export default {
    components: {
      'primary-button': PrimaryButton
    },
    props: {
      iconName: {
        type: String,
        required: true,
        default: ''
      },
      iconStyle: {
        type: String,
        default: ''
      },
      link: {
        type: String,
        default: null
      }
    }
  }
</script>

<template>
  <a
    v-if="link"
    :href="link"
    target="_blank"
    rel="noreferrer"
  >
    <primary-button
      class="btn-icon"
    >
      <img
        :src="'/images/ozaria/teachers/dashboard/svg_icons/'+iconName+'.svg'"
        :style="iconStyle"
      >
    </primary-button>
  </a>
  <primary-button
    v-else
    class="btn-icon"
  >
    <img
      :src="'/images/ozaria/teachers/dashboard/svg_icons/'+iconName+'.svg'"
      :style="iconStyle"
    >
  </primary-button>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

.btn-icon {
  height: 30px;
  width: 30px;
  border-radius: 4px;
  margin: 5px;
  display: flex;
  align-items: center;
  justify-content: center;
}
</style>
