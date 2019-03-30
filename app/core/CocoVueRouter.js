import Vue from 'vue'
import VueRouter from 'vue-router'

import SchoolAdminDashboard from 'views/school-administrator/dashboard/SchoolAdministratorDashboardComponent'

Vue.use(VueRouter)

export default new VueRouter({
  history: true,

  routes: [
    { path: '/school-administrator', component: SchoolAdminDashboard }
  ]
})
