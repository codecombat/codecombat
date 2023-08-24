<template>
  <div class="card">
    <h2>Waiting for others!</h2>
    <h3>Invite someone by sharing this link:</h3>
    <p>{{ url }}</p>
  </div>
</template>

<script>
export default {
  name: 'WaitingCard',
  props: ['url']
}
</script>

<style scoped>
.card {
  background-color: #2b3f56;
  border-radius: 16px;
  margin: 10px 20px;
  max-width: 50%;
  flex: 1 1 350px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 2px 0;
  aspect-ratio: 16/9;
}
.card h2 {
  color: #1bebb9;
  margin: 2px 0;
}
.card h3 {
  color: #fff;
  margin: 2px 0;
}
.card p {
  color: #fff;
  margin: 16px 0 0;
  font-size: 12px;
}
@media screen and (max-width: 700px) {
  .card {
    max-width: 100%;
    margin: 10px 20px;
  }
}
</style>
