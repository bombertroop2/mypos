$(function () {
    $('#filter-packing-list-departure-date').daterangepicker(
            {
                locale: {
                    format: 'DD/MM/YYYY'
                },
                opens: "left",
                autoUpdateInput: false
            });
    $('#filter-packing-list-departure-date').on('apply.daterangepicker', function (ev, picker) {
        $(this).val(picker.startDate.format('DD/MM/YYYY') + ' - ' + picker.endDate.format('DD/MM/YYYY'));
    });

    $('#filter-packing-list-departure-date').on('cancel.daterangepicker', function (ev, picker) {
        $(this).val('');
    });

    $("#search-packing-list-btn").click(function () {
        $("#filter_number").val($("#filter-packing-list-number").val());
        $("#filter_departure_date").val($("#filter-packing-list-departure-date").val());
        $("#filter_courier").val($("#filter-packing-list-courier").val());
        $("#filter_status").val($("#filter-packing-list-status").val());
        $(".smart-listing-controls").submit();
    });

    $("#filter-packing-list-courier").attr("data-placeholder", "Courier").chosen({width: "200px"});
    $("#filter-packing-list-status").attr("data-placeholder", "Status").chosen();
});