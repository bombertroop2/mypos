var bootboxDialogFormConsale = null;

$(function () {
    $('#filter-consale-transaction-date').daterangepicker(
            {
                locale: {
                    format: 'DD/MM/YYYY'
                },
                opens: "left",
                autoUpdateInput: false
            });
    $('#filter-consale-transaction-date').on('apply.daterangepicker', function (ev, picker) {
        $(this).val(picker.startDate.format('DD/MM/YYYY') + ' - ' + picker.endDate.format('DD/MM/YYYY'));
    });

    $('#filter-consale-transaction-date').on('cancel.daterangepicker', function (ev, picker) {
        $(this).val('');
    });

    $("#search-consale-btn").click(function () {
        $("#filter_date").val($("#filter-consale-transaction-date").val());
        $("#filter_string").val($("#filter-string").val());
        if ($("#filter-counter-warehouse").length > 0)
            $("#filter_counter_warehouse").val($("#filter-counter-warehouse").val());
        $(".smart-listing-controls").submit();
    });

    $("#consignment_sale_transaction_date").datepicker({
        dateFormat: "dd/mm/yy"
    });

    $('#consale_barcode').keypress(function (e) {
        var key = e.which;
        if (key == 13)  // the enter key code
        {
            $("#consale_barcode").blur();
            if ($("#consignment_sale_transaction_date").val().trim() == "")
                bootbox.alert({message: "Please fill in transaction date first", size: 'small'});
            else
                $("#search-barcode-btn-consale").click();
            return false;
        }
    });

    $("#search-barcode-btn-consale").click(function () {
        if ($("#consignment_sale_transaction_date").val().trim() == "")
            bootbox.alert({message: "Please fill in transaction date first", size: 'small'});
        else if ($("#consignment_sale_warehouse_id").length > 0 && $("#consignment_sale_warehouse_id").val().trim() == "")
            bootbox.alert({message: "Please select warehouse first", size: 'small'});
        else {
            if ($("#consignment_sale_warehouse_id").length > 0) {
                if ($("#consignment_sale_counter_event_id").length > 0 && $("#consignment_sale_counter_event_id").val().trim() != "") {
                    $.get("/consignment_sales/get_product", {
                        barcode: $("#consale_barcode").val().trim(),
                        transaction_date: $("#consignment_sale_transaction_date").val().trim(),
                        warehouse_id: $("#consignment_sale_warehouse_id").val().trim(),
                        counter_event_id: $("#consignment_sale_counter_event_id").val().trim()
                    });
                } else {
                    $.get("/consignment_sales/get_product", {
                        barcode: $("#consale_barcode").val().trim(),
                        transaction_date: $("#consignment_sale_transaction_date").val().trim(),
                        warehouse_id: $("#consignment_sale_warehouse_id").val().trim()
                    });

                }
            } else {
                if ($("#consignment_sale_counter_event_id").length > 0 && $("#consignment_sale_counter_event_id").val().trim() != "") {
                    $.get("/consignment_sales/get_product", {
                        barcode: $("#consale_barcode").val().trim(),
                        transaction_date: $("#consignment_sale_transaction_date").val().trim(),
                        counter_event_id: $("#consignment_sale_counter_event_id").val().trim()
                    });
                } else {
                    $.get("/consignment_sales/get_product", {
                        barcode: $("#consale_barcode").val().trim(),
                        transaction_date: $("#consignment_sale_transaction_date").val().trim()
                    });
                }
            }
        }
    });

    $("#consignment_sale_submit_button").click(function () {
        if ($("#consignment_sale_transaction_date").val().trim() == "")
            bootbox.alert({message: "Please fill in transaction date first", size: 'small'});
        else if ($("#consignment_sale_warehouse_id").length > 0 && $("#consignment_sale_warehouse_id").val().trim() == "")
            bootbox.alert({message: "Please select warehouse first", size: 'small'});
        else {
            bootbox.confirm({
                message: "Once you create transaction, you'll not be able to change it</br>Are you sure?",
                buttons: {
                    confirm: {
                        label: '<i class="fa fa-check"></i> Confirm'
                    },
                    cancel: {
                        label: '<i class="fa fa-times"></i> Cancel'
                    }
                },
                callback: function (result) {
                    if (result) {
                        $("body").css('padding-right', '0px');
                        $("#consignment_sale_no_sale").val("false");
                        $("#new_consignment_sale").submit();
                    }
                },
                size: "small"
            });
        }
        return false;
    });

    $("#consignment_sale_no_sale_button").click(function () {
        if ($("#consignment_sale_transaction_date").val().trim() == "")
            bootbox.alert({message: "Please fill in transaction date first", size: 'small'});
        else if ($("#consignment_sale_warehouse_id").length > 0 && $("#consignment_sale_warehouse_id").val().trim() == "")
            bootbox.alert({message: "Please select warehouse first", size: 'small'});
        else {
            bootbox.confirm({
                message: "Once you create transaction, you'll not be able to change it</br>Are you sure?",
                buttons: {
                    confirm: {
                        label: '<i class="fa fa-check"></i> Confirm'
                    },
                    cancel: {
                        label: '<i class="fa fa-times"></i> Cancel'
                    }
                },
                callback: function (result) {
                    if (result) {
                        $("body").css('padding-right', '0px');
                        $("#consignment_sale_no_sale").val("true");
                        $("#new_consignment_sale").submit();
                    }
                },
                size: "small"
            });
        }
        return false;
    });

    $('#search-consale-product-btn').on('click', function () {
        if ($("#consignment_sale_transaction_date").val().trim() == "")
            bootbox.alert({message: "Please fill in transaction date first", size: 'small'});
        else if ($("#consignment_sale_warehouse_id").length > 0 && $("#consignment_sale_warehouse_id").val().trim() == "")
            bootbox.alert({message: "Please select warehouse first", size: 'small'});
        else {
            bootboxDialogFormConsale = bootbox
                    .dialog({
                        title: 'Search Product',
                        message: $('#searchConsaleProductForm'),
                        show: false, /* We will show it manually later */
                        onEscape: true
                    }).on('shown.bs.modal', function () {
                $('#searchConsaleProductForm')
                        .show();
                $("#consale_product_code").focus();
                $("#consale_product_code").val("");
                $("#consale_product_color_field_container").html("");
                $("#consale_product_size_field_container").html("");
                $("#modal_form_btn_add_product_consale").addClass("hidden");
            }).on('hide.bs.modal', function (e) {
                $('#searchConsaleProductForm').hide().appendTo('body');
                var processId = setInterval(function () {
                    if ($("#consale_barcode").is(":focus")) {
                        clearInterval(processId);
                    } else {
                        $("#consale_barcode").focus();
                    }
                }, 0);
            }).modal('show');
        }
    });

    $('#consale_product_code').keypress(function (e) {
        var key = e.which;
        if (key == 13)  // the enter key code
        {
            if ($("#consignment_sale_warehouse_id").length > 0) {
                $.get("/consignment_sales/get_product_colors", {
                    product_code: $("#consale_product_code").val().trim(),
                    warehouse_id: $("#consignment_sale_warehouse_id").val().trim()
                });
            } else {
                $.get("/consignment_sales/get_product_colors", {
                    product_code: $("#consale_product_code").val().trim()
                });
            }
            return false;
        }
    });

    $("#consignment_sale_warehouse_id").attr("data-placeholder", "Select").chosen();
    $("#consignment_sale_warehouse_id_chosen").css("width", "25%");

    $("#consignment_sale_transaction_date").change(function () {
        $("#detail_form_container").html("");
        if ($("#consignment_sale_warehouse_id").length > 0 && $("#consignment_sale_warehouse_id").val().trim() != "") {
            $.get("/consignment_sales/get_events", {
                warehouse_id: $("#consignment_sale_warehouse_id").val().trim(),
                transaction_date: $("#consignment_sale_transaction_date").val().trim()
            });
        } else {
            $.get("/consignment_sales/get_events", {
                transaction_date: $("#consignment_sale_transaction_date").val().trim()
            });
        }
    });

    $("#consignment_sale_warehouse_id").change(function () {
        $("#detail_form_container").html("");
        if ($("#consignment_sale_transaction_date").val().trim() != "") {
            $.get("/consignment_sales/get_events", {
                warehouse_id: $("#consignment_sale_warehouse_id").val().trim(),
                transaction_date: $("#consignment_sale_transaction_date").val().trim()
            });
        }
    });

});