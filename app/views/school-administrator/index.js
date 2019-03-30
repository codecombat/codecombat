const RootComponent = require('views/core/RootComponent')
const template = require('templates/base-flat')

module.exports = class SchoolAdministratorView extends RootComponent {

    constructor(options) {
        super(options)

        this.id = 'school-administrator-view'
        this.template = template
        this.router = true
    }
}
