var totalAmountReceived = 0;
var totalAmountReceivedForDPPayment = 0;

$(function () {
    $('#filter-payment-date').daterangepicker(
            {
                locale: {
                    format: 'DD/MM/YYYY'
                },
                opens: "left",
                autoUpdateInput: false
            });
    $('#filter-payment-date').on('apply.daterangepicker', function (ev, picker) {
        $(this).val(picker.startDate.format('DD/MM/YYYY') + ' - ' + picker.endDate.format('DD/MM/YYYY'));
    });

    $('#filter-payment-date').on('cancel.daterangepicker', function (ev, picker) {
        $(this).val('');
    });
});