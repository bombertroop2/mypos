var counter_eventWarehouseProductDataTables = [];
var counter_eventWarehouseProductDataTablesCashDiscount = [];
var counter_eventWarehouseProductDataTablesSpecialPrice = [];
var counter_eventWarehouseProductDataTablesBuyOneGetOne = [];
var counter_eventWarehouseProductDataTablesGift = [];
var counter_eventGeneralProductDataTablesPercentageDiscount = null;
var counter_eventGeneralProductDataTablesCashDiscount = null;
var counter_eventGeneralProductDataTablesSpecialPrice = null;
var counter_eventGeneralProductDataTablesBuyOneGetOne = null;
var counter_eventGeneralProductDataTablesGift = null;

$(function () {
    $('#filter-counter_event-start-time').daterangepicker(
            {
                locale: {
                    format: 'DD/MM/YYYY HH:mm'
                },
                opens: "left",
                autoUpdateInput: false,
                timePicker: true,
                timePicker24Hour: true
            });
    $('#filter-counter_event-start-time').on('apply.daterangepicker', function (ev, picker) {
        $(this).val(picker.startDate.format('DD/MM/YYYY HH:mm') + ' - ' + picker.endDate.format('DD/MM/YYYY HH:mm'));
    });

    $('#filter-counter_event-start-time').on('cancel.daterangepicker', function (ev, picker) {
        $(this).val('');
    });

    $('#filter-counter_event-end-time').daterangepicker(
            {
                locale: {
                    format: 'DD/MM/YYYY HH:mm'
                },
                opens: "left",
                autoUpdateInput: false,
                timePicker: true,
                timePicker24Hour: true
            });
    $('#filter-counter_event-end-time').on('apply.daterangepicker', function (ev, picker) {
        $(this).val(picker.startDate.format('DD/MM/YYYY HH:mm') + ' - ' + picker.endDate.format('DD/MM/YYYY HH:mm'));
    });

    $('#filter-counter_event-end-time').on('cancel.daterangepicker', function (ev, picker) {
        $(this).val('');
    });
});
