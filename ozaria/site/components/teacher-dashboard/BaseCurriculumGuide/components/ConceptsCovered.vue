<script>
  export default {
    props: {
      conceptList: {
        type: Array,
        required: false,
        default: () => ([])
      }
    },
    computed: {
      shouldShow () {
        return this.conceptList?.length > 0
      }
    }
  }
</script>
<template>
  <div v-if="shouldShow">
    <h3>{{ $t('teacher.concepts_covered') }}</h3>
    <ul>
      <li
        v-for="text in conceptList"
        :key="text"
      >
        {{ $t(`concepts.${text}`) || text }}
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
    text-transform: capitalize;
  }

  ul {
    padding-left: 15px;
    margin-bottom: 30px;
  }

  li {
    @include font-p-3-paragraph-small-white;
    color: #545b64;
    font-size: 12px;
    line-height: 13px;
    text-align: left;
    margin-bottom: 6px
  }
</style>
