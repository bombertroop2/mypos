$(function () {
    $('#filter-ap-invoice-courier-courier-invoice-date').daterangepicker(
            {
                locale: {
                    format: 'DD/MM/YYYY'
                },
                opens: "left",
                autoUpdateInput: false
            });
    $('#filter-ap-invoice-courier-courier-invoice-date').on('apply.daterangepicker', function (ev, picker) {
        $(this).val(picker.startDate.format('DD/MM/YYYY') + ' - ' + picker.endDate.format('DD/MM/YYYY'));
    });

    $('#filter-ap-invoice-courier-courier-invoice-date').on('cancel.daterangepicker', function (ev, picker) {
        $(this).val('');
    });
    $("#filter-ap-invoice-courier-courier-id").attr("data-placeholder", "Courier").chosen({width: "200px"});
    $("#filter-ap-invoice-courier-status").attr("data-placeholder", "Status").chosen({width: "150px"});

    $("#search-ap-invoice-courier-btn").click(function () {
        $("#filter_ap_invoice_courier_invoice_number").val($("#filter-ap-invoice-courier-invoice-number").val());
        $("#filter_ap_invoice_courier_courier_id").val($("#filter-ap-invoice-courier-courier-id").val());
        $("#filter_ap_invoice_courier_courier_invoice_date").val($("#filter-ap-invoice-courier-courier-invoice-date").val());
        $("#filter_ap_invoice_courier_status").val($("#filter-ap-invoice-courier-status").val());
        $(".smart-listing-controls").submit();
    });

});