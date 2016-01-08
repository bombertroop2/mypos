/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */


$(function () {
    $("#product_size_group").change(function () {
        $.get("/products/populate_detail_form", {
            id: $(this).val()
        });
    });
});

// ini untuk turbolink gem
$(document).on('page:load', function() {
    $("#product_size_group").change(function () {
        $.get("/products/populate_detail_form", {
            id: $(this).val()
        });
    });
});