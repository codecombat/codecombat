<template>
  <div class="clan-form form-group">
    <!-- Input Group with Button -->
    <div class="input-group input-group-xs">
      <span class="input-group-addon">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="14"
          height="14"
          fill="currentColor"
          class="bi bi-search"
          viewBox="0 0 16 16"
        >
          <path d="M11.742 10.344a6.5 6.5 0 1 0-1.397 1.398h-.001c.03.04.062.078.098.115l3.85 3.85a1 1 0 0 0 1.415-1.414l-3.85-3.85a1.007 1.007 0 0 0-.115-.1zM12 6.5a5.5 5.5 0 1 1-11 0 5.5 5.5 0 0 1 11 0z" />
        </svg>
      </span>
      <input
        type="text"
        class="form-control"
        placeholder="Search teams"
      >
    </div>
  </div>
</template>

<script>
export default {
}
</script>

<style scoped lang="scss">
/* Custom extra-small input group */
.input-group-xs > .form-control,
.input-group-xs > .input-group-addon,
.input-group-xs > .input-group-btn > .btn {
  height: 30px;
  font-size: 12px;
  line-height: 1;
}

.input-group-xs > .input-group-addon {
  padding: 4px 8px;
}
.clan-form {
  font-size: 18px;
  line-height: 26px;
  justify-items: center;
  margin-top: 20px;

  .input-group {
    width: 70%;
  }
}
</style>