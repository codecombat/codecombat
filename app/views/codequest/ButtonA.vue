<template>
  <a
    class="button-a"
    target="_blank"
  >
    <div class="text">{{ text }}</div>
  </a>
</template>

<script>
export default {
  name: 'ButtonA',
  props: {
    text: {
      type: String,
      default: 'Button_A'
    }
  }
}
</script>

<style scoped lang="scss">
.button-a {
  align-items: center;
  border-radius: 8px;
  display: flex;
  gap: 8px;
  justify-content: center;
  overflow: hidden;
  padding: 12px 20px;
  position: relative;
  width: 160px;
  cursor:pointer;
  text-decoration: none;
}

.button-a .text {
  color: #111928;
  font-family: "Plus Jakarta Sans-ExtraBold", Helvetica;
  font-size: 18px;
  font-weight: 800;
  letter-spacing: 0;
  line-height: 24px;
  margin-top: -1px;
  position: relative;
  white-space: nowrap;
  width: fit-content;
  text-decoration: none;
}

.button-a {
  background: #4DECF0;
}

</style>
