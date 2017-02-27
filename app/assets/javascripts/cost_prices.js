$(function () {
    $('#search-cost').autoNumeric('init');  //autoNumeric with defaults
    $('#filter-effective-date').daterangepicker(
            {
                locale: {
                    format: 'DD/MM/YYYY'
                },
                autoUpdateInput: false
            });
    $('#filter-effective-date').on('apply.daterangepicker', function (ev, picker) {
        $(this).val(picker.startDate.format('DD/MM/YYYY') + ' - ' + picker.endDate.format('DD/MM/YYYY'));
    });

    $('#filter-effective-date').on('cancel.daterangepicker', function (ev, picker) {
        $(this).val('');
    });
});
