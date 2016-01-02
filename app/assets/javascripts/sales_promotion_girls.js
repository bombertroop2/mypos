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
});
