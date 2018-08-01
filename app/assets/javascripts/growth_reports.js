$(function () {
    //$("#warehouse_id_chosen").addClass("text-left");
    $("#generate-btn").click(function () {
        if ($("#growth_report_month").val().trim() == "")
            bootbox.alert({message: "Please select month first!", size: "small"});
        else if ($("#growth_report_year").val().trim() == "")
            bootbox.alert({message: "Please select year first!", size: "small"});
        else if ($("#growth_report_counter_type").val().trim() == "")
            bootbox.alert({message: "Please select counter type first!", size: "small"});
        else if ($("#growth_report_region").val().trim() == "")
            bootbox.alert({message: "Please select region first!", size: "small"});
        else {
            $.get("/growth_reports/index", {
                month: $("#growth_report_month").val().trim(),
                year: $("#growth_report_year").val().trim(),
                counter_type: $("#growth_report_counter_type").val().trim(),
                region: $("#growth_report_region").val().trim()
            });
        }
    });

    $("#profile-tab").click(function () {
        var mtdTabProcessId = setInterval(function () {
            if ($("#tab_content2").hasClass("active") && $("#tab_content2").hasClass("in")) {
                $("#growth_report_month").attr("data-placeholder", "Please select").chosen("destroy").chosen();
                $("#growth_report_year").attr("data-placeholder", "Please select").chosen("destroy").chosen();
                $("#growth_report_region").attr("data-placeholder", "Please select").chosen("destroy").chosen();
                $("#growth_report_counter_type").attr("data-placeholder", "Please select").chosen("destroy").chosen();
                clearInterval(mtdTabProcessId);
            }
        }, 0);
    });

    $("#profile-tab2").click(function () {
        var ytdTabProcessId = setInterval(function () {
            if ($("#tab_content3").hasClass("active") && $("#tab_content3").hasClass("in")) {
                $("#growth_report_year_year").attr("data-placeholder", "Please select").chosen("destroy").chosen();
                $("#growth_report_region_year").attr("data-placeholder", "Please select").chosen("destroy").chosen();
                $("#growth_report_counter_type_year").attr("data-placeholder", "Please select").chosen("destroy").chosen();
                clearInterval(ytdTabProcessId);
            }
        }, 0);
    });

    $("#growth_report_date").datepicker({
        dateFormat: "dd/mm/yy"
    });

    $("#growth_report_region_daily").attr("data-placeholder", "Please select").chosen("destroy").chosen();
    $("#growth_report_counter_type_daily").attr("data-placeholder", "Please select").chosen("destroy").chosen();

    $("#generate-btn-daily").click(function () {
        if ($("#growth_report_date").val().trim() == "")
            bootbox.alert({message: "Please select date first!", size: "small"});
        else if ($("#growth_report_counter_type_daily").val().trim() == "")
            bootbox.alert({message: "Please select counter type first!", size: "small"});
        else if ($("#growth_report_region_daily").val().trim() == "")
            bootbox.alert({message: "Please select region first!", size: "small"});
        else {
            $.get("/growth_reports/index", {
                date: $("#growth_report_date").val().trim(),
                counter_type: $("#growth_report_counter_type_daily").val().trim(),
                region: $("#growth_report_region_daily").val().trim()
            });
        }
    });

    $("#generate-btn-year").click(function () {
        if ($("#growth_report_year_year").val().trim() == "")
            bootbox.alert({message: "Please select year first!", size: "small"});
        else if ($("#growth_report_counter_type_year").val().trim() == "")
            bootbox.alert({message: "Please select counter type first!", size: "small"});
        else if ($("#growth_report_region_year").val().trim() == "")
            bootbox.alert({message: "Please select region first!", size: "small"});
        else {
            $.get("/growth_reports/index", {
                year: $("#growth_report_year_year").val().trim(),
                counter_type: $("#growth_report_counter_type_year").val().trim(),
                region: $("#growth_report_region_year").val().trim()
            });
        }
    });
});