var submitAppFormCash = false;
var submitAppFormTransfer = false;
var submitAppFormGiro = false;
var aPPpRdataTable = null;
var aPPpRdataTableGiro = null;
var aPPpRdataTableTransfer = null;
$(function () {
    $('#filter-ap-payment-date').daterangepicker(
            {
                locale: {
                    format: 'DD/MM/YYYY'
                },
                opens: "left",
                autoUpdateInput: false
            });
    $('#filter-ap-payment-date').on('apply.daterangepicker', function (ev, picker) {
        $(this).val(picker.startDate.format('DD/MM/YYYY') + ' - ' + picker.endDate.format('DD/MM/YYYY'));
    });

    $('#filter-ap-payment-date').on('cancel.daterangepicker', function (ev, picker) {
        $(this).val('');
    });
    $("#filter-ap-payment-method").attr("data-placeholder", "Payment method").chosen({width: "150px"});
    $("#filter-ap-payment-vendor-id").attr("data-placeholder", "Vendor").chosen({width: "200px"});

    $("#search-ap-payment-btn").click(function () {
        $("#filter_ap_payment_number").val($("#filter-ap-payment-number").val());
        $("#filter_ap_payment_vendor_id").val($("#filter-ap-payment-vendor-id").val());
        $("#filter_ap_payment_date").val($("#filter-ap-payment-date").val());
        $("#filter_ap_payment_method").val($("#filter-ap-payment-method").val());
        $(".smart-listing-controls").submit();
    });

});