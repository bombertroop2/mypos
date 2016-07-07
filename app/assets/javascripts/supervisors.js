$(function () {
    MaskedInput({
        elm: document.getElementById('supervisor_phone'),
        format: '____-_______',
        separator: '-'
    });
    MaskedInput({
        elm: document.getElementById('supervisor_mobile_phone'),
        format: '____________'
    });
});

$(document).on('turbolinks:load', function () {
    MaskedInput({
        elm: document.getElementById('supervisor_phone'),
        format: '____-_______',
        separator: '-'
    });
    MaskedInput({
        elm: document.getElementById('supervisor_mobile_phone'),
        format: '____________'
    });
});
