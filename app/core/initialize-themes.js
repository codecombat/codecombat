module.exports = {
  $themePath (path) {
    // Get the body element
    const body = document.body

    // Regular expression to match any theme
    const themeRegex = /(\w+)-theme/

    // Find the theme in the body's class list
    const themeMatch = [...body.classList].find(className => themeRegex.test(className))

    if (themeMatch) {
      // Extract the theme name
      const themeName = themeMatch.match(themeRegex)[1]

      if (themeName === 'blue') {
        return path
      }

      // Split the path into parts
      const parts = path.split('.')

      // Add '_' + themeName to the last part before '.js'
      parts[parts.length - 2] += `__${themeName}`

      // Join the parts back together
      path = parts.join('.')
    }

    return path
  }
}