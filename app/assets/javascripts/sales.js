var eventPurchasedProductDataTables = null;
var bootboxDialogForm = null;
var bootboxDialogFormGiftEvent = null;
var bootboxDialogBOGOForm = [];
var buttonFinishClicked = false;

$(function () {
    $(".actionBar > .buttonNext").click(function () {
        if ($("#step-2").is(":visible")) {
            $("#list-step-2").click();
        } else if ($("#step-3").is(":visible")) {
            $("#list-step-3").click();
        } else if ($("#step-4").is(":visible")) {
            $("#list-step-4").click();
        }
    });
    $(".actionBar > .buttonPrevious").click(function () {
        if ($("#step-2").is(":visible"))
            $("#barcode").focus();
        else if ($("#step-1").is(":visible"))
            $("#member-id").focus();
        $($(".stepContainer")[0]).css("overflow-x", "hidden");
    });
    $(".actionBar > .buttonFinish").click(function () {
        var boxSaleConfirm = null;
        if (buttonFinishClicked == false) {
            boxSaleConfirm = bootbox.confirm({
                message: "Once you create transaction, you'll not be able to change or delete it</br>Are you sure?",
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
                        $("#new_sale").submit();
                    }
                },
                size: "small"
            });
        }
        buttonFinishClicked = true;
        boxSaleConfirm.on("hidden.bs.modal", function () {
            buttonFinishClicked = false;
        });
    });

    $("#list-step-1").click(function () {
        var processId = setInterval(function () {
            if ($("#member-id").is(":focus")) {
                clearInterval(processId);
            } else {
                $("#member-id").focus();
            }
        }, 0);
        $($(".stepContainer")[0]).css("overflow-x", "hidden");
    });
    $("#list-step-2").click(function () {
        var processId = setInterval(function () {
            if ($("#barcode").is(":focus")) {
                clearInterval(processId);
            } else {
                $("#barcode").focus();
            }
        }, 0);
        $($(".stepContainer")[0]).css("overflow-x", "visible");
    });
    $("#list-step-4").click(function () {
        var stockFormProcessId = setInterval(function () {
            if ($("#barcode_stock_form").is(":focus")) {
                clearInterval(stockFormProcessId);
            } else {
                $("#barcode_stock_form").focus();
            }
        }, 0);
    });

    $("#list-step-3").click(function () {
        $("#sale_payment_method").attr("data-placeholder", "Please select").chosen();
        $("#sale_bank_id").attr("data-placeholder", "Please select").chosen("destroy").chosen();
        $($(".stepContainer")[0]).css("overflow-x", "visible");
        $("#sale_payment_method").trigger("chosen:activate");
        $("#payment_form_total_sale").html($("#total-sale").html());
        var saleTotal = parseFloat($("#payment_form_total_sale").html().trim().replace(/\Rp/g, '').replace(/\./g, '').replace(/\,/g, '.'));
        if (isNaN(saleTotal))
            saleTotal = 0;
        var memberDiscount = parseFloat($("#sale_member_discount").val());
        if (isNaN(memberDiscount))
            memberDiscount = 0;
        var memberDiscountInMoney = saleTotal * (memberDiscount / 100);
        var totalAfterMemberDiscount = saleTotal - memberDiscountInMoney;
        $("#payment_form_member_discount").html(memberDiscountInMoney);
        $("#payment_form_member_discount").toCurrency({
            precision: 2, // decimal precision
            delimiter: ".", // thousands delimiter
            separator: ",", // decimal separator
            unit: "Rp", // unit
            format: "%u%n", // format. %u is the placeholder for the unit, %n for the number
            negativeFormat: false   // format for negative numbers. If false, it defaults to the same format as positive numbers
        });
        $("#payment_form_total_sale_after_discount").html(totalAfterMemberDiscount);
        $("#payment_form_total_sale_after_discount").toCurrency({
            precision: 2, // decimal precision
            delimiter: ".", // thousands delimiter
            separator: ",", // decimal separator
            unit: "Rp", // unit
            format: "%u%n", // format. %u is the placeholder for the unit, %n for the number
            negativeFormat: false   // format for negative numbers. If false, it defaults to the same format as positive numbers
        });
        if ($("#sale_cash").val().trim() != "") {
            var cashValue = parseFloat($("#sale_cash").val().trim().replace(/\Rp/g, '').replace(/\./g, '').replace(/\,/g, '.'));
            if (isNaN(cashValue))
                cashValue = 0;

            var giftEventDiscount = parseFloat($("#sale_gift_event_discount_field").html().trim().replace(/\Rp/g, '').replace(/\./g, '').replace(/\,/g, '.'));
            if (isNaN(giftEventDiscount) || !$("#sale_gift_event_discount_field").is(":visible"))
                giftEventDiscount = 0;

            var totalAfterGiftDiscount = saleTotal - giftEventDiscount;
            var memberDiscountInMoney = totalAfterGiftDiscount * (memberDiscount / 100);
            var totalAfterMemberDiscount = totalAfterGiftDiscount - memberDiscountInMoney;
            var moneyChange = cashValue - totalAfterMemberDiscount;
            $("#payment_form_sale_change").html(moneyChange);
            $("#payment_form_sale_change").toCurrency({
                precision: 2, // decimal precision
                delimiter: ".", // thousands delimiter
                separator: ",", // decimal separator
                unit: "Rp", // unit
                format: "%u%n", // format. %u is the placeholder for the unit, %n for the number
                negativeFormat: false   // format for negative numbers. If false, it defaults to the same format as positive numbers
            });
            $("#payment_form_member_discount").html(memberDiscountInMoney);
            $("#payment_form_member_discount").toCurrency({
                precision: 2, // decimal precision
                delimiter: ".", // thousands delimiter
                separator: ",", // decimal separator
                unit: "Rp", // unit
                format: "%u%n", // format. %u is the placeholder for the unit, %n for the number
                negativeFormat: false   // format for negative numbers. If false, it defaults to the same format as positive numbers
            });
            $("#payment_form_total_sale_after_discount").html(totalAfterMemberDiscount);
            $("#payment_form_total_sale_after_discount").toCurrency({
                precision: 2, // decimal precision
                delimiter: ".", // thousands delimiter
                separator: ",", // decimal separator
                unit: "Rp", // unit
                format: "%u%n", // format. %u is the placeholder for the unit, %n for the number
                negativeFormat: false   // format for negative numbers. If false, it defaults to the same format as positive numbers
            });
        }
        if ($("#sale_gift_event_discount_field").is(":visible")) {
            var giftEventDiscount = parseFloat($("#sale_gift_event_discount_field").html().trim().replace(/\Rp/g, '').replace(/\./g, '').replace(/\,/g, '.'));
            if (isNaN(giftEventDiscount))
                giftEventDiscount = 0;

            var totalAfterGiftDiscount = saleTotal - giftEventDiscount;
            var memberDiscountInMoney = totalAfterGiftDiscount * (memberDiscount / 100);
            var totalAfterMemberDiscount = totalAfterGiftDiscount - memberDiscountInMoney;
            $("#payment_form_total_sale_after_discount").html(totalAfterMemberDiscount);
            $("#payment_form_total_sale_after_discount").toCurrency({
                precision: 2, // decimal precision
                delimiter: ".", // thousands delimiter
                separator: ",", // decimal separator
                unit: "Rp", // unit
                format: "%u%n", // format. %u is the placeholder for the unit, %n for the number
                negativeFormat: false   // format for negative numbers. If false, it defaults to the same format as positive numbers
            });
            $("#payment_form_member_discount").html(memberDiscountInMoney);
            $("#payment_form_member_discount").toCurrency({
                precision: 2, // decimal precision
                delimiter: ".", // thousands delimiter
                separator: ",", // decimal separator
                unit: "Rp", // unit
                format: "%u%n", // format. %u is the placeholder for the unit, %n for the number
                negativeFormat: false   // format for negative numbers. If false, it defaults to the same format as positive numbers
            });
        }
    });

    $("#discount_product").change(function () {
        if ($(this).val() == "Discount") {
            $("#sale_event_gift_discount_amount_field_layout").removeClass("hidden");
            $("#modal_form_btn_add_event_gift_product").removeClass("hidden");
            $(".gift-event-product-search-fields").addClass("hidden");
            $("#sale_event_gift_product_color_field_container").html("");
            $("#sale_event_gift_product_size_field_container").html("");
        } else if ($(this).val() == "Product") {
            $("#sale_event_gift_discount_amount_field_layout").addClass("hidden");
            $("#modal_form_btn_add_event_gift_product").addClass("hidden");
            $(".gift-event-product-search-fields").removeClass("hidden");
            $("#sale_event_gift_product_color_field_container").html("");
            $("#sale_event_gift_product_size_field_container").html("");
            var processId = setInterval(function () {
                if ($("#gift_event_product_barcode").is(":focus")) {
                    clearInterval(processId);
                } else {
                    $("#gift_event_product_barcode").focus();
                }
            }, 0);
        }
    });

    $("#modal_form_btn_add_event_gift_product").click(function () {
        if ($("#discount_product").val() == "Discount") {
            if (bootboxDialogFormGiftEvent != null)
                bootboxDialogFormGiftEvent.modal("hide");
            $("#sale_gift_event_discount_field_layout").removeClass("hidden");
            $("#sale_gift_event_discount_field").html($("#sale_event_gift_discount_amount").html());
            $("#sale_gift_event_gift_type").val($("#discount_product").val());
            $("#sale_gift_event_gift_item").addClass("hidden");
            $("#payment_form_gift_item_field").html("");
            if ($("#sale_gift_event_discount_field").is(":visible")) {
                var saleTotal = parseFloat($("#payment_form_total_sale").html().trim().replace(/\Rp/g, '').replace(/\./g, '').replace(/\,/g, '.'));
                if (isNaN(saleTotal))
                    saleTotal = 0;

                var giftEventDiscount = parseFloat($("#sale_gift_event_discount_field").html().trim().replace(/\Rp/g, '').replace(/\./g, '').replace(/\,/g, '.'));
                if (isNaN(giftEventDiscount))
                    giftEventDiscount = 0;

                var memberDiscount = parseFloat($("#sale_member_discount").val());
                if (isNaN(memberDiscount))
                    memberDiscount = 0;

                var totalAfterGiftDiscount = saleTotal - giftEventDiscount;
                var memberDiscountInMoney = totalAfterGiftDiscount * (memberDiscount / 100);
                var totalAfterMemberDiscount = totalAfterGiftDiscount - memberDiscountInMoney;
                $("#payment_form_total_sale_after_discount").html(totalAfterMemberDiscount);
                $("#payment_form_total_sale_after_discount").toCurrency({
                    precision: 2, // decimal precision
                    delimiter: ".", // thousands delimiter
                    separator: ",", // decimal separator
                    unit: "Rp", // unit
                    format: "%u%n", // format. %u is the placeholder for the unit, %n for the number
                    negativeFormat: false   // format for negative numbers. If false, it defaults to the same format as positive numbers
                });
                $("#payment_form_member_discount").html(memberDiscountInMoney);
                $("#payment_form_member_discount").toCurrency({
                    precision: 2, // decimal precision
                    delimiter: ".", // thousands delimiter
                    separator: ",", // decimal separator
                    unit: "Rp", // unit
                    format: "%u%n", // format. %u is the placeholder for the unit, %n for the number
                    negativeFormat: false   // format for negative numbers. If false, it defaults to the same format as positive numbers
                });
            }
            if (!$("#step-3").is(":visible")) {
                $("#list-step-3").click();
            } else {
                if ($("#sale_cash").val().trim() != "") {
                    var cashValue = parseFloat($("#sale_cash").val().trim().replace(/\Rp/g, '').replace(/\./g, '').replace(/\,/g, '.'));
                    if (isNaN(cashValue))
                        cashValue = 0;

                    var saleTotal = parseFloat($("#payment_form_total_sale").html().trim().replace(/\Rp/g, '').replace(/\./g, '').replace(/\,/g, '.'));
                    if (isNaN(saleTotal))
                        saleTotal = 0;

                    var giftEventDiscount = parseFloat($("#sale_gift_event_discount_field").html().trim().replace(/\Rp/g, '').replace(/\./g, '').replace(/\,/g, '.'));
                    if (isNaN(giftEventDiscount) || !$("#sale_gift_event_discount_field").is(":visible"))
                        giftEventDiscount = 0;

                    var memberDiscount = parseFloat($("#sale_member_discount").val());
                    if (isNaN(memberDiscount))
                        memberDiscount = 0;

                    var totalAfterGiftDiscount = saleTotal - giftEventDiscount;
                    var memberDiscountInMoney = totalAfterGiftDiscount * (memberDiscount / 100);
                    var totalAfterMemberDiscount = totalAfterGiftDiscount - memberDiscountInMoney;
                    var moneyChange = cashValue - totalAfterMemberDiscount;
                    $("#payment_form_sale_change").html(moneyChange);
                    $("#payment_form_sale_change").toCurrency({
                        precision: 2, // decimal precision
                        delimiter: ".", // thousands delimiter
                        separator: ",", // decimal separator
                        unit: "Rp", // unit
                        format: "%u%n", // format. %u is the placeholder for the unit, %n for the number
                        negativeFormat: false   // format for negative numbers. If false, it defaults to the same format as positive numbers
                    });
                    $("#payment_form_member_discount").html(memberDiscountInMoney);
                    $("#payment_form_member_discount").toCurrency({
                        precision: 2, // decimal precision
                        delimiter: ".", // thousands delimiter
                        separator: ",", // decimal separator
                        unit: "Rp", // unit
                        format: "%u%n", // format. %u is the placeholder for the unit, %n for the number
                        negativeFormat: false   // format for negative numbers. If false, it defaults to the same format as positive numbers
                    });
                    $("#payment_form_total_sale_after_discount").html(totalAfterMemberDiscount);
                    $("#payment_form_total_sale_after_discount").toCurrency({
                        precision: 2, // decimal precision
                        delimiter: ".", // thousands delimiter
                        separator: ",", // decimal separator
                        unit: "Rp", // unit
                        format: "%u%n", // format. %u is the placeholder for the unit, %n for the number
                        negativeFormat: false   // format for negative numbers. If false, it defaults to the same format as positive numbers
                    });
                }
            }
            $($(".stepContainer")[0]).css("height", "100%");
        } else if ($("#discount_product").val() == "Product") {
            $.get("/sales/get_gift_event_product", {
                product_code: $("#sale_event_gift_product_code").val().trim(),
                product_color: $("#sale_gift_event_product_color").val().trim(),
                product_size: $("#sale_gift_event_product_size").val().trim()
            });
        }
    });

    $("#gift-event-search-barcode-btn").click(function () {
        $("#gift_event_product_barcode").blur();
        $.get("/sales/get_gift_event_product", {
            barcode: $("#gift_event_product_barcode").val().trim()
        });

    });

    $('#gift_event_product_barcode').keypress(function (e) {
        var key = e.which;
        if (key == 13)  // the enter key code
        {
            $(this).blur();
            $("#gift-event-search-barcode-btn").click();
            return false;
        }
    });

    $("#sale_event_gift_product_code").keypress(function (e) {
        var key = e.which;
        if (key == 13)  // the enter key code
        {
            $.get("/sales/get_gift_event_product_colors", {
                product_code: $("#sale_event_gift_product_code").val().trim()
            });
            return false;
        }
    });

    $('#filter-sale-transaction-time').daterangepicker(
            {
//                locale: {
//                    format: 'DD/MM/YYYY HH:mm:ss'
//                },
                locale: {
                    format: 'DD/MM/YYYY'
                },
                opens: "left",
                autoUpdateInput: false/*,
                 timePicker: true,
                 timePicker24Hour: true,
                 timePickerSeconds: true*/
            });
    $('#filter-sale-transaction-time').on('apply.daterangepicker', function (ev, picker) {
//        $(this).val(picker.startDate.format('DD/MM/YYYY HH:mm:ss') + ' - ' + picker.endDate.format('DD/MM/YYYY HH:mm:ss'));
        $(this).val(picker.startDate.format('DD/MM/YYYY') + ' - ' + picker.endDate.format('DD/MM/YYYY'));
    });

    $('#filter-sale-transaction-time').on('cancel.daterangepicker', function (ev, picker) {
        $(this).val('');
    });
    $("#filter-sale-warehouse-id").attr("data-placeholder", "Warehouse").chosen({width: "200px"});
    $("#export-sale-btn").click(function () {
        $("#filter_payment_method_export").val($("#filter-payment-method").val());
        $("#filter_date_export").val($("#filter-sale-transaction-time").val());
        $("#filter_string_export").val($("#filter-string").val());
        $("#filter_warehouse_export").val($("#filter-sale-warehouse-id").val());
        $("#export_pos").submit();
    });

    $("#sales_promotion_girl_id").attr("data-placeholder", "Please select").chosen({width: "100%"});
    $("#sales_promotion_girl_id").change(function () {
        $("#search-barcode-btn").prop("disabled", false);
        $("#search-sale-product-btn").prop("disabled", false);
    });
});
