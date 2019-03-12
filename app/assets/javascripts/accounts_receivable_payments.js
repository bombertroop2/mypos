var submitArpFormCash = false;
var submitArpFormGiro = false;
var submitArpFormTransfer = false;
$(function () {
    $('#filter-ar-payment-date').daterangepicker(
            {
                locale: {
                    format: 'DD/MM/YYYY'
                },
                opens: "left",
                autoUpdateInput: false
            });
    $('#filter-ar-payment-date').on('apply.daterangepicker', function (ev, picker) {
        $(this).val(picker.startDate.format('DD/MM/YYYY') + ' - ' + picker.endDate.format('DD/MM/YYYY'));
    });

    $('#filter-ar-payment-date').on('cancel.daterangepicker', function (ev, picker) {
        $(this).val('');
    });
    $("#filter-ar-payment-method").attr("data-placeholder", "Payment method").chosen({width: "150px"});
    $("#filter-ar-payment-customer-id").attr("data-placeholder", "Customer").chosen({width: "200px"});

    $("#search-ar-payment-btn").click(function () {
        $("#filter_ar_payment_number").val($("#filter-ar-payment-number").val());
        $("#filter_ar_payment_customer_id").val($("#filter-ar-payment-customer-id").val());
        $("#filter_ar_payment_date").val($("#filter-ar-payment-date").val());
        $("#filter_ar_payment_method").val($("#filter-ar-payment-method").val());
        $(".smart-listing-controls").submit();
    });

});