var selectedPriceListProductId = '';
var selectedProductId = '';

function selectProductRowPriceList() {
    var e = jQuery.Event("click");
    $("#listing_products_table_price_lists_" + selectedPriceListProductId).find("td:first-child").trigger(e);
}
//$(function () {
//    var productsPriceListsDataTable = $('#listing_products_table_price_lists').DataTable({
//        order: [0, 'asc'],
//        dom: 'T<"clear">lfrtip',
//        columns: [
//            {data: 'product code'},
//            {data: 'brand'},
//            {data: 'model'},
//            {data: 'goods type'},
//            {data: 'vendor'},
//            {data: 'target'}
//        ],
//        tableTools: {
//            sRowSelect: 'single',
//            aButtons: []
//        },
//        paging: false,
//        info: false,
//        scrollY: "250px",
//        scrollCollapse: true
//    });
//
//    $('#listing_products_table_price_lists tbody').on('click', 'tr', function () {
//        if ($(this).hasClass('selected')) {
//            selectedProductId = $(this).attr("id").split("_")[5];
////            $("#price_list_product_id").val(productId);
////            $("#product_id").html($("#products_code_" + productId).html());
//        } /*else {
//         $("#price_list_product_id").val("");
//         $("#product_id").html("");
//         }*/
//    });
//
//    if (selectedPriceListProductId != '')
//        selectProductRowPriceList();
//
//    $("#generate_price_form").click(function () {
//        if (productsPriceListsDataTable.rows('.selected').data().length == 0)
//            alert('You have not selected a product yet!');
//        else
//            $.get("/price_lists/generate_price_form", {
//                id: selectedProductId
//            });
//        return false;
//    });
//
//    $("#price_list_effective_date").datepicker({
//        dateFormat: "dd/mm/yy"
//    });
//    $('#price_list_price').autoNumeric('init');
//
//});

$(window).on('load', function () {
    var productsPriceListsDataTable = $('#listing_products_table_price_lists').DataTable({
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

    $('#listing_products_table_price_lists tbody').on('click', 'tr', function () {
        if ($(this).hasClass('selected')) {
            selectedProductId = $(this).attr("id").split("_")[5];
//            $("#price_list_product_id").val(productId);
//            $("#product_id").html($("#products_code_" + productId).html());
        } /*else {
         $("#price_list_product_id").val("");
         $("#product_id").html("");
         }*/
    });

    if (selectedPriceListProductId != '')
        selectProductRowPriceList();

    $("#generate_price_form").click(function () {
        if (productsPriceListsDataTable.rows('.selected').data().length == 0)
            alert('You have not selected a product yet!');
        else
            $.get("/price_lists/generate_price_form", {
                id: selectedProductId
            });
        return false;
    });

    $("#price_list_effective_date").datepicker({
        dateFormat: "dd/mm/yy"
    });
    $('#price_list_price').autoNumeric('init');

});