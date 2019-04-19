var bootboxDialogFormReplacementProduct = null;
var saleProductId = "";
var receiptNumber = "";
var salesReturnProductDataTables = null;
$(function () {
    $('#filter-sales-return-date').daterangepicker(
            {
                locale: {
                    format: 'DD/MM/YYYY'
                },
                opens: "left",
                autoUpdateInput: false
            });
    $('#filter-sales-return-date').on('apply.daterangepicker', function (ev, picker) {
        $(this).val(picker.startDate.format('DD/MM/YYYY') + ' - ' + picker.endDate.format('DD/MM/YYYY'));
    });

    $('#filter-sales-return-date').on('cancel.daterangepicker', function (ev, picker) {
        $(this).val('');
    });

    $("#filter-sales-return-warehouse-id").attr("data-placeholder", "Store").chosen({width: "200px"});
});
