<template>
  <div class="flex members-component">
    <div class="title row">
      <div class="name col-sm-4">
        {{ $t('general.name') }}
      </div>
      <div class="startDate col-sm-4">
        {{ $t('outcomes.start_date') }}
      </div>
      <div class="count col-sm-4">
        {{ $t('events.class_count') }}
        <span class="count-tips-trigger">?</span>
        <span class="count-tips"> {{ $t('events.lessons_count_desc') }}</span>
      </div>
    </div>
    <div
      v-for="(member, id) in members"
      :key="id"
      class="current row"
    >
      <input
        class="name col-sm-4"
        name="m"
        type="text"
        disabled="true"
        :value="member.name"
      >
      <input
        class="startdate col-sm-4"
        type="date"
        :value="formatDate(member)"
        disabled
      >
      <input
        class="count col-sm-3"
        type="number"
        :value="member.count"
        @input="updateMember(id, 'count', $event.target.value)"
      >
      <div
        class="remove icon-remove"
        @click="removeMember(id)"
      />
    </div>
    <div class="split" />
    <div class="new">
      <user-search
        class="user-search"
        :value="newMember.name"
        @select="selectNewMember"
      />
      <input
        type="button"
        class="btn btn-primary btn-add-member"
        :class="{disabled: !newMember._id}"
        :value="$t('events.add_member')"
        @click="addMember"
      >
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'
import UserSearchComponent from './UserSearchComponent'
import _ from 'lodash'
export default {
  name: 'MembersComponent',
  components: {
    'user-search': UserSearchComponent
  },
  props: {
    members: {
      type: Object
    }
  },
  computed: {
    ...mapGetters({
      propsEvent: 'events/eventPanelEvent'
    })
  },
  data () {
    return {
      newMember: {}
    }
  },
  methods: {
    formatDate (member) {
      let date
      if (member.startDate) {
        date = member.startDate
      } else {
        date = _.find(this.propsEvent.instances, { index: member.startIndex }).startDate
      }
      return date.toString().slice(0, 10)
    },
    selectNewMember (u) {
      this.newMember = u
    },
    addMember () {
      this.$emit('new-member', this.newMember)
      this.newMember = {}
    },
    removeMember (member) {
      this.$emit('remove-member', member)
    },
    updateMember (id, key, value) {
      if (key === 'count') {
        value = parseInt(value)
      }
      this.$emit('update-member', {id, key, value})
    }
  }
}
</script>

<style lang="scss" scoped>
.members-component {
  .title {
    font-weight: bold;
    margin-bottom: 10px;
  }

  .split {
    margin: 20px 0;
    border-bottom: 1px solid #ccc;
    height: 1px;
  }

  .new {
    display: flex;
    margin-bottom: 15px;

    .user-search {
      flex-grow: 1;
    }
    .plus {
      flex-shrink: 1;
    }
  }

  .count-tips {
    box-shadow: 0px 1px 3px 1px #ccc;
    padding: 2px;
    display: none;
    font-size: 14px;
    position: absolute;
    z-index: 99;
    background-color: white;
    font-weight: normal;
  }

  .count-tips-trigger {
    width: 22px;
    height: 22px;
    display: inline-block;
    border: 1px solid #999;
    border-radius: 50%;
    line-height: 20px;
    text-align: center;
    color: #999;
    cursor: pointer;

    &:hover ~ .count-tips {
      display: block;
    }
  }
}
</style>
