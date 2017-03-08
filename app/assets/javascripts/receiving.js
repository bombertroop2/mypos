function autoScrollToBottomOfPage() {
    $("html, body").animate({
        scrollTop: $("html, body").get(0).scrollHeight
    }, 2000);
}

//function selectRow(purchaseOrderId) {
//    var e = jQuery.Event("click");
//    $("#purchase_order_" + purchaseOrderId).find("td:first-child").trigger(e);
//}


$(function () {
    // funny solution for silly bug
    $('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
        var target = $(e.target).attr("href") // activated tab
        if (target == "#direct_purchase" && ($('#listing_product_table_receiving').dataTable().fnSettings().aaSorting[0][0] == 1 || $('#listing_product_table_receiving').dataTable().fnSettings().aaSorting[0][0] === undefined)) {
            $("#code_th").click();
            $("#code_th").click();
        } /*else {
            // jika current sorted column ada di kolom name maka trigger klik
            if ($('#listing_purchase_order_table').dataTable().fnSettings().aaSorting[0][0] == 0 || $('#listing_purchase_order_table').dataTable().fnSettings().aaSorting[0][0] === undefined) {
                $("#number_th").click();
                $("#number_th").click();
            }
        }*/
    });
});