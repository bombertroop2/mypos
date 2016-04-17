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
    if ($("#taxable_entrepreneur").length > 0) {
        $(document).keydown(function (e) {
            if (e.keyCode == 116 && e.ctrlKey) {
                $("#taxable_entrepreneur").toggle();
                return false;
            }
        });

        $("#vendor_is_taxable_entrepreneur").click(function () {
            // $this will contain a reference to the checkbox   
            if ($(this).is(':checked')) {
                $("#value_added_tax").show();
            } else {
                $("#value_added_tax").hide();
            }
        });
    }
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
    if ($("#taxable_entrepreneur").length > 0) {
        $(document).keydown(function (e) {
            if (e.keyCode == 116 && e.ctrlKey) {
                $("#taxable_entrepreneur").toggle();
                return false;
            }
        });

        $("#vendor_is_taxable_entrepreneur").click(function () {
            // $this will contain a reference to the checkbox   
            if ($(this).is(':checked')) {
                $("#value_added_tax").show();
            } else {
                $("#value_added_tax").hide();
            }
        });
    }
});
