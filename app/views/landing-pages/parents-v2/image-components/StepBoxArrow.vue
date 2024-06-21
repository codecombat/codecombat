<template>
  <svg
    xmlns="http://www.w3.org/2000/svg"
    width="76"
    height="45"
    viewBox="0 0 76 45"
    fill="none"
  >
    <path
      d="M3 19.4385C1.34315 19.4385 0 20.7816 0 22.4385C0 24.0953 1.34315 25.4385 3 25.4385V19.4385ZM75.1213 24.5598C76.2929 23.3882 76.2929 21.4887 75.1213 20.3172L56.0294 1.22527C54.8579 0.0536995 52.9584 0.0536995 51.7868 1.22527C50.6152 2.39685 50.6152 4.29634 51.7868 5.46791L68.7574 22.4385L51.7868 39.409C50.6152 40.5806 50.6152 42.4801 51.7868 43.6517C52.9584 44.8233 54.8579 44.8233 56.0294 43.6517L75.1213 24.5598ZM3 25.4385H73V19.4385H3V25.4385Z"
    />
  </svg>
</template>

<script>
export default {
  name: 'TextBubbleComponent',
}
</script>

<style scoped lang="scss">
@import 'app/styles/component_variables.scss';

svg {
  fill: var(--color-primary);
}
</style>