switch (process.env.COCO_SMOKE_DOMAIN) {
  case "local":
    module.exports.DOMAIN = 'http://localhost:3000';
    break;
  case "next":
    module.exports.DOMAIN = 'http://next.codecombat.com';
    break;
  case "staging":
    module.exports.DOMAIN = 'http://staging.codecombat.com';
    break;
  case "prod":
    module.exports.DOMAIN = 'https://codecombat.com';
    break;
  default:
    module.exports.DOMAIN = 'http://localhost:3000';
}

// General time to wait for elements to appear
module.exports.ASYNC_TIMEOUT = 8000;

// Used after an element appears, before an action occurs, to give the UI time to catch up,
// and to make the smoke test more 'watchable'.
module.exports.PAUSE_TIME = 300;
