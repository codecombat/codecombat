<script>
import ClassSummaryRow from './components/ClassSummaryRow'
import ClassChapterSummaries from './components/ClassChapterSummaries'
import utils from 'core/utils'

export default {
  components: {
    ClassSummaryRow,
    ClassChapterSummaries,
  },
  props: {
    classroomStats: {
      type: Object,
      required: true
    },
    chapterStats: {
      type: Array,
      required: true
    },
    displayOnly: {
      type: Boolean,
      default: false
    }
  },

  computed: {
    showEsportsCampInfoCoCo () {
      return utils.isCodeCombat && me.isCodeNinja() && !this.chapterStats.length
    },

    showEsportsCampInfoOz () {
      return utils.isOzaria && me.isCodeNinja() && this.chapterStats.length === 2
    },

    showJuniorCampInfo () {
      return utils.isCodeCombat && me.isCodeNinja() && this.chapterStats.length === 1
    },
  }
}
</script>

<template>
  <div class="class-component">
    <class-summary-row
      :class-id="classroomStats.id"
      :classroom-name="classroomStats.name"
      :language="classroomStats.language"
      :num-students="classroomStats.numberOfStudents"
      :date-created="classroomStats.classroomCreated"
      :date-start="classroomStats.classDateStart"
      :date-end="classroomStats.classDateEnd"
      :code-camel="classroomStats.codeCamel"
      :archived="classroomStats.archived"
      :display-only="displayOnly"
      :share-permission="classroomStats.sharePermission"
      @clickTeacherArchiveModalButton="$emit('clickTeacherArchiveModalButton')"
      @clickAddStudentsModalButton="$emit('clickAddStudentsModalButton')"
      @clickShareClassWithTeacherModalButton="$emit('clickShareClassWithTeacherModalButton')"
    />
    <!--
      can be enabled for shared once in addition to fetchCourseInstancesForTeacher, we do it for all shared class whose owner is not this logged in teacher
    -->
    <class-chapter-summaries
      v-if="!classroomStats.sharePermission"
      :chapter-progress="chapterStats"
    />
    <div v-if="showEsportsCampInfoCoCo || showEsportsCampInfoOz">
      <b>Esports Camp Quick Links</b>
      <!-- TODO: break down by day? Or just generally give some sort of reinforcement of the camp's intended pacing. -->
      <ul class="list-inline">
        <li>
          <!-- TODO: sensei guide -->
          <a
            href="???"
            class="btn btn-primary"
          >Sensei Guide</a>
        </li>
        <li v-if="showEsportsCampInfoCoCo">
          <a
            href="https://www.ozaria.com/teachers/classes/"
            class="btn btn-primary"
          >Ozaria Chapters 1+2</a>
        </li>
        <li>
          <!-- TODO: this button can't customize its text, need to use a more general one
          <span
            v-tooltip.top="{
                           content: 'Click here to see lesson slides for camp day 1, covering Ozaria Chapter 1',
                           classes: 'teacher-dashboard-tooltip lighter-p',
                           autoHide: false
                           }"
          >
            <button-slides
              class="margin-right"
              link="https://docs.google.com/presentation/d/1KgFOg2tqbKEH8qNwIBdmK2QbHvTsxnW_Xo7LvjPsxwE/edit?usp=sharing"
            />
          </span>
          -->
          <a
            href=""
            target="_blank"
            class="btn btn-primary"
          >Chapter 1 Slides</a>
        </li>
        <li>
          <a
            href="https://drive.google.com/drive/folders/1u78qNwBmGXkKxw3qzqSimoUbMCNv_IMn?usp=sharing"
            target="_blank"
            class="btn btn-primary"
          >Chapter 2 Slides</a>
        </li>
        <li>
          <!-- TODO: specific tournament link -->
          <a
            href="/play/ladder/equinox/clan/65fa5bc654652e2ad959548e?tournament=65fcadac32f2005645fba16b"
            class="btn btn-primary"
          >Equinox Arena</a>
        </li>
        <li>
          <a
            href="https://drive.google.com/drive/folders/16lYF5Bt_WupEUv9rNfTN_byL8DSJK3iX?usp=sharing"
            target="_blank"
            class="btn btn-primary"
          >Equinox Slides</a>
        </li>
        <li>
          <!-- TODO: specific tournament link -->
          <a
            href="/play/ladder/fierce-forces/clan/65fa5bc654652e2ad959548e?tournament=65fcadf032f2005645fba186"
            class="btn btn-primary"
          >Tournament Arena</a>
        </li>
        <li>
          <!-- TODO: tournament slides -->
          <a
            href="???"
            target="_blank"
            class="btn btn-primary"
          >Tournament Slides</a>
        </li>
      </ul>
    </div>
    <div v-if="showJuniorCampInfo">
      <b>Roblox Camp Quick Links</b>
      <!-- TODO: break down by day? Or just generally give some sort of reinforcement of the camp's intended pacing. -->
      <ul class="list-inline">
        <li>
          <!-- TODO: sensei guide -->
          <a
            href="???"
            class="btn btn-primary"
          >Sensei Guide</a>
        </li>
        <li>
          <!-- TODO: real Junior slides -->
          <a
            href="???"
            target="_blank"
            class="btn btn-primary"
          >CodeCombat Junior Slides</a>
        </li>
        <li>
          <!-- TODO: class-specific Roblox private server link -->
          <a
            href="https://www.roblox.com/games/11704713454"
            class="btn btn-primary"
          >Join Roblox Private Server</a>
        </li>
        <li>
          <!-- TODO: updated Roblox slides -->
          <a
            href="https://drive.google.com/drive/folders/1E6k12t6wxRCdeEjBQM1Pp4Cww6X3EN1q?usp=sharing"
            target="_blank"
            class="btn btn-primary"
          >Roblox Getting Started Slides</a>
        </li>
        <li>
          <!-- TODO: updated Roblox slides -->
          <a
            href="https://drive.google.com/drive/folders/1-l_49tX4PQSTPO8GPqge6HuO6sTLVkdI?usp=sharing"
            target="_blank"
            class="btn btn-primary"
          >Roblox Learning Levels Slides</a>
        </li>
        <li>
          <!-- TODO: Creative Mode Roblox slides -->
          <a
            href="???"
            target="_blank"
            class="btn btn-primary"
          >Roblox Creative Mode Slides</a>
        </li>
      </ul>
    </div>
  </div>
</template>

<style lang="scss" scoped>

</style>
