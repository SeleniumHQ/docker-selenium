require('colors');
var chai = require('chai');
chai.should();

var wd = require('wd');

module.exports = function(browserName) {
  var logPrefix = ('[' + browserName + '] ').grey;
  var browser = wd.remote({
    hostname: process.env.HUB_PORT_4444_TCP_ADDR,
    port: process.env.HUB_PORT_4444_TCP_PORT
  });

  // optional extra logging
  browser.on('status', function(info) {
    console.log(logPrefix + info.cyan);
  });
  browser.on('command', function(eventType, command, response) {
    console.log(logPrefix + ' > ' + eventType.cyan, command, (response || '').grey);
  });
  browser.on('http', function(meth, path, data) {
    console.log(logPrefix + ' > ' + meth.magenta, path, (data || '').grey);
  });

  browser.init({
    browserName: browserName
  }, function() {
    browser.get("https://www.wikipedia.org/", function() {
      browser.title(function(err, title) {
        if (err) {
          console.error(err);
          browser.quit();
          process.exit(1);
        }

        title.should.include('Wikipedia');
        browser.quit();
      })
    });
  });
};
