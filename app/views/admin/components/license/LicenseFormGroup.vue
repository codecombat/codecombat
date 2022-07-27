<script>
export default {
  props: ['label', 'extra', 'value']
}
</script>
<template lang="pug">
  .form-group
    label
      span {{label}}
      =" "
      input(v-bind="$attrs", :value="value", @input="$emit('input', $event.target.value)")
      span(v-if="extra") {{extra}}
</template>

<style scoped>

</style>