<script>
  export default {
    props: {
      cstaList: {
        type: Array,
        required: false,
        default: () => ([])
      }
    },
    computed: {
      shouldShow () {
        return this.cstaList?.length > 0
      }
    }
  }
</script>

<template>
  <div v-if="shouldShow">
    <h3>CSTA Standards</h3>
    <p>Designed to align to the following CSTA Standards:</p>
    <ul>
      <li
        v-for="{ name, description } in cstaList"
        :key="name"
      >
        <b>{{ name }}</b>: {{ description }}
      </li>
    </ul>
  </div>
</template>

<style lang="scss" scoped>
  @import "app/styles/bootstrap/variables";
  @import "ozaria/site/styles/common/variables.scss";
  @import "app/styles/ozaria/_ozaria-style-params.scss";

  h3 {
    @include font-p-3-small-button-text-black;
    text-align: left;
    margin-bottom: 10px;
  }

  ul {
    padding-left: 15px;
  }

  li, p {
    @include font-p-3-paragraph-small-white;
    color: #545b64;
    font-size: 12px;
    line-height: 13px;
    text-align: left;
    margin-bottom: 6px
  }
</style>
