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
    $("#product_collections").chosen({
        width: "25%"
    });

    $("#product_collections").change(function () {
        $("#submit-button").attr("disabled", "disabled");
        if ($(this).val() == null)
            $("#generate_po_detail_form").attr("disabled", "disabled");
        else
            $("#generate_po_detail_form").removeAttr("disabled");
    });

    $("#generate_po_detail_form").click(function () {
        if (typeof purchaseOrderId === 'undefined')
            $.get("/purchase_orders/get_product_details", {
                product_ids: $("#product_collections").val().join(","),
                previous_selected_product_ids: $("#product_ids").val()
            });
        else
            $.get("/purchase_orders/get_product_details", {
                product_ids: $("#product_collections").val().join(","),
                purchase_order_id: purchaseOrderId,
                previous_selected_product_ids: $("#product_ids").val()
            });

        return false;
    });

    $("#purchase_order_request_delivery_date").datepicker({
        dateFormat: "dd/mm/yy"
    });

    hideDeleteMarkedProduct();

});

$(document).on('page:load', function () {
    $("#product_collections").chosen({
        width: "25%"
    });

    $("#product_collections").change(function () {
        $("#submit-button").attr("disabled", "disabled");
        if ($(this).val() == null)
            $("#generate_po_detail_form").attr("disabled", "disabled");
        else
            $("#generate_po_detail_form").removeAttr("disabled");
    });

    $("#generate_po_detail_form").click(function () {
        if (typeof purchaseOrderId === 'undefined')
            $.get("/purchase_orders/get_product_details", {
                product_ids: $("#product_collections").val().join(","),
                previous_selected_product_ids: $("#product_ids").val()
            });
        else
            $.get("/purchase_orders/get_product_details", {
                product_ids: $("#product_collections").val().join(","),
                purchase_order_id: purchaseOrderId,
                previous_selected_product_ids: $("#product_ids").val()
            });

        return false;
    });

    $("#purchase_order_request_delivery_date").datepicker({
        dateFormat: "dd/mm/yy"
    });

    hideDeleteMarkedProduct();
});