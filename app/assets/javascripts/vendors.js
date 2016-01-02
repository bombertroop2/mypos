$(function () {
    MaskedInput({
        elm: document.getElementById('vendor_phone'),
        format: '____-_______',
        separator: '-'
    });
    MaskedInput({
        elm: document.getElementById('vendor_facsimile'),
        format: '____-_______',
        separator: '-'
    });
    MaskedInput({
        elm: document.getElementById('vendor_pic_phone'),
        format: '____-_______',
        separator: '-'
    });
    MaskedInput({
        elm: document.getElementById('vendor_pic_mobile_phone'),
        format: '____________'
    });
});

$(document).on('page:load', function () {
    MaskedInput({
        elm: document.getElementById('vendor_phone'),
        format: '____-_______',
        separator: '-'
    });
    MaskedInput({
        elm: document.getElementById('vendor_facsimile'),
        format: '____-_______',
        separator: '-'
    });
    MaskedInput({
        elm: document.getElementById('vendor_pic_phone'),
        format: '____-_______',
        separator: '-'
    });
    MaskedInput({
        elm: document.getElementById('vendor_pic_mobile_phone'),
        format: '____________'
    });
});
