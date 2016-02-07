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

    $("#product_effective_date").datepicker({
        dateFormat:"dd/mm/yy"
    });
});

// ini untuk turbolink gem
$(document).on('page:load', function () {
    $("#product_size_group_id").change(function () {
        $.get("/products/populate_detail_form", {
            id: $(this).val()
        });
    });
    
    $("#product_effective_date").datepicker({
        dateFormat:"dd/mm/yy"
    });
});