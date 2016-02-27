$(function () {
    $("#purchase_return_purchase_order_id").change(function () {
        $.get("/purchase_returns/get_purchase_order_details", {
            purchase_order_id: $(this).val()
        });
    });

    $(".quantity").numeric({
        decimal: false,
        negative: false
    }, function () {
        alert("Positive integers only");
        this.value = "";
        this.focus();
    });

});

$(document).on('page:load', function () {
    $("#purchase_return_purchase_order_id").change(function () {
        $.get("/purchase_returns/get_purchase_order_details", {
            purchase_order_id: $(this).val()
        });
    });

    $(".quantity").numeric({
        decimal: false,
        negative: false
    }, function () {
        alert("Positive integers only");
        this.value = "";
        this.focus();
    });

});