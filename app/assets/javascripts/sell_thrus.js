$(function () {
    $("#sell_thru_date").datepicker({
        dateFormat: "dd/mm/yy"
    });
    $("#sell_thru_counter").attr("data-placeholder", "Please select").chosen();
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
});

function sortSellThruTable() {
    var table, rows, switching, i, x, y, shouldSwitch;
    table = document.getElementById("sell-thru-table");
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
            x = rows[i].getElementsByTagName("TD")[9];
            y = rows[i + 1].getElementsByTagName("TD")[9];

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

function exportSellThruDataToExcel(filename='')
{
    var downloadurl;
    var fileType = 'application/vnd.ms-excel';
    var tableSelect = document.getElementById("sell-thru-table");
    var dataHTML = tableSelect.outerHTML.replace(/ /g, '%20');
    filename = filename ? filename + '.xls' : 'sell_thru_report.xls';
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

