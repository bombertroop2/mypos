$(function () {
    $('#filter-ar-invoice-due-date').daterangepicker(
            {
                locale: {
                    format: 'DD/MM/YYYY'
                },
                opens: "center",
                autoUpdateInput: false
            });
    $('#filter-ar-invoice-due-date').on('apply.daterangepicker', function (ev, picker) {
        $(this).val(picker.startDate.format('DD/MM/YYYY') + ' - ' + picker.endDate.format('DD/MM/YYYY'));
    });

    $('#filter-ar-invoice-due-date').on('cancel.daterangepicker', function (ev, picker) {
        $(this).val('');
    });
    $("#filter-ar-invoice-customer-id").attr("data-placeholder", "Customer").chosen({width: "200px"});
    $("#filter-ar-invoice-status").attr("data-placeholder", "Status").chosen({width: "150px"});

    $("#search-ar-invoice-btn").click(function () {
        $("#filter_ar_invoice_number").val($("#filter-ar-invoice-number").val());
        $("#filter_ar_invoice_due_date").val($("#filter-ar-invoice-due-date").val());
        $("#filter_ar_invoice_customer_id").val($("#filter-ar-invoice-customer-id").val());
        $("#filter_ar_invoice_status").val($("#filter-ar-invoice-status").val());
        $(".smart-listing-controls").submit();
    });

});