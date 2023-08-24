<template>
  <svg
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 44 44"
  >
    <g
      fill="none"
      fill-rule="evenodd"
      stroke-width="2"
      class="jsx-3467701036"
    >
      <circle
        cx="22"
        cy="22"
        r="19.4775"
        class="jsx-3467701036"
      >
        <animate
          attributeName="r"
          begin="0s"
          dur="1.8s"
          values="1; 20"
          calcMode="spline"
          keyTimes="0; 1"
          keySplines="0.165, 0.84, 0.44, 1"
          repeatCount="indefinite"
        />
        <animate
          attributeName="stroke-opacity"
          begin="0s"
          dur="1.8s"
          values="1; 0"
          calcMode="spline"
          keyTimes="0; 1"
          keySplines="0.3, 0.61, 0.355, 1"
          repeatCount="indefinite"
        />
      </circle>
      <circle
        cx="22"
        cy="22"
        r="11.8787"
        class="jsx-3467701036"
      >
        <animate
          attributeName="r"
          begin="-0.9s"
          dur="1.8s"
          values="1; 20"
          calcMode="spline"
          keyTimes="0; 1"
          keySplines="0.165, 0.84, 0.44, 1"
          repeatCount="indefinite"
        />
        <animate
          attributeName="stroke-opacity"
          begin="-0.9s"
          dur="1.8s"
          values="1; 0"
          calcMode="spline"
          keyTimes="0; 1"
          keySplines="0.3, 0.61, 0.355, 1"
          repeatCount="indefinite"
        />
      </circle>
    </g>
  </svg>
</template>

<script>
export default {
  name: 'LoadingTile'
}
</script>

<style scoped>
svg {
  display: block;
  height: 36px;
  width: 36px;
  stroke: #fff;
}
</style>
