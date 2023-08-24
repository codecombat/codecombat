<template>
  <div class="no-video">
    <p>{{ username }}</p>
  </div>
</template>

<script>
export default {
  name: 'NoVideoTile',
  props: ['username']
}
</script>

<style>
.no-video {
  background-color: #2b3f56;
  border-radius: 16px;
  aspect-ratio: 16/9;
  color: #fff;
  position: relative;
  display: flex;
  height: 100%;
  justify-content: center;
  align-items: center;
  padding: 2px 0;
}
</style>
