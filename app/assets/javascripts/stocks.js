$(function () {
    $("#warehouse_id").attr("data-placeholder", "Please select warehouse").chosen();
    $("#warehouse_id_chosen").addClass("text-left");
    $("#search-stock-btn").click(function () {
        if ($("#warehouse_id").val() !== undefined && $("#warehouse_id").val() == "")
            bootbox.alert({message: "Please select warehouse first!", size: "small"});
        else {
            $("#filter_warehouse_id").val($("#warehouse_id").val());
            $("#filter_product_criteria").val($("#product_criteria").val());
            $(".smart-listing-controls").submit();
        }
    });
    $('input[type=radio][name=product_filter_mode]').change(function () {
        if (this.value == 'All') {
            $("#product_criteria").val("");
            $("#product_criteria").css("cursor", "not-allowed");
            $("#product_criteria").attr("readonly", true);
        } else if (this.value == 'Filter') {
            $("#product_criteria").css("cursor", "auto");
            $("#product_criteria").attr("readonly", false);
            $("#product_criteria").focus();
        }
    });    
});