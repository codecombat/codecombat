<script>
  import ContentIcon from '../../common/icons/ContentIcon'
  export default {
    components: {
      ContentIcon
    },

    props: {
      iconType: {
        type: String,
        required: true,
        validator: value => ['cutscene', 'cinematic', 'capstone', 'interactive', 'practicelvl', 'challengelvl'].indexOf(value) !== -1
      },

      displayName: {
        type: String,
        required: true
      },

      description: {
        type: String,
        required: false,
        default: ''
      }
    },

    computed: {
      getContentTypeHeader () {
        switch (this.iconType) {
        case `cutscene`:
          return 'Cutscene'
        case `cinematic`:
          return `Cinematic`
        case `capstone`:
          return `Capstone`
        case `interactive`:
          return `Concept Check`
        case `practicelvl`:
          return `Practice Level`
        case `challengelvl`:
          return `Challenge Level`
        default:
          return ``
        }
      }
    }
  }
</script>
<template>
  <div class="module-row" @click="$emit('click')">
    <content-icon class="content-icon" :icon="iconType" />
    <p><b>{{ getContentTypeHeader }}: {{ displayName }}</b></p>
    <p>{{ description }}</p>
  </div>
</template>

<style lang="scss" scoped>
  @import "app/styles/bootstrap/variables";
  @import "ozaria/site/styles/common/variables.scss";
  @import "app/styles/ozaria/_ozaria-style-params.scss";

  .module-row {
    min-width: 30px;

    display: flex;
    flex-direction: row;
    align-items: center;

    padding-top: 5px;
    padding-bottom: 5px;

    cursor: pointer;
  }

  .module-row:hover {
    border: 1px solid #74C6DF;
  }

  .content-icon {
    margin: 0 15px;
  }

  p {
    @include font-p-3-paragraph-small-white;
    color: $pitch;
    font-size: 12px;
    line-height: 13px;
    text-align: left;

    margin-bottom: -3px;
    margin-right: 15px;
  }
</style>
