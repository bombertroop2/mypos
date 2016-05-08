/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */


$(function () {
    $("#product_size_group_id").change(function () {
        // split isi dari action attributnya form untuk ambil id produk
        var splittedAction = $(".form-horizontal").attr("action").split("/");
        if (splittedAction.length == 2)
            $.get("/products/populate_detail_form", {
                id: $(this).val()
            });
        else if (splittedAction.length == 3)
            $.get("/products/populate_detail_form", {
                id: $(this).val(),
                product_id: splittedAction[2]
            });
    });

    $("#product_cost_lists_attributes_0_effective_date").datepicker({
        dateFormat: "dd/mm/yy"
    });

    $('#product_cost_lists_attributes_0_cost').autoNumeric('init');  //autoNumeric with defaults

    if ($("#new_product").length > 0)
        $("#new_product").submit(function () {
            $(".price-effective-date").val($("#product_cost_lists_attributes_0_effective_date").val());
        });
    else if ($(".form-horizontal").length > 0)
        $(".form-horizontal").submit(function () {
            $(".price-effective-date").val($("#product_effective_date").val());
        });

});

// ini untuk turbolink gem
$(document).on('page:load', function () {
    $("#product_size_group_id").change(function () {
        // split isi dari action attributnya form untuk ambil id produk
        var splittedAction = $(".form-horizontal").attr("action").split("/");
        if (splittedAction.length == 2)
            $.get("/products/populate_detail_form", {
                id: $(this).val()
            });
        else if (splittedAction.length == 3)
            $.get("/products/populate_detail_form", {
                id: $(this).val(),
                product_id: splittedAction[2]
            });
    });

    $("#product_cost_lists_attributes_0_effective_date").datepicker({
        dateFormat: "dd/mm/yy"
    });

    $('#product_cost_lists_attributes_0_cost').autoNumeric('init');  //autoNumeric with defaults

    if ($("#new_product").length > 0)
        $("#new_product").submit(function () {
            $(".price-effective-date").val($("#product_cost_lists_attributes_0_effective_date").val());
        });
    else if ($(".form-horizontal").length > 0)
        $(".form-horizontal").submit(function () {
            $(".price-effective-date").val($("#product_effective_date").val());
        });
});