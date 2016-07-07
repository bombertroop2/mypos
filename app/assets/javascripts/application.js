// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require bootstrap-sprockets
//= require cocoon
//= require vendors
//= require jquery.dataTables.min
//= require_tree .



//$(function () {
//    $('.inputs').bind('keypress', function (event) {
//        if (event.which === 13) {
//            $('[tabindex=' + (+this.tabIndex + 1) + ']').focus();
//            return false;
//        }
//    });
//    
//    if ($("#taxable_entrepreneur").length == 0) {
//        $(document).off("keydown");
//    }
//});

$(document).on('turbolinks:load', function () {
    $('.inputs').bind('keypress', function (event) {
        if (event.which === 13) {
            $('[tabindex=' + (+this.tabIndex + 1) + ']').focus();
            return false;
        }
    });
    
    if ($("#taxable_entrepreneur").length == 0) {
        $(document).off("keydown");
    }
});
