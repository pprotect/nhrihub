// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
// see https://github.com/twbs/bootstrap-sass
//= require bind_polyfill_shim
//= require jquery
//= require jquery_ujs
//= require underscore
// require turbolinks
//= require bootstrap-sprockets
// see http://stackoverflow.com/a/34212085/451893
// the bootply solution works, but the github plugin does not...
// so this is the bootply code!
//= require bootstrap-multimodal
//= require ractive-1.0.0-build-64
//= require ractive-bootstrap
//= require js-routes
//= require locale
// require flash // cannot include it here as it borks the javascript testing, so include it in each page's script
//= require string
Ractive.DEBUG = false
