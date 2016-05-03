/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */


$(function () {
    $("#product_size_group_id").change(function () {
        $.get("/products/populate_detail_form", {
            id: $(this).val()
        });
    });

    $("#product_cost_lists_attributes_0_effective_date").datepicker({
        dateFormat: "dd/mm/yy"
    });

    $('#product_cost_lists_attributes_0_cost').autoNumeric('init');  //autoNumeric with defaults

    $("#new_product").submit(function () {
        $(".price-effective-date").val($("#product_cost_lists_attributes_0_effective_date").val());
    });
});

// ini untuk turbolink gem
$(document).on('page:load', function () {
    $("#product_size_group_id").change(function () {
        $.get("/products/populate_detail_form", {
            id: $(this).val()
        });
    });

    $("#product_cost_lists_attributes_0_effective_date").datepicker({
        dateFormat: "dd/mm/yy"
    });

    $('#product_cost_lists_attributes_0_cost').autoNumeric('init');  //autoNumeric with defaults

    $("#new_product").submit(function () {
        $(".price-effective-date").val($("#product_cost_lists_attributes_0_effective_date").val());
    });
});