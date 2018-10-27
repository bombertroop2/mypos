var submitForm = false;
$(function () {
    $("#import_date").datepicker({
        dateFormat: "dd/mm/yy"
    });


    $("#import_beginning_stocks_form").submit(function () {
        if (submitForm) {
            submitForm = false;
            return true;
        } else {
            bootbox.confirm({
                message: "Please double check all of the data before you import beginning stock, make sure everything is correct.<br>Once you import beginning stock, you'll not be able to edit or cancel it<br>Are you ABSOLUTELY sure?",
                buttons: {
                    confirm: {
                        label: '<i class="fa fa-check"></i> Confirm'
                    },
                    cancel: {
                        label: '<i class="fa fa-times"></i> Cancel'
                    }
                },
                callback: function (result) {
                    if (result) {
                        $("body").css('padding-right', '0px');
                        submitForm = true;
                        $("#import_beginning_stocks_form").submit();
                    }
                },
                size: "small"
            });
            return false;
        }
    });
});