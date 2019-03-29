$(function () {
    $('#filter-ap-invoice-vendor-invoice-date').daterangepicker(
            {
                locale: {
                    format: 'DD/MM/YYYY'
                },
                opens: "left",
                autoUpdateInput: false
            });
    $('#filter-ap-invoice-vendor-invoice-date').on('apply.daterangepicker', function (ev, picker) {
        $(this).val(picker.startDate.format('DD/MM/YYYY') + ' - ' + picker.endDate.format('DD/MM/YYYY'));
    });

    $('#filter-ap-invoice-vendor-invoice-date').on('cancel.daterangepicker', function (ev, picker) {
        $(this).val('');
    });
    $('#filter-ap-invoice-due-date').daterangepicker(
            {
                locale: {
                    format: 'DD/MM/YYYY'
                },
                opens: "left",
                autoUpdateInput: false
            });
    $('#filter-ap-invoice-due-date').on('apply.daterangepicker', function (ev, picker) {
        $(this).val(picker.startDate.format('DD/MM/YYYY') + ' - ' + picker.endDate.format('DD/MM/YYYY'));
    });

    $('#filter-ap-invoice-due-date').on('cancel.daterangepicker', function (ev, picker) {
        $(this).val('');
    });
    $("#filter-ap-invoice-vendor-id").attr("data-placeholder", "Vendor").chosen({width: "200px"});
    $("#filter-ap-invoice-status").attr("data-placeholder", "Status").chosen({width: "150px"});

    $("#search-ap-invoice-btn").click(function () {
        $("#filter_ap_invoice_invoice_number").val($("#filter-ap-invoice-invoice-number").val());
        $("#filter_ap_invoice_vendor_id").val($("#filter-ap-invoice-vendor-id").val());
        $("#filter_ap_invoice_vendor_invoice_date").val($("#filter-ap-invoice-vendor-invoice-date").val());
        $("#filter_ap_invoice_due_date").val($("#filter-ap-invoice-due-date").val());
        $("#filter_ap_invoice_status").val($("#filter-ap-invoice-status").val());
        $(".smart-listing-controls").submit();
    });

});