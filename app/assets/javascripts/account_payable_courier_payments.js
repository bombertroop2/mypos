var submitAppcFormCash = false;
var submitAppcFormTransfer = false;
var submitAppcFormGiro = false;
$(function () {
    $('#filter-ap-courier-payment-date').daterangepicker(
            {
                locale: {
                    format: 'DD/MM/YYYY'
                },
                opens: "left",
                autoUpdateInput: false
            });
    $('#filter-ap-courier-payment-date').on('apply.daterangepicker', function (ev, picker) {
        $(this).val(picker.startDate.format('DD/MM/YYYY') + ' - ' + picker.endDate.format('DD/MM/YYYY'));
    });

    $('#filter-ap-courier-payment-date').on('cancel.daterangepicker', function (ev, picker) {
        $(this).val('');
    });
    $("#filter-ap-courier-payment-method").attr("data-placeholder", "Payment method").chosen({width: "150px"});
    $("#filter-ap-courier-payment-courier-id").attr("data-placeholder", "Courier").chosen({width: "200px"});

    $("#search-ap-courier-payment-btn").click(function () {
        $("#filter_ap_courier_payment_number").val($("#filter-ap-courier-payment-number").val());
        $("#filter_ap_courier_payment_courier_id").val($("#filter-ap-courier-payment-courier-id").val());
        $("#filter_ap_courier_payment_date").val($("#filter-ap-courier-payment-date").val());
        $("#filter_ap_courier_payment_method").val($("#filter-ap-courier-payment-method").val());
        $(".smart-listing-controls").submit();
    });

});