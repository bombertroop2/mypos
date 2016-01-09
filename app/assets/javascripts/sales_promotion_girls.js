$(function () {
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
//        if ($(this).val() == "spg")
//            $('#user_auth').hide();
//        else
//            $('#user_auth').show();
        $('#sales_promotion_girl_user_attributes_spg_role').val($(this).val());
    });

//    if ($('#sales_promotion_girl_role').val() == 'spg' || $('#sales_promotion_girl_role').val() == '')
//        $('#user_auth').hide();
//    else
//        $('#user_auth').show();

    $('#sales_promotion_girl_user_attributes_spg_role').val($('#sales_promotion_girl_role').val());
});

$(document).on('page:load', function () {
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
//        if ($(this).val() == "spg")
//            $('#user_auth').hide();
//        else
//            $('#user_auth').show();
        $('#sales_promotion_girl_user_attributes_spg_role').val($(this).val());
    });

//    if ($('#sales_promotion_girl_role').val() == 'spg' || $('#sales_promotion_girl_role').val() == '')
//        $('#user_auth').hide();
//    else
//        $('#user_auth').show();

    $('#sales_promotion_girl_user_attributes_spg_role').val($('#sales_promotion_girl_role').val());
});
