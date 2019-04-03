$(function () {
    $("#print_barcode_temp_effective_date").datepicker({
        dateFormat: "dd/mm/yy"
    });
    $("#print_barcode_temp_price_code").attr("data-placeholder", "Please select").chosen();
    $("#print_barcode_temp_product_code").autocomplete({
        source: "/print_barcode_temps/search_product",
        minLength: 2
    });
    $("#btn_add_print_product").click(function () {
        if ($("#print_barcode_temp_price_code").val().trim() == "")
            bootbox.alert({message: "Please select price code first", size: 'small'});
        else if ($("#print_barcode_temp_effective_date").val().trim() == "")
            bootbox.alert({message: "Please select effective date first", size: 'small'});
        else if ($("#print_barcode_temp_product_code").val().trim() == "")
            bootbox.alert({message: "Please fill in product code first", size: 'small'});
        else {
            $.get("/print_barcode_temps/add_product", {
                price_code_id: $("#print_barcode_temp_price_code").val().trim(),
                effective_date: $("#print_barcode_temp_effective_date").val().trim(),
                product_code: $("#print_barcode_temp_product_code").val().trim()
            });
        }
    });
    $('#print_barcode_temp_product_code').keypress(function (e) {
        var key = e.which;
        if (key == 13)  // the enter key code
        {
            $("#btn_add_print_product").click();
            return false;
        }
    });
});