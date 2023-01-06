<template>
  <a
      :href="href"
      @click="$emit('click')"
  >
    {{ buttonText }}
  </a>
</template>

<style scoped>

a {
  font-family: Work Sans;
  font-style: normal;
  font-weight: bolder;
  font-size: 20px;
  line-height: 16px;
  color: #131B25;

  min-width: 268px;
  min-height: 50px;

  padding: 16px 36px;

  background: #fcbb00;
  border-radius: 9.5px;
}

a:hover {
  background: #fcd200;
  text-decoration: none;
}

</style>

<script>
export default {
  props: {
    buttonText: {
      type: String,
      default: 'Schedule a Free Class'
    },
    href: {
      type: [String, Boolean],
      default: '#'
    }
  }
}
</script>
