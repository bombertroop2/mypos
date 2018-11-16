$(function () {
    $("#sell_thru_date").datepicker({
        dateFormat: "dd/mm/yy"
    });
    $("#sell_thru_date_showroom").datepicker({
        dateFormat: "dd/mm/yy"
    });
    $("#sell_thru_date_central_counter").datepicker({
        dateFormat: "dd/mm/yy"
    });
    $("#sell_thru_date_central_showroom").datepicker({
        dateFormat: "dd/mm/yy"
    });
    $("#sell_thru_counter").attr("data-placeholder", "Please select").chosen();
    $("#sell_thru_showroom").attr("data-placeholder", "Please select").chosen({width: "200px"});
    //$("#sell_thru_central_counter").attr("data-placeholder", "Please select").chosen({width: "200px"});
    $("#generate-btn-sell-thru-report").click(function () {
        if ($("#sell_thru_counter").val().trim() == "")
            bootbox.alert({message: "Please select counter first!", size: "small"});
        else if ($("#sell_thru_date").val().trim() == "")
            bootbox.alert({message: "Please select date first!", size: "small"});
        else {
            $.get("/sell_thru", {
                date: $("#sell_thru_date").val().trim(),
                counter: $("#sell_thru_counter").val().trim()
            });
        }
    });
    $("#export-btn-sell-thru-report").click(function () {
        if ($("#sell_thru_counter").val().trim() == "")
            bootbox.alert({message: "Please select counter first!", size: "small"});
        else if ($("#sell_thru_date").val().trim() == "")
            bootbox.alert({message: "Please select date first!", size: "small"});
        else {
            $.get("/sell_thru", {
                date: $("#sell_thru_date").val().trim(),
                counter: $("#sell_thru_counter").val().trim(),
                export: true
            });
        }
    });
    $("#generate-btn-sell-thru-report-showroom").click(function () {
        if ($("#sell_thru_showroom").val().trim() == "")
            bootbox.alert({message: "Please select showroom first!", size: "small"});
        else if ($("#sell_thru_date_showroom").val().trim() == "")
            bootbox.alert({message: "Please select date first!", size: "small"});
        else {
            $.get("/sell_thru", {
                date: $("#sell_thru_date_showroom").val().trim(),
                showroom: $("#sell_thru_showroom").val().trim(),
                type: "showroom"
            });
        }
    });
    $("#export-btn-sell-thru-report-showroom").click(function () {
        if ($("#sell_thru_showroom").val().trim() == "")
            bootbox.alert({message: "Please select showroom first!", size: "small"});
        else if ($("#sell_thru_date_showroom").val().trim() == "")
            bootbox.alert({message: "Please select date first!", size: "small"});
        else {
            $.get("/sell_thru", {
                date: $("#sell_thru_date_showroom").val().trim(),
                showroom: $("#sell_thru_showroom").val().trim(),
                export: true,
                type: "showroom"
            });
        }
    });
    $("#generate-btn-sell-thru-report-central-counter").click(function () {
        /*if ($("#sell_thru_central_counter").val().trim() == "")
         bootbox.alert({message: "Please select warehouse first!", size: "small"});
         else */if ($("#sell_thru_date_central_counter").val().trim() == "")
            bootbox.alert({message: "Please select date first!", size: "small"});
        else {
            $.get("/sell_thru", {
                date: $("#sell_thru_date_central_counter").val().trim(),
                type: "central counter"
                        //warehouse: $("#sell_thru_central_counter").val().trim()
            });
        }
    });
    $("#export-btn-sell-thru-report-central-counter").click(function () {
        /*if ($("#sell_thru_central_counter").val().trim() == "")
         bootbox.alert({message: "Please select warehouse first!", size: "small"});
         else */if ($("#sell_thru_date_central_counter").val().trim() == "")
            bootbox.alert({message: "Please select date first!", size: "small"});
        else {
            $.get("/sell_thru", {
                date: $("#sell_thru_date_central_counter").val().trim(),
                //showroom: $("#sell_thru_central_counter").val().trim(),
                type: "central counter",
                export: true
            });
        }
    });
    $("#generate-btn-sell-thru-report-central-showroom").click(function () {
        if ($("#sell_thru_date_central_showroom").val().trim() == "")
            bootbox.alert({message: "Please select date first!", size: "small"});
        else {
            $.get("/sell_thru", {
                date: $("#sell_thru_date_central_showroom").val().trim(),
                type: "central showroom"
            });
        }
    });
    $("#export-btn-sell-thru-report-central-showroom").click(function () {
        if ($("#sell_thru_date_central_showroom").val().trim() == "")
            bootbox.alert({message: "Please select date first!", size: "small"});
        else {
            $.get("/sell_thru", {
                date: $("#sell_thru_date_central_showroom").val().trim(),
                type: "central showroom",
                export: true
            });
        }
    });
});

function sortSellThruTable(tableId) {
    var table, rows, switching, i, x, y, shouldSwitch;
    table = document.getElementById(tableId);
    switching = true;
    /* Make a loop that will continue until
     no switching has been done: */
    while (switching) {
        // Start by saying: no switching is done:
        switching = false;
        rows = table.rows;
        /* Loop through all table rows (except the
         first, which contains table headers): */
        for (i = 2; i < (rows.length - 1); i++) {
            // Start by saying there should be no switching:
            shouldSwitch = false;
            /* Get the two elements you want to compare,
             one from current row and one from the next: */
            x = rows[i].getElementsByTagName("TD")[10];
            y = rows[i + 1].getElementsByTagName("TD")[10];

            var firstPercentage = parseFloat(x.innerHTML.toLowerCase().trim().split("%")[0]);
            var secondPercentage = parseFloat(y.innerHTML.toLowerCase().trim().split("%")[0]);

            // Check if the two rows should switch place:
            if (firstPercentage > secondPercentage) {
                // If so, mark as a switch and break the loop:
                shouldSwitch = true;
                break;
            }
        }
        if (shouldSwitch) {
            /* If a switch has been marked, make the switch
             and mark that a switch has been done: */
            rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
            switching = true;
        }
    }
}

function exportSellThruDataToExcel(filename, tableId)
{
    var downloadurl;
    var fileType = 'application/vnd.ms-excel';
    var tableSelect = document.getElementById(tableId);
    var dataHTML = tableSelect.outerHTML.replace(/ /g, '%20');
    filename = filename + '.xls';
    downloadurl = document.createElement("a");
    document.body.appendChild(downloadurl);
    if (navigator.msSaveOrOpenBlob)
    {
        var blob = new Blob(['\ufeff', dataHTML],
                {
                    type: fileType
                });
        navigator.msSaveOrOpenBlob(blob, filename);
    } else
    {
        downloadurl.href = 'data:' + fileType + ', ' + dataHTML;
        downloadurl.download = filename;
        downloadurl.click();
    }
}

