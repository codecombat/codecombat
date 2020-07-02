<script>
  export default {
    props: {
      icon: {
        type: String,
        required: true,
        validator: value => ['PDF', 'Spreadsheet', 'Doc', 'FAQ', 'Slides', 'Solutions', 'Spreadsheet', 'Video'].indexOf(value) !== -1
      },
      label: {
        type: String,
        required: false,
        default: ''
      }
    },
    computed: {
      cssVariables () {
        return {
          '--backgroundImage': `url(/images/ozaria/teachers/dashboard/svg_icons/Icon${this.icon}.svg)`,
          '--backgroundImageHover': `url(/images/ozaria/teachers/dashboard/svg_icons/Icon${this.icon}Hover.svg)`
        }
      }
    }
  }
</script>

<template>
  <div class='resource-icon' :style="cssVariables">
    <div @clik="emit('click')" class='icon'/>
    <p v-if="label !== ''">{{ label }}</p>
  </div>
</template>

<style lang="scss" scoped>
  .resource-icon {
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    width: 150px;
    margin: 40px 10px;
  }
  .icon {
    width: 80px;
    height: 80px;
    cursor: pointer;

    background-image: var(--backgroundImage);

    &:hover {
      background-image: var(--backgroundImageHover);
    }
  }
  p {
    margin-top: 15px;
    font-family: 'Work Sans';
    font-size: 14px;
    line-height: 18px;
    text-align: center;
    letter-spacing: 0.27px;
  }
</style>
