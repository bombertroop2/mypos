$(function () {
    $("#filter-warehouse-adjustment").attr("data-placeholder", "Warehouse").chosen({width: "200px"});
    $("#filter-adjustment-type").attr("data-placeholder", "Type").chosen();
    $('#filter-adjustment-date').daterangepicker(
            {
                locale: {
                    format: 'DD/MM/YYYY'
                },
                opens: "left",
                autoUpdateInput: false
            });
    $('#filter-adjustment-date').on('apply.daterangepicker', function (ev, picker) {
        $(this).val(picker.startDate.format('DD/MM/YYYY') + ' - ' + picker.endDate.format('DD/MM/YYYY'));
    });

    $('#filter-adjustment-date').on('cancel.daterangepicker', function (ev, picker) {
        $(this).val('');
    });

    $("#search-adjustment-btn").click(function () {
        $("#filter_number").val($("#filter-number-adjustment").val());
        $("#filter_date").val($("#filter-adjustment-date").val());
        $("#filter_warehouse").val($("#filter-warehouse-adjustment").val());
        $("#filter_type").val($("#filter-adjustment-type").val());
        $(".smart-listing-controls").submit();
    });
});