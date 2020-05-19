
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
      }
    }
  }
</script>

<template>
  <primary-button
    class="btn-icon"
    @click="$emit('click')"
  >
    <img :src="'/images/ozaria/teachers/dashboard/svg_icons/'+iconName+'.svg'">
  </primary-button>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

.btn-icon {
  height: 30px;
  border-radius: 4px;
  margin: 5px;
}
</style>
