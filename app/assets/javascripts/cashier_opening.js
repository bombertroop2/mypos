function printCashDisbursementReport() {
    $("#cash_disbursement_report").show();
    $("#cash_disbursement_report").print();
    $("#cash_disbursement_report").hide();
    return false;
}

function printClosingReport() {
    $("#closing_report").show();
    $("#closing_report").print();
    $("#closing_report").hide();
    return false;
}

$(function () {
    $('#cashier_opening_beginning_cash').autoNumeric('init');

    $("#cashier_opening_submit_button").click(function () {
        bootbox.confirm({
            message: "Please double check all of the data before you open the cashier, make sure the beginning cash is correct.<br>Once you open cashier, you'll not be able to edit or cancel it<br>Are you sure?",
            buttons: {
                confirm: {
                    label: '<i class="fa fa-check"></i> Confirm'
                },
                cancel: {
                    label: '<i class="fa fa-times"></i> Cancel'
                }
            },
            callback: function (result) {
                if (result) {
                    $("body").css('padding-right', '0px');
                    $("#new_cashier_opening").submit();
                }
            },
            size: "small"
        });
        return false;
    });

    $('#filter-opened-at').daterangepicker(
            {
                locale: {
                    format: 'DD/MM/YYYY'
                },
                opens: "left",
                autoUpdateInput: false
            });
    $('#filter-opened-at').on('apply.daterangepicker', function (ev, picker) {
        $(this).val(picker.startDate.format('DD/MM/YYYY') + ' - ' + picker.endDate.format('DD/MM/YYYY'));
    });

    $('#filter-opened-at').on('cancel.daterangepicker', function (ev, picker) {
        $(this).val('');
    });
});