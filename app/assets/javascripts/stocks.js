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

});