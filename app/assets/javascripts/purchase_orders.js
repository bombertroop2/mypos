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
        if ($(this).find("[type='checkbox']").length > 0 && $(this).find("[type='checkbox']").is(":checked") && $("#product_collections").val().indexOf(productId) < 0)
            $(this).hide();
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

$(function () {
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

    hideDeleteMarkedProduct();

    if ($("#product_ids").val() != undefined && $("#product_ids").val() != "") {
        var splittedProductIds = $("#product_ids").val().split(",");
        $.each(splittedProductIds, function (index, value) {
            var e = jQuery.Event("click");
            e.ctrlKey = true;
            $("#product_" + value).find("td:first-child").trigger(e);
        });
    }

});

$(document).on('page:load', function () {
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

    hideDeleteMarkedProduct();

    if ($("#product_ids").val() != undefined && $("#product_ids").val() != "") {
        var splittedProductIds = $("#product_ids").val().split(",");
        $.each(splittedProductIds, function (index, value) {
            var e = jQuery.Event("click");
            e.ctrlKey = true;
            $("#product_" + value).find("td:first-child").trigger(e);
        });
    }
});