$(function () {
    $("#warehouse_code").attr("data-placeholder", "Please select").chosen();
    $("#incentive_spg").attr("data-placeholder", "Please select").chosen();
    $("#calculate_by").attr("data-placeholder", "Please select").chosen();
    $('#incentive_transaction_date').daterangepicker(
            {
                locale: {
                    format: 'DD/MM/YYYY'
                },
                opens: "right",
                autoUpdateInput: false
            });
    $('#incentive_transaction_date').on('apply.daterangepicker', function (ev, picker) {
        $(this).val(picker.startDate.format('DD/MM/YYYY') + ' - ' + picker.endDate.format('DD/MM/YYYY'));
    });

    $('#incentive_transaction_date').on('cancel.daterangepicker', function (ev, picker) {
        $(this).val('');
    });
});