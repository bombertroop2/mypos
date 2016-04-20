var receivingDataTable = null;

function autoScrollToBottomOfPage() {
    $("html, body").animate({
        scrollTop: $("html, body").get(0).scrollHeight
    }, 1500);
}

function selectRow(purchaseOrderId) {
    var e = jQuery.Event("click");
    $("#purchase_order_" + purchaseOrderId).find("td:first-child").trigger(e);
}

$(function () {
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
});

$(document).on('page:load', function () {
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
});