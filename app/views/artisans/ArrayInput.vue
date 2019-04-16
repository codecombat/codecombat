<template lang="pug">
div.arrayinput
  span [
  select(
    v-for="item,index in value"
    v-bind:key="index"
    v-model="value[index]"
    @input="updateValue"
  )
    option(
      v-for="v,i in enumList"
      v-bind:key="i"
    ) {{ v }}
  span ]
  button.btn(v-on:click="addNewItem") +
  button.btn(v-on:click="popItem" v-if="value.length > 0") -
</template>

<script lang="coffee">
module.exports = Vue.extend({
  props: {
    value: { required: true, type: Array, default: -> [] },
    enumList: { required: true, type: Array }
  }
  methods:
    addNewItem: ->
      @value.push(@enumList[0])
      @updateValue()
    popItem: ->
      @value.pop()
      @updateValue()
    updateValue: ->
      @$emit('input', @value)
})

</script>

<style lang="sass">
.arrayinput
  flex-wrap: wrap
  select
    max-width: 200px
    font-size: 90%
</style>
