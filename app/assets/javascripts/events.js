var eventWarehouseProductDataTables = [];
var eventWarehouseProductDataTablesCashDiscount = [];
var eventWarehouseProductDataTablesSpecialPrice = [];
var eventWarehouseProductDataTablesBuyOneGetOne = [];
var eventWarehouseProductDataTablesGift = [];
var eventGeneralProductDataTablesPercentageDiscount = [];


$(function () {
    $('#filter-event-start-time').daterangepicker(
            {
                locale: {
                    format: 'DD/MM/YYYY HH:mm'
                },
                opens: "left",
                autoUpdateInput: false,
                timePicker: true,
                timePicker24Hour: true
            });
    $('#filter-event-start-time').on('apply.daterangepicker', function (ev, picker) {
        $(this).val(picker.startDate.format('DD/MM/YYYY HH:mm') + ' - ' + picker.endDate.format('DD/MM/YYYY HH:mm'));
    });

    $('#filter-event-start-time').on('cancel.daterangepicker', function (ev, picker) {
        $(this).val('');
    });

    $('#filter-event-end-time').daterangepicker(
            {
                locale: {
                    format: 'DD/MM/YYYY HH:mm'
                },
                opens: "left",
                autoUpdateInput: false,
                timePicker: true,
                timePicker24Hour: true
            });
    $('#filter-event-end-time').on('apply.daterangepicker', function (ev, picker) {
        $(this).val(picker.startDate.format('DD/MM/YYYY HH:mm') + ' - ' + picker.endDate.format('DD/MM/YYYY HH:mm'));
    });

    $('#filter-event-end-time').on('cancel.daterangepicker', function (ev, picker) {
        $(this).val('');
    });
});
