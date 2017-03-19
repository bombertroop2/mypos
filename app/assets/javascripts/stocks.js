$(function () {
    $("#warehouse_id").attr("data-placeholder", "Please select warehouse").chosen();
    $("#warehouse_id_chosen").addClass("text-left");
    $("#search-stock-btn").click(function () {
        $("#filter_warehouse_id").val($("#warehouse_id").val());
        $("#filter_product_criteria").val($("#filter-product-criteria").val());
        $(".smart-listing-controls").submit();
    });

});