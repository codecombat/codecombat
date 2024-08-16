<template>
  <div class="loading-indicator">
    <span class="spinner" />
  </div>
</template>

<script>

export default {
  name: 'LoadingSpinner'
}
</script>

<style scoped lang="scss">
@import 'ozaria/site/styles/common/variables.scss';

.spinner {
    border: 16px solid #f3f3f3;
    border-top: 16px solid $moon;
    border-radius: 50%;
    width: 120px;
    height: 120px;
    animation: spin 2s linear infinite;
    display: block;
}

@keyframes spin {
    from {
        transform: rotate(0deg);
    }

    to {
        transform: rotate(360deg);
    }
}
</style>