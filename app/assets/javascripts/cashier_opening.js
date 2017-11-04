function print(cashierOpeningId) {
    $("#sales_summary_report_" + cashierOpeningId).show();
    $("#sales_summary_report_" + cashierOpeningId).print();
    $("#sales_summary_report_" + cashierOpeningId).hide();
    return false;
}

$(function () {
    $('#cashier_opening_beginning_cash').autoNumeric('init');

    $("#cashier_opening_submit_button").click(function () {
        bootbox.confirm({
            message: "Once you open cashier, you'll not be able to cancel it</br>Are you sure?",
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