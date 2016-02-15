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
                product_ids: $("#product_collections").val().join(",")
            });
        else
            $.get("/purchase_orders/get_product_details", {
                product_ids: $("#product_collections").val().join(","),
                purchase_order_id: purchaseOrderId
            });

        return false;
    });
    
    $("#purchase_order_request_delivery_date").datepicker({
        dateFormat:"dd/mm/yy"
    });

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
                product_ids: $("#product_collections").val().join(",")
            });
        else
            $.get("/purchase_orders/get_product_details", {
                product_ids: $("#product_collections").val().join(","),
                purchase_order_id: purchaseOrderId
            });

        return false;
    });
    
    $("#purchase_order_request_delivery_date").datepicker({
        dateFormat:"dd/mm/yy"
    });
});