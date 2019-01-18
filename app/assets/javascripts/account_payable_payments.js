var submitAppFormCash = false;
var submitAppFormTransfer = false;
var submitAppFormGiro = false;
$(function () {
    $('#filter_ap_payment_date').daterangepicker(
            {
                locale: {
                    format: 'DD/MM/YYYY'
                },
                opens: "left",
                autoUpdateInput: false
            });
    $('#filter_ap_payment_date').on('apply.daterangepicker', function (ev, picker) {
        $(this).val(picker.startDate.format('DD/MM/YYYY') + ' - ' + picker.endDate.format('DD/MM/YYYY'));
        $(".smart-listing-controls").submit();
    });

    $('#filter_ap_payment_date').on('cancel.daterangepicker', function (ev, picker) {
        $(this).val('');
        $(".smart-listing-controls").submit();
    });
});