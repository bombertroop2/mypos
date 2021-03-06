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
//= require cocoon
//= require smart_listing
//= require vendors
//= require jquery.dataTables.min
//= require jquery.remotipart
//= require moment.min
//= require daterangepicker
//= require jquery.transit.min
//= require bootstrap.min
//= require fastclick
//= require bootstrap-progressbar.min
//= require custom.min
//= require bs-checkbox
//= require jquery-ui.min
//= require tag-it
//= require autocomplete-rails
//= require highcharts
//= require chartkick
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

var openingNotification = false;
$(window).on('load', function () {
    $('.inputs').bind('keypress', function (event) {
        if (event.which === 13) {
            $('[tabindex=' + (+this.tabIndex + 1) + ']').focus();
            return false;
        }
    });
    if ($("#taxable_entrepreneur").length == 0) {
        $(document).off("keydown");
    }

// open notification center on click
    $("#open_notification").click(function () {
        if (!$(this).hasClass("open") && $("#notification-counter").text() != "0") {
            openingNotification = true;
            $("#notification-counter").text("0");
            var notificationIds = [];
            $(".notification-rows").each(function () {
                notificationIds.push($(this).attr("id").split("_")[1]);
            });
            $.get("/notifications/notify_user", {
                notification_ids: notificationIds.join(",")
            }, function (data) {
                openingNotification = false;
            });
        }
    });
    App.notifications = App.cable.subscriptions.create("NotificationsChannel", {
        connected: function () {
// Called when the subscription is ready for use on the server
            console.log("connected");
        },
        disconnected: function () {
            // Called when the subscription has been terminated by the server
            console.log("disconnected");
        },
        received: function (data) {
            if ($(".notification-rows").length > 3)
                $($(".notification-rows").last().parent()).remove();
            // Called when there's incoming data on the websocket for this channel
            $('#menu1').prepend(data.notification);
            $("#notification_" + data.notification_id).click(function () {
                $.get("/notifications/" + data.notification_id).done(function (data) {
                    bootbox.alert({
                        title: "Notification",
                        message: data
                    });
                });
            });
            this.update_counter();
        },
        update_counter: function () {
            var counterContainer = $('#notification-counter');
            var val = parseInt(counterContainer.text());
            val++;
            counterContainer
                    .css({opacity: 0})
                    .text(val)
                    .css({top: '-5px'})
                    .transition({top: '8px', opacity: 1});
        }
    });
    $.fn.dataTable.moment('DD/MM/YYYY');
    $.extend($.fn.dataTableExt.oSort, {
        "currency-pre": function (a) {
            a = (a === "-") ? 0 : a.replace(/[^\d\-\,]/g, "").replace(/[\,]/g, ".");
            return parseFloat(a);
        },
        "currency-asc": function (a, b) {
            return a - b;
        },
        "currency-desc": function (a, b) {
            return b - a;
        }
    });
}).ajaxStart(function () {
    if (!openingNotification)
        $("#json-overlay").show();
}).ajaxStop(function () {
    if (!openingNotification)
        $("#json-overlay").hide();
}).ajaxComplete(function (event, jqxhr, settings, thrownError) {
    if ($(".new-item-placeholder").length > 0)
        $(".new-item-placeholder").on('classChanged', function () {
            if ($(this).hasClass("new-item-placeholder") && $(this).hasClass("info") && $(this).hasClass("hidden")) {
                $(".new-item-placeholder").html("");
            }
        });
    if (jqxhr.status == 401) {
        window.location.replace('/users/sign_in');
    }
});
