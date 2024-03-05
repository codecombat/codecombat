const path = require('path');
const express = require('express');
const fs = require('fs');

fs.writeFileSync('.storybook/temp.sass', `$is-codecombat: ${true}\n`);
fs.writeFileSync('.storybook/temp.scss', `$is-codecombat: ${true};\n`);

module.exports = function expressMiddleware(app) {
  app.use('/images', express.static(path.join(__dirname, '../app/assets/images')));

  app.get('/product-update', (req, res) => {
    fs.writeFileSync('.storybook/temp.sass', `$is-codecombat: ${req.query.product === 'codecombat'}\n`);
    fs.writeFileSync('.storybook/temp.scss', `$is-codecombat: ${req.query.product === 'codecombat'};\n`);
    res.sendStatus(200)
  });

};