var receivingDataTable = null;
var receivingDataTableDirectPurchase = null;

function autoScrollToBottomOfPage() {
    $("html, body").animate({
        scrollTop: $("html, body").get(0).scrollHeight
    }, 2000);
}

function selectRow(purchaseOrderId) {
    var e = jQuery.Event("click");
    $("#purchase_order_" + purchaseOrderId).find("td:first-child").trigger(e);
}

$(function () {
    $("#direct_purchase_receiving_date").datepicker({
        dateFormat: "dd/mm/yy"
    });

    // funny solution for silly bug
    $('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
        var target = $(e.target).attr("href") // activated tab
        if (target == "#direct_purchase" && ($('#listing_product_table_receiving').dataTable().fnSettings().aaSorting[0][0] == 1 || $('#listing_product_table_receiving').dataTable().fnSettings().aaSorting[0][0] === undefined)) {
            $("#code_th").click();
            $("#code_th").click();
        } else {
            // jika current sorted column ada di kolom name maka trigger klik
            if ($('#listing_purchase_order_table').dataTable().fnSettings().aaSorting[0][0] == 0 || $('#listing_purchase_order_table').dataTable().fnSettings().aaSorting[0][0] === undefined) {
                $("#number_th").click();
                $("#number_th").click();
            }
        }
    });
    receivingDataTableDirectPurchase = $('#listing_product_table_receiving').DataTable({
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

    receivingDataTable = $('#listing_purchase_order_table').DataTable({
        order: [0, 'asc'],
        dom: 'T<"clear">lfrtip',
        columns: [
            {data: 'number'},
            {data: 'status'},
            {data: 'vendor'},
            {data: 'warehouse'}
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

    $("#generate_receiving_po_form").click(function () {
        if (receivingDataTable.rows('.selected').data().length == 0)
            alert('You have not selected a purchase order yet!');
        else {
            var purchaseOrderId = receivingDataTable.rows(receivingDataTable.rows('.selected')[0][0]).nodes().to$().attr("id").split("_")[2];

            $.get("/receiving/" + purchaseOrderId + "/get_purchase_order");
        }

        return false;
    });

    $("#generate_dp_detail_form").click(function () {
        if (receivingDataTableDirectPurchase.rows('.selected').data().length == 0)
            alert('You have not selected a product yet!');
        else {
            var productIds = [];
            $.each(receivingDataTableDirectPurchase.rows('.selected')[0], function (index, value) {
                productIds.push(receivingDataTableDirectPurchase.rows(value).nodes().to$().attr("id").split("_")[1]);
            });
            $.get("/receiving/get_product_details", {
                product_ids: productIds.join(","),
                previous_selected_product_ids: $("#receiving_product_ids").val()
            });
        }

        return false;
    });

    $('#direct_purchase_first_discount').keypress(function (e) {
        if (e.which == 13) {
            if ($(this).val().trim() != "") {
                $("#direct_purchase_second_discount").prop("disabled", false);
                $("#direct_purchase_second_discount").focus();
                $("#direct_purchase_price_discount").val("");
            }
        }
    });
    $('#direct_purchase_price_discount').autoNumeric('init');
    if ($("#receiving_product_ids").val() != undefined && $("#receiving_product_ids").val() != "") {
        var splittedProductIds = $("#receiving_product_ids").val().split(",");
        $.each(splittedProductIds, function (index, value) {
            var e = jQuery.Event("click");
            e.ctrlKey = true;
            $("#product_" + value).find("td:first-child").trigger(e);
        });
    }

    $(".do-radio-button-direct-purchase").click(function () {
        if ($(this).val() == "yes")
            $("#direct_purchase_received_purchase_order_attributes_delivery_order_number").prop("disabled", false);
        else {
            $("#direct_purchase_received_purchase_order_attributes_delivery_order_number").val("");
            $("#direct_purchase_received_purchase_order_attributes_delivery_order_number").prop("disabled", true);
        }
    });
});

$(document).on('page:load', function () {
    $("#direct_purchase_receiving_date").datepicker({
        dateFormat: "dd/mm/yy"
    });

    // funny solution for silly bug
    $('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
        var target = $(e.target).attr("href") // activated tab
        if (target == "#direct_purchase" && ($('#listing_product_table_receiving').dataTable().fnSettings().aaSorting[0][0] == 1 || $('#listing_product_table_receiving').dataTable().fnSettings().aaSorting[0][0] === undefined)) {
            $("#code_th").click();
            $("#code_th").click();
        } else {
            // jika current sorted column ada di kolom name maka trigger klik
            if ($('#listing_purchase_order_table').dataTable().fnSettings().aaSorting[0][0] == 0 || $('#listing_purchase_order_table').dataTable().fnSettings().aaSorting[0][0] === undefined) {
                $("#number_th").click();
                $("#number_th").click();
            }
        }
    });
    receivingDataTableDirectPurchase = $('#listing_product_table_receiving').DataTable({
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

    receivingDataTable = $('#listing_purchase_order_table').DataTable({
        order: [0, 'asc'],
        dom: 'T<"clear">lfrtip',
        columns: [
            {data: 'number'},
            {data: 'status'},
            {data: 'vendor'},
            {data: 'warehouse'}
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
    $("#generate_receiving_po_form").click(function () {
        if (receivingDataTable.rows('.selected').data().length == 0)
            alert('You have not selected a purchase order yet!');
        else {
            var purchaseOrderId = receivingDataTable.rows(receivingDataTable.rows('.selected')[0][0]).nodes().to$().attr("id").split("_")[2];

            $.get("/receiving/" + purchaseOrderId + "/get_purchase_order");
        }

        return false;
    });

    $("#generate_dp_detail_form").click(function () {
        if (receivingDataTableDirectPurchase.rows('.selected').data().length == 0)
            alert('You have not selected a product yet!');
        else {
            var productIds = [];
            $.each(receivingDataTableDirectPurchase.rows('.selected')[0], function (index, value) {
                productIds.push(receivingDataTableDirectPurchase.rows(value).nodes().to$().attr("id").split("_")[1]);
            });

            $.get("/receiving/get_product_details", {
                product_ids: productIds.join(","),
                previous_selected_product_ids: $("#receiving_product_ids").val()
            });
        }

        return false;
    });

    $('#direct_purchase_first_discount').keypress(function (e) {
        if (e.which == 13) {
            if ($(this).val().trim() != "") {
                $("#direct_purchase_second_discount").prop("disabled", false);
                $("#direct_purchase_second_discount").focus();
                $("#direct_purchase_price_discount").val("");
            }
        }
    });
    $('#direct_purchase_price_discount').autoNumeric('init');
    if ($("#receiving_product_ids").val() != undefined && $("#receiving_product_ids").val() != "") {
        var splittedProductIds = $("#receiving_product_ids").val().split(",");
        $.each(splittedProductIds, function (index, value) {
            var e = jQuery.Event("click");
            e.ctrlKey = true;
            $("#product_" + value).find("td:first-child").trigger(e);
        });
    }

    $(".do-radio-button-direct-purchase").click(function () {
        if ($(this).val() == "yes")
            $("#direct_purchase_received_purchase_order_attributes_delivery_order_number").prop("disabled", false);
        else {
            $("#direct_purchase_received_purchase_order_attributes_delivery_order_number").val("");
            $("#direct_purchase_received_purchase_order_attributes_delivery_order_number").prop("disabled", true);
        }
    });

});