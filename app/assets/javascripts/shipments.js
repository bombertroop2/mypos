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

    $('#table-listing-shipments #new-item-btn').removeClass('pull-right');

    $("#table-listing-shipments tr.new-item-action").find("td").append("<button type='submit' class='btn btn-link pull-right' id='print-btn'><i class='glyphicon glyphicon-print'></i> Print Checked Rows</button>");

    $('.bs-checkbox').bsCheckbox();
    $("#checkAll").click(function () {
        checkbox = $(this).find("input[type=checkbox]");
        if (checkbox.is(":checked")) {
            $('span.checkbox-table').each(function () {
                $(this).find("input[type=checkbox]").prop('checked', true);
                $(this).removeClass('glyphicon-unchecked').addClass('glyphicon-check');
            });
        } else {
            $('span.checkbox-table').each(function () {
                $(this).find("input[type=checkbox]").prop('checked', false);
                $(this).removeClass('glyphicon-check').addClass('glyphicon-unchecked');
            });
        }
    });

    $("#print-btn").click(function () {
        var check = [];
        if ($('input:checkbox:checked').length == 0)
            bootbox.alert({message: "Please check the data you want to print", size: "small"});
        else {
            $('input:checkbox:checked').each(function () {
                check.push(parseInt($(this).val()));
            });
            $.get("/shipments/multiprint", {
                check: check
            });
        }
    });

    $("#filter-customer-direct-sales").attr("data-placeholder", "Customer").chosen({width: "200px"});

    $('#filter-date-direct-sales').daterangepicker(
            {
                locale: {
                    format: 'DD/MM/YYYY'
                },
                opens: "left",
                autoUpdateInput: false
            });
    $('#filter-date-direct-sales').on('apply.daterangepicker', function (ev, picker) {
        $(this).val(picker.startDate.format('DD/MM/YYYY') + ' - ' + picker.endDate.format('DD/MM/YYYY'));
    });

    $('#filter-date-direct-sales').on('cancel.daterangepicker', function (ev, picker) {
        $(this).val('');
    });

    $("#search-direct-sales-btn").click(function () {
        $("#filter_string_direct_sales").val($("#filter-string-direct-sales").val());
        $("#filter_date_direct_sales").val($("#filter-date-direct-sales").val());
        $("#filter_customer_direct_sales").val($("#filter-customer-direct-sales").val());
        $(".smart-listing-controls").submit();
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

function receiveInventory(shipmentId, docNumber) {
//Show the datepicker in the bootbox
    bootbox.confirm({
        message: BootboxContent,
        title: "Receive inventory " + docNumber + " ?",
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

function changeReceiveInventoryDate(shipmentId, docNumber) {
//Show the datepicker in the bootbox
    bootbox.confirm({
        message: changeReceiveDateBootboxContent,
        title: "Change receive date (" + docNumber + ") ?",
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
