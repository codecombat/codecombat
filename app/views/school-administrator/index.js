const RootComponent = require('views/core/RootComponent')
const template = require('templates/base-flat')

const SchoolAdministratorDashboardComponent = require('./dashboard/SchoolAdministratorDashboardComponent').default
console.log(SchoolAdministratorDashboardComponent instanceof Vue)
console.log(SchoolAdministratorDashboardComponent)

module.exports = class SchoolAdministratorView extends RootComponent {

    constructor(options) {
        super(options)

        this.id = 'school-administrator-view'
        this.template = template
        this.VueComponent = SchoolAdministratorDashboardComponent
    }
}
