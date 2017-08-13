$(function () {
    $('#filter-listing-transaction-date').daterangepicker(
            {
                locale: {
                    format: 'DD/MM/YYYY'
                },
                opens: "center",
                autoUpdateInput: false
            });
    $('#filter-listing-transaction-date').on('apply.daterangepicker', function (ev, picker) {
        $(this).val(picker.startDate.format('DD/MM/YYYY') + ' - ' + picker.endDate.format('DD/MM/YYYY'));
    });

    $('#filter-listing-transaction-date').on('cancel.daterangepicker', function (ev, picker) {
        $(this).val('');
    });

});