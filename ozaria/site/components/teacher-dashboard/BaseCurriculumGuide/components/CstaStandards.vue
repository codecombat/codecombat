<script>
  import ButtonResourceIcon from '../../BaseResourceHub/components/ButtonResourceIcon'
  import { resourceHubLinks } from '../../common/constants.js'
  import utils from 'core/utils'

  export default {
    components: {
      ButtonResourceIcon
    },
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
      },

      cstaResourceData () {
        return resourceHubLinks.csta
      },

      translatedCstaList () {
        return this.cstaList.map(standard => ({
          name: utils.i18n(standard, 'name'),
          description: utils.i18n(standard, 'description')
        }))
      }
    }
  }
</script>

<template>
  <div v-if="shouldShow">
    <h3>{{ $t('teacher_dashboard.standards_alignment') }}</h3>
    <div class="flex">
      <button-resource-icon
        :icon="cstaResourceData.icon"
        :label="cstaResourceData.label"
        :link="cstaResourceData.link"
        from="Curriculum Guide"
      />
    </div>
    <p>{{ $t('teacher_dashboard.standards_sample') }}</p>
    <ul>
      <li
        v-for="{ name, description } in translatedCstaList"
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
    text-transform: capitalize;
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
