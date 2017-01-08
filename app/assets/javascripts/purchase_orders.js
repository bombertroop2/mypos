var dataTable;
function intersection(x, y) {
    x.sort();
    y.sort();
    var i = j = 0;
    ret = [];
    while (i < x.length && j < y.length) {
        if (x[i] < y[j])
            i++;
        else if (y[j] < x[i])
            j++;
        else {
            ret.push(x[i]);
            i++, j++;
        }
    }
    return ret;
}

// sembunyikan produk yang di tandai hapus apabila terjadi error ketika editing (error validasi)
function hideDeleteMarkedProduct() {
    $(".product-table").each(function () {
        var productId = $(this).attr("id").split("_")[2];
        if ($(this).find("[type='checkbox']").length > 0 && $(this).find("[type='checkbox']").is(":checked")/* && $("#product_collections").val().indexOf(productId) < 0*/) {
            $(this).hide();
        }
    });
}

// munculkan kembali produk yang di tandai hapus apabila user menambahkan kembali produk ini
function showDeleteMarkedProduct() {
    $(".product-table").each(function () {
        var productId = $(this).attr("id").split("_")[2];
        if ($(this).find("[type='checkbox']").length > 0 && $(this).find("[type='checkbox']").is(":checked") && $("#product_collections").val().indexOf(productId) >= 0) {
            $(this).show();
            $(this).find("[type='checkbox']").attr("checked", false);
        }
    });
}

//$(function () {
//    dataTable = $('#listing_product_table').DataTable({
//        order: [1, 'asc'],
//        dom: 'T<"clear">lfrtip',
//        columns: [
//            {data: null, defaultContent: '', orderable: false},
//            {data: 'code'},
//            {data: 'brand'}
//        ],
//        tableTools: {
//            sRowSelect: 'os',
//            sRowSelector: 'td:first-child',
//            aButtons: ['select_all', 'select_none']
//        },
//        paging: false,
//        info: false,
//        scrollY: "250px",
//        scrollCollapse: true
//    });
//
//    $("#generate_po_detail_form").click(function () {
//        if (dataTable.rows('.selected').data().length == 0)
//            alert('You have not selected a product yet!');
//        else {
//            var productIds = [];
//            $.each(dataTable.rows('.selected')[0], function (index, value) {
//                productIds.push(dataTable.rows(value).nodes().to$().attr("id").split("_")[1]);
//            });
//            if (typeof purchaseOrderId === 'undefined')
//                $.get("/purchase_orders/get_product_details", {
//                    product_ids: productIds.join(","),
//                    previous_selected_product_ids: $("#product_ids").val()
//                });
//            else
//                $.get("/purchase_orders/get_product_details", {
//                    product_ids: productIds.join(","),
//                    purchase_order_id: purchaseOrderId,
//                    previous_selected_product_ids: $("#product_ids").val()
//                });
//        }
//
//        return false;
//    });
//
//    $("#purchase_order_request_delivery_date").datepicker({
//        dateFormat: "dd/mm/yy"
//    });
//
//    $('#purchase_order_purchase_order_date').datepicker({
//        dateFormat: "dd/mm/yy"
//    });
//
//    hideDeleteMarkedProduct();
//
//    if ($("#product_ids").val() != undefined && $("#product_ids").val() != "") {
//        var splittedProductIds = $("#product_ids").val().split(",");
//        $.each(splittedProductIds, function (index, value) {
//            var e = jQuery.Event("click");
//            e.ctrlKey = true;
//            $("#product_" + value).find("td:first-child").trigger(e);
//        });
//    }
//
//    if ($(".discount-fields").length > 0)
//        $(".discount-fields").numeric();
//
//    $('#purchase_order_price_discount').autoNumeric('init');
//    $('#purchase_order_first_discount').keypress(function (e) {
//        if (e.which == 13) {
//            if ($(this).val().trim() != "") {
//                $("#purchase_order_second_discount").prop("disabled", false);
//                $("#purchase_order_second_discount").focus();
//                $("#purchase_order_price_discount").val("");
//            }
//        }
//    });
//
//    $("#purchase_order_price_discount").keyup(function () {
//        if ($(this).val().trim() != "" && $(this).val().trim() != "Rp") {
//            $('#purchase_order_first_discount').val("");
//            $('#purchase_order_second_discount').val("");
//            $("#purchase_order_second_discount").prop("disabled", true);
//        }
//    });
//
//// ini untuk validasi di purchase order product, untuk cek apakah ada cost yang aktif pada tanggal PO
//    $(".po-form").submit(function () {
//        $(".purchase-order-date").val($("#purchase_order_purchase_order_date").val());
//        $(".purchase-order-vendor-id").val($("#purchase_order_vendor_id").val());
//    });
//
//});

$(document).on('turbolinks:load', function () {
    dataTable = $('#listing_product_table').DataTable({
        order: [1, 'asc'],
        dom: 'T<"clear">lfrtip',
        columns: [
            {data: null, defaultContent: '', orderable: false},
            {data: 'code'},
            {data: 'brand'}
        ],
        tableTools: {
            sRowSelect: 'os',
            sRowSelector: 'td:first-child',
            aButtons: ['select_all', 'select_none']
        },
        paging: false,
        info: false,
        scrollY: "250px",
        scrollCollapse: true
    });


    $("#generate_po_detail_form").click(function () {
        if (dataTable.rows('.selected').data().length == 0)
            alert('You have not selected a product yet!');
        else {
            var productIds = [];
            $.each(dataTable.rows('.selected')[0], function (index, value) {
                productIds.push(dataTable.rows(value).nodes().to$().attr("id").split("_")[1]);
            });
            if (typeof purchaseOrderId === 'undefined')
                $.get("/purchase_orders/get_product_details", {
                    product_ids: productIds.join(","),
                    previous_selected_product_ids: $("#product_ids").val()
                });
            else
                $.get("/purchase_orders/get_product_details", {
                    product_ids: productIds.join(","),
                    purchase_order_id: purchaseOrderId,
                    previous_selected_product_ids: $("#product_ids").val()
                });
        }

        return false;
    });

    $("#purchase_order_request_delivery_date").datepicker({
        dateFormat: "dd/mm/yy"
    });

    $('#purchase_order_purchase_order_date').datepicker({
        dateFormat: "dd/mm/yy"
    });

    hideDeleteMarkedProduct();

    if ($("#product_ids").val() != undefined && $("#product_ids").val() != "") {
        var splittedProductIds = $("#product_ids").val().split(",");
        $.each(splittedProductIds, function (index, value) {
            var e = jQuery.Event("click");
            e.ctrlKey = true;
            $("#product_" + value).find("td:first-child").trigger(e);
        });
    }

    if ($(".discount-fields").length > 0)
        $(".discount-fields").numeric();

    $('#purchase_order_price_discount').autoNumeric('init');
    $('#purchase_order_first_discount').keypress(function (e) {
        if (e.which == 13) {
            if ($(this).val().trim() != "") {
                $("#purchase_order_second_discount").prop("disabled", false);
                $("#purchase_order_second_discount").focus();
                $("#purchase_order_price_discount").val("");
            }
        }
    });

    $("#purchase_order_price_discount").keyup(function () {
        if ($(this).val().trim() != "" && $(this).val().trim() != "Rp") {
            $('#purchase_order_first_discount').val("");
            $('#purchase_order_second_discount').val("");
            $("#purchase_order_second_discount").prop("disabled", true);
        }
    });

    // ini untuk validasi di purchase order product, untuk cek apakah ada cost yang aktif pada tanggal PO
    $(".po-form").submit(function () {
        $(".purchase-order-date").val($("#purchase_order_purchase_order_date").val());
        $(".purchase-order-vendor-id").val($("#purchase_order_vendor_id").val());
    });

});