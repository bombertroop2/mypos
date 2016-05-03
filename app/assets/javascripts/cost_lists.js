var selectedCostListProductId = '';

function selectProductRow() {
    var e = jQuery.Event("click");
    $("#listing_products_table_" + selectedCostListProductId).find("td:first-child").trigger(e);
}
$(function () {
    var productsDataTable = $('#listing_products_table').DataTable({
        order: [0, 'asc'],
        dom: 'T<"clear">lfrtip',
        columns: [
            {data: 'product code'},
            {data: 'brand'},
            {data: 'model'},
            {data: 'goods type'},
            {data: 'vendor'},
            {data: 'target'}
        ],
        tableTools: {
            sRowSelect: 'single',
            aButtons: []
        },
        paging: false,
        info: false,
        scrollY: "250px",
        scrollCollapse: true
    });

    $("#cost_list_effective_date").datepicker({
        dateFormat: "dd/mm/yy"
    });

    $('#cost_list_cost').autoNumeric('init');  //autoNumeric with defaults


    $('#listing_products_table tbody').on('click', 'tr', function () {
        if ($(this).hasClass('selected')) {
            var productId = $(this).attr("id").split("_")[3];
            $("#cost_list_product_id").val(productId);
            $("#product_id").html($("#products_code_" + productId).html());
        } else {
            $("#cost_list_product_id").val("");
            $("#product_id").html("");
        }
    });

    if (selectedCostListProductId != '')
        selectProductRow();
});

$(document).on('page:load', function () {
    var productsDataTable = $('#listing_products_table').DataTable({
        order: [0, 'asc'],
        dom: 'T<"clear">lfrtip',
        columns: [
            {data: 'product code'},
            {data: 'brand'},
            {data: 'model'},
            {data: 'goods type'},
            {data: 'vendor'},
            {data: 'target'}
        ],
        tableTools: {
            sRowSelect: 'single',
            aButtons: []
        },
        paging: false,
        info: false,
        scrollY: "250px",
        scrollCollapse: true
    });

    $("#cost_list_effective_date").datepicker({
        dateFormat: "dd/mm/yy"
    });

    $('#cost_list_cost').autoNumeric('init');  //autoNumeric with defaults

    $('#listing_products_table tbody').on('click', 'tr', function () {
        if ($(this).hasClass('selected')) {
            var productId = $(this).attr("id").split("_")[3];
            $("#cost_list_product_id").val(productId);
            $("#product_id").html($("#products_code_" + productId).html());
        } else {
            $("#cost_list_product_id").val("");
            $("#product_id").html("");
        }
    });

    if (selectedCostListProductId != '')
        selectProductRow();
});