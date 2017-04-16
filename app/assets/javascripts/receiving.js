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
    /*
    $('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
        var target = $(e.target).attr("href") // activated tab
        if (target == "#direct_purchase" && ($('#listing_product_table_receiving').dataTable().fnSettings().aaSorting[0][0] == 1 || $('#listing_product_table_receiving').dataTable().fnSettings().aaSorting[0][0] === undefined)) {
            $("#code_th").click();
            $("#code_th").click();
        } 
    });*/

    $('#filter-receiving-date').daterangepicker(
            {
                locale: {
                    format: 'DD/MM/YYYY'
                },
                opens: "left",
                autoUpdateInput: false
            });
    $('#filter-receiving-date').on('apply.daterangepicker', function (ev, picker) {
        $(this).val(picker.startDate.format('DD/MM/YYYY') + ' - ' + picker.endDate.format('DD/MM/YYYY'));
    });

    $('#filter-receiving-date').on('cancel.daterangepicker', function (ev, picker) {
        $(this).val('');
    });

});