$(function () {
    $("#total_size_btn").click(function () {
        var totalSize = $("#total_size").val();
        if (!isNaN(totalSize)) {
            var totalSizeInt = parseInt(totalSize);
            if (totalSizeInt > 0) {
                $(".nested-fields").remove();
                for (var i = 0; i < totalSizeInt; i++)
                    $(".add_fields").click();
            }
        }
        return false;
    });
});

$(document).on('page:load', function () {
    $("#total_size_btn").click(function () {
        var totalSize = $("#total_size").val();
        if (!isNaN(totalSize)) {
            var totalSizeInt = parseInt(totalSize);
            if (totalSizeInt > 0) {
                $(".nested-fields").remove();
                for (var i = 0; i < totalSizeInt; i++)
                    $(".add_fields").click();
            }
        }
        return false;
    });
});