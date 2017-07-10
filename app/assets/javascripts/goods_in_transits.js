$(function () {
    $('#filter-delivery-date-git').daterangepicker(
            {
                locale: {
                    format: 'DD/MM/YYYY'
                },
                opens: "left",
                autoUpdateInput: false
            });
    $('#filter-delivery-date-git').on('apply.daterangepicker', function (ev, picker) {
        $(this).val(picker.startDate.format('DD/MM/YYYY') + ' - ' + picker.endDate.format('DD/MM/YYYY'));
    });

    $('#filter-delivery-date-git').on('cancel.daterangepicker', function (ev, picker) {
        $(this).val('');
    });

});
