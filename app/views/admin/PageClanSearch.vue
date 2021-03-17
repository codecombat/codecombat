<script>
import { getClanBySchool, getClanByDistrict } from 'core/api/clans'
const algolia = require('core/services/algolia')

export default {
  data:() => ({
    foundClans: []
  }),
  mounted() {
    if (!me.isAdmin()) {
      alert('You must be logged in as an admin to use this page.')
      return application.router.navigate('/', { trigger: true })
    }
    $(this.$refs.organizationControl).algolia_autocomplete({ hint: false }, [{
      source: function (query, callback) {
        algolia.schoolsIndex.search(query, { hitsPerPage: 5, aroundLatLngViaIP: false }).then((answer) =>
          callback(answer.hits)
        , function () {
          return callback([])
        })
      },
      displayKey: 'name',
      templates: {
        suggestion: function (suggestion) {
          const hr = suggestion._highlightResult
          return `<div class='school'> ${hr.name.value} </div>` +
            `<div class='district'>${hr.district.value}, ` +
              `<span>${hr.city?.value}, ${hr.state.value}</span></div>`
        }
      },
    }]).on('autocomplete:selected', async (event, suggestion, dataset) => {
      const districtId = suggestion.district_id
      const schoolId = suggestion.id

      try {
        const school = await getClanBySchool(schoolId)
        this.foundClans = [...this.foundClans, school]
      } catch (e) {
        noty({
          text: e.message,
          layout: 'topCenter',
          type: 'error',
          timeout: 5000,
          killer: false
        })
      }

      try {
        const district = await getClanByDistrict(districtId)
        this.foundClans = [...this.foundClans, district]
      } catch (e) {
        noty({
          text: e.message,
          layout: 'topCenter',
          type: 'error',
          timeout: 5000,
          killer: false
        })
      }
    });

  $(this.$refs.districtControl).algolia_autocomplete({ hint: false }, [{
    source: function (query, callback) {
      algolia.schoolsIndex.search(query, { hitsPerPage: 5, aroundLatLngViaIP: false }).then((answer) =>
        callback(answer.hits)
      , function () {
        return callback([])
      })
    },
    displayKey: 'district',
    templates: {
      suggestion: function (suggestion) {
        const hr = suggestion._highlightResult
        return `<div class='district'>${hr.district.value}, ` +
        `<span>${hr.city?.value}, ${hr.state.value}</span></div>`
      }
    }
  }]).on('autocomplete:selected', async (event, suggestion, dataset) => {
    console.log(suggestion)
    const districtId = suggestion.district_id

    try {
      const district = await getClanByDistrict(districtId)
      this.foundClans = [...this.foundClans, district]
    } catch (e) {
      noty({
        text: e.message,
        layout: 'topCenter',
        type: 'error',
        timeout: 5000,
        killer: false
      })
    }
    })
  }
}
</script>

<template>
  <div class="form-group">
    <label>School search</label>
    <input id="organization-control" class="form-control" ref="organizationControl"/>
    <label>District search</label>
    <input id="district-control" class="form-control" ref="districtControl"/>

    <div>
      <h2>List of found clans/teams</h2>
      <ul>
        <li
          v-for="child in foundClans"
          :key="child._id">
          <span>{{child.displayName || child.name}} - </span><span>{{child.id}}</span><a :href="`/league/${child.slug}`">Esports Page</a>
          </li>
      </ul>
    </div>
  </div>
</template>


<style lang="sass">
.algolia-autocomplete 
    width: 100%

    .aa-input
      width: 100%

    .aa-hint
      color: #999
      width: 100%

    .aa-dropdown-menu 
      background-color: #fff
      border: 1px solid #999
      border-top: none
      width: 100%

      .aa-suggestion 
        cursor: pointer
        padding: 5px 4px
        border-top: 1px solid #ccc

        .school
          font-family: Open Sans
          font-size: 14px
          line-height: 20px
          font-weight: bold

        .district
          font-family: Open Sans
          font-size: 14px
          line-height: 20px

          span
            white-space: nowrap


      .aa-suggestion.aa-cursor 
        background-color: #B2D7FF

      em
        font-weight: bold
        font-style: normal
</style>