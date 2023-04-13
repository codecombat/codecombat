<template>
  <div class="resources">
    <div class="resources__text">Resources</div>
    <div class="resources__btns">
      <div class="resource resources__slides">
        <span class="resource__text">Lesson Slides</span>
        <img src="/images/ozaria/teachers/dashboard/svg_icons/IconComputer.svg" alt="Slides icon" class="resource__icon resource__slides">
      </div>
      <div class="resource resources__project">
        <span class="resource__text">Project Rubric</span>
        <img src="/images/ozaria/teachers/dashboard/svg_icons/IconRubric.svg" alt="Project Rubric icon" class="resource__icon resource__project">
      </div>
      <div class="resource resources__exemplar">
        <span class="resource__text">Exemplar Project</span>
        <img src="/images/ozaria/teachers/dashboard/svg_icons/IconExemplarProject.svg" alt="Example project icon" class="resource__icon resource__exemplar">
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ModuleResources'
}
</script>

<style scoped lang="scss">
.resources {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  flex-direction: column;
  padding: 2rem;

  &__text {
    font-weight: 500;
    font-size: 1.6rem;
    line-height: 3rem;
    letter-spacing: 0.444444px;
    text-transform: uppercase;

    border-bottom: 1px solid #D8D8D8;
    padding: .5rem;
    width: 100%;
    align-self: flex-start;
  }

  &__btns {
    display: flex;
    flex-direction: column;
  }
}

.resource {
  border: 1px solid #476FB1;
  border-radius: 8px;
  padding: .5rem 2rem;
  position: relative;

  &:not(:last-child) {
    margin-bottom: 2rem;
  }

  &:first-child {
    margin-top: 2rem;
  }

  &__text {
    font-weight: 600;
    font-size: 1.6rem;
    line-height: 1.7rem;
    letter-spacing: 0.333333px;
  }

  &__icon {
    position: absolute;
    top: -20%;
    right: -10%;

    width: 3rem;
    height: 2rem;
  }

  &__exemplar, &__project {
    background-color: #f7d047;
  }

  &__slides {
    background-color: #5DB9AC;
  }
}
</style>
