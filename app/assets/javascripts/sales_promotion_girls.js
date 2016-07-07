//$(function () {
//    MaskedInput({
//        elm: document.getElementById('sales_promotion_girl_phone'),
//        format: '____-_______',
//        separator: '-'
//    });
//    MaskedInput({
//        elm: document.getElementById('sales_promotion_girl_mobile_phone'),
//        format: '____________'
//    });
//    $('#sales_promotion_girl_role').change(function () {
//        $('#sales_promotion_girl_user_attributes_spg_role').val($(this).val());
//    });
//
//    $('#sales_promotion_girl_user_attributes_spg_role').val($('#sales_promotion_girl_role').val());
//
//});

$(document).on('turbolinks:load', function () {
    MaskedInput({
        elm: document.getElementById('sales_promotion_girl_phone'),
        format: '____-_______',
        separator: '-'
    });
    MaskedInput({
        elm: document.getElementById('sales_promotion_girl_mobile_phone'),
        format: '____________'
    });
    $('#sales_promotion_girl_role').change(function () {
        $('#sales_promotion_girl_user_attributes_spg_role').val($(this).val());
    });


    $('#sales_promotion_girl_user_attributes_spg_role').val($('#sales_promotion_girl_role').val());

});
