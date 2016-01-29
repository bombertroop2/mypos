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
    
    $("#generate_po_detail_form").click(function() {
        $.get("/purchase_orders/get_product_details", {
            product_ids:$("#product_collections").val().join(",")
        });

        return false;
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
    
    $("#generate_po_detail_form").click(function() {
        $.get("/purchase_orders/get_product_details", {
            product_ids:$("#product_collections").val().join(",")
        });

        return false;
    });
});