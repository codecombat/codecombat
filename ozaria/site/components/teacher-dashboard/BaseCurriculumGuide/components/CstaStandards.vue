<script>
  import ButtonResourceIcon from '../../BaseResourceHub/components/ButtonResourceIcon'
  export default {
    props: {
      cstaList: {
        type: Array,
        required: false,
        default: () => ([])
      }
    },
    components: {
      ButtonResourceIcon
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
    <h3>Standards Alignment</h3>
    <div class="flex">
      <button-resource-icon icon="PDF" label="CSTA Standards Alignment"/>
    </div>
    <p>A sample of the standards covered in this Chapter:</p>
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

  p {
    font-weight: 600;
    font-size: 14px;
    line-height: 16px;
    margin-bottom: 15px;
  }

  .flex {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 100%;
    .resource-icon {
      margin: 10px 10px;
    }
  }
</style>
