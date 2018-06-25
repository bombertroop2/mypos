$(function () {
    $('#filter-delivery-date').daterangepicker(
            {
                locale: {
                    format: 'DD/MM/YYYY'
                },
                opens: "left",
                autoUpdateInput: false
            });
    $('#filter-delivery-date').on('apply.daterangepicker', function (ev, picker) {
        $(this).val(picker.startDate.format('DD/MM/YYYY') + ' - ' + picker.endDate.format('DD/MM/YYYY'));
    });

    $('#filter-delivery-date').on('cancel.daterangepicker', function (ev, picker) {
        $(this).val('');
    });

    $('#filter-received-date').daterangepicker(
            {
                locale: {
                    format: 'DD/MM/YYYY'
                },
                opens: "left",
                autoUpdateInput: false
            });
    $('#filter-received-date').on('apply.daterangepicker', function (ev, picker) {
        $(this).val(picker.startDate.format('DD/MM/YYYY') + ' - ' + picker.endDate.format('DD/MM/YYYY'));
    });

    $('#filter-received-date').on('cancel.daterangepicker', function (ev, picker) {
        $(this).val('');
    });

});


function BootboxContent() {
    var frm_str = '<div class="form-group">'
            + '<label for="popup-receive-date">Be careful! This cannot be canceled</label>'
            + '<input readonly="true" id="popup-receive-date" class="form-control input-sm" size="10" placeholder="Receive Date" type="text">'
            + '</div>';

    var object = $('<div/>').html(frm_str).contents();

    object.find('#popup-receive-date').datepicker({
        dateFormat: "dd/mm/yy"
    });

    return object;
}

function changeReceiveDateBootboxContent() {
    var frm_str = '<div class="form-group">'
            + '<label for="popup-change-receive-date">Be careful! You can only change receive date once after you receive inventory the first time</label>'
            + '<input readonly="true" id="popup-change-receive-date" class="form-control input-sm" size="10" placeholder="Receive Date" type="text">'
            + '</div>';

    var object = $('<div/>').html(frm_str).contents();

    object.find('#popup-change-receive-date').datepicker({
        dateFormat: "dd/mm/yy"
    });

    return object;
}

function receiveInventory(shipmentId) {
//Show the datepicker in the bootbox
    bootbox.confirm({
        message: BootboxContent,
        title: "Receive inventory?",
        buttons: {
            cancel: {
                label: '<i class="fa fa-times"></i> Cancel'
            },
            confirm: {
                label: '<i class="fa fa-check"></i> Confirm'
            }
        },
        callback: function (result) {
            if (result && !$("#popup-receive-date").val() == "") {
                $("body").css('padding-right', '0px');
                $.get("/shipments/" + shipmentId + "/receive", {
                    receive_date: $("#popup-receive-date").val()
                });
            } else if (result && $("#popup-receive-date").val() == "")
                return false;
        },
        size: "small"
    });
}

function changeReceiveInventoryDate(shipmentId) {
//Show the datepicker in the bootbox
    bootbox.confirm({
        message: changeReceiveDateBootboxContent,
        title: "Change receive date?",
        buttons: {
            cancel: {
                label: '<i class="fa fa-times"></i> Cancel'
            },
            confirm: {
                label: '<i class="fa fa-check"></i> Confirm'
            }
        },
        callback: function (result) {
            if (result && !$("#popup-change-receive-date").val() == "") {
                $("body").css('padding-right', '0px');
                $.get("/shipments/" + shipmentId + "/change_receive_date", {
                    receive_date: $("#popup-change-receive-date").val()
                });
            } else if (result && $("#popup-change-receive-date").val() == "")
                return false;
        },
        size: "small"
    });
}