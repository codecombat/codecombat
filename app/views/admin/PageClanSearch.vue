<script>
import { getClanBySchool, getClanByDistrict } from 'core/api/clans'
import Clan from 'app/models/Clan'
const algolia = require('core/services/algolia')

export default {
  data:() => ({
    foundClans: []
  }),
  mounted() {
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
        console.log(suggestion)
        const districtId = suggestion.district_id
        const schoolId = suggestion.id

        try {
          const school = await getClanBySchool(schoolId)
          this.foundClans = [...this.foundClans, school]
        } catch (e) {}

        try {
          const district = await getClanByDistrict(districtId)
          this.foundClans = [...this.foundClans, district]
        } catch (e) {}
      })
    // TODO
    // $("#district-control").algolia_autocomplete({hint: false}, [
    //   source: (query, callback) ->
    //     algolia.schoolsIndex.search(query, { hitsPerPage: 5, aroundLatLngViaIP: false }).then (answer) ->
    //       callback answer.hits
    //     , ->
    //       callback []
    //   displayKey: 'district',
    //   templates:
    //     suggestion: (suggestion) ->
    //       hr = suggestion._highlightResult
    //       "<div class='district'>#{hr.district.value}, " +
    //         "<span>#{hr.city?.value}, #{hr.state.value}</span></div>"
    // ]).on 'autocomplete:selected', (event, suggestion, dataset) =>
    //   @$('input[name="organization"]').val '' # TODO: does not persist on tabbing: back to school, back to district
    //   @$('input[name="city"]').val suggestion.city
    //   @$('input[name="state"]').val suggestion.state
    //   @$('select[name="state"]').val suggestion.state
    //   @$('select[name="country"]').val 'United States'
    //   @state.set({showUsaStateDropdown: true})
    //   @state.set({stateValue: suggestion.state})
    //   for key in DISTRICT_NCES_KEYS
    //     @$('input[name="nces_' + key + '"]').val suggestion[key]
    //   @onChangeForm()
  }
}
</script>

<template>
  <div class="form-group">
    <label>School search</label>
    <input id="organization-control" class="form-control" ref="organizationControl"/>
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