var bootboxDialogFormConsale = null;

$(function () {
    $('#filter-courier-price-effective-date').daterangepicker(
            {
                locale: {
                    format: 'DD/MM/YYYY'
                },
                opens: "left",
                autoUpdateInput: false
            });
    $('#filter-courier-price-effective-date').on('apply.daterangepicker', function (ev, picker) {
        $(this).val(picker.startDate.format('DD/MM/YYYY') + ' - ' + picker.endDate.format('DD/MM/YYYY'));
    });

    $('#filter-courier-price-effective-date').on('cancel.daterangepicker', function (ev, picker) {
        $(this).val('');
    });

    $("#search-courier-price-btn").click(function () {
        $("#filter_courier").val($("#filter-courier-price-courier").val());
        $("#filter_city").val($("#filter-courier-price-city").val());
        $("#filter_effective_date").val($("#filter-courier-price-effective-date").val());
        $("#filter_price_type").val($("#filter-courier-price-price-type").val());
        $(".smart-listing-controls").submit();
    });

    $("#filter-courier-price-courier").attr("data-placeholder", "Courier").chosen({width: "200px"});
    $("#filter-courier-price-city").attr("data-placeholder", "City").chosen({width: "200px"});
    $("#filter-courier-price-price-type").attr("data-placeholder", "Price type").chosen({width: "100px"});
});