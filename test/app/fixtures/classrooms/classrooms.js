const Classroom = require('models/Classroom');
const Classrooms = require('collections/Classrooms');

module.exports = new Classrooms([
  require('./active-classroom'),
  require('./empty-classroom'),
  require('./archived-classroom')
]);
