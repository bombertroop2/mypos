$(function () {
    $('#filter-plan-date').daterangepicker(
            {
                locale: {
                    format: 'DD/MM/YYYY'
                },
                opens: "left",
                autoUpdateInput: false
            });
    $('#filter-plan-date').on('apply.daterangepicker', function (ev, picker) {
        $(this).val(picker.startDate.format('DD/MM/YYYY') + ' - ' + picker.endDate.format('DD/MM/YYYY'));
    });

    $('#filter-plan-date').on('cancel.daterangepicker', function (ev, picker) {
        $(this).val('');
    });
    $("#filter-status").attr("data-placeholder", "Status").chosen({width: "100px"});
    $("#filter-destination-warehouse").attr("data-placeholder", "Warehouse to").chosen({width: "200px"});
});