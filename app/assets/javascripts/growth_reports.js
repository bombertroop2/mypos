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

    $("#print-btn-daily").click(function () {
        if ($("#growth_report_date").val().trim() == "")
            bootbox.alert({message: "Please select date first!", size: "small"});
        else if ($("#growth_report_counter_type_daily").val().trim() == "")
            bootbox.alert({message: "Please select counter type first!", size: "small"});
        else if ($("#growth_report_region_daily").val().trim() == "")
            bootbox.alert({message: "Please select region first!", size: "small"});
        else {
            $.get("/growth_reports/print", {
                date: $("#growth_report_date").val().trim(),
                counter_type: $("#growth_report_counter_type_daily").val().trim(),
                region: $("#growth_report_region_daily").val().trim()
            });
        }
    });

    $("#export-btn-daily").click(function () {
        if ($("#growth_report_date").val().trim() == "") {
            bootbox.alert({message: "Please select date first!", size: "small"});
            return false;
        } else if ($("#growth_report_counter_type_daily").val().trim() == "") {
            bootbox.alert({message: "Please select counter type first!", size: "small"});
            return false;
        } else if ($("#growth_report_region_daily").val().trim() == "") {
            bootbox.alert({message: "Please select region first!", size: "small"});
            return false;
        } else {
            $($(this).parent()).children('input[name="date"]').val($("#growth_report_date").val().trim());
            $($(this).parent()).children('input[name="counter_type"]').val($("#growth_report_counter_type_daily").val().trim());
            $($(this).parent()).children('input[name="region"]').val($("#growth_report_region_daily").val().trim());
        }
    });

    $("#print-btn-month").click(function () {
        if ($("#growth_report_month").val().trim() == "")
            bootbox.alert({message: "Please select month first!", size: "small"});
        else if ($("#growth_report_year").val().trim() == "")
            bootbox.alert({message: "Please select year first!", size: "small"});
        else if ($("#growth_report_counter_type").val().trim() == "")
            bootbox.alert({message: "Please select counter type first!", size: "small"});
        else if ($("#growth_report_region").val().trim() == "")
            bootbox.alert({message: "Please select region first!", size: "small"});
        else {
            $.get("/growth_reports/print", {
                month: $("#growth_report_month").val().trim(),
                year: $("#growth_report_year").val().trim(),
                counter_type: $("#growth_report_counter_type").val().trim(),
                region: $("#growth_report_region").val().trim()
            });
        }
    });

    $("#export-btn-month").click(function () {
        if ($("#growth_report_month").val().trim() == "") {
            bootbox.alert({message: "Please select month first!", size: "small"});
            return false;
        } else if ($("#growth_report_year").val().trim() == "") {
            bootbox.alert({message: "Please select year first!", size: "small"});
            return false;
        } else if ($("#growth_report_counter_type").val().trim() == "") {
            bootbox.alert({message: "Please select counter type first!", size: "small"});
            return false;
        } else if ($("#growth_report_region").val().trim() == "") {
            bootbox.alert({message: "Please select region first!", size: "small"});
            return false;
        } else {
            $($(this).parent()).children('input[name="year"]').val($("#growth_report_year").val().trim());
            $($(this).parent()).children('input[name="counter_type"]').val($("#growth_report_counter_type").val().trim());
            $($(this).parent()).children('input[name="region"]').val($("#growth_report_region").val().trim());
            $($(this).parent()).children('input[name="month"]').val($("#growth_report_month").val().trim());
        }
    });

    $("#print-btn-year").click(function () {
        if ($("#growth_report_year_year").val().trim() == "")
            bootbox.alert({message: "Please select year first!", size: "small"});
        else if ($("#growth_report_counter_type_year").val().trim() == "")
            bootbox.alert({message: "Please select counter type first!", size: "small"});
        else if ($("#growth_report_region_year").val().trim() == "")
            bootbox.alert({message: "Please select region first!", size: "small"});
        else {
            $.get("/growth_reports/print", {
                year: $("#growth_report_year_year").val().trim(),
                counter_type: $("#growth_report_counter_type_year").val().trim(),
                region: $("#growth_report_region_year").val().trim()
            });
        }
    });

    $("#print-btn-custom-range").click(function () {
        if ($("#growth_report_date_range").val().trim() == "")
            bootbox.alert({message: "Please select date range first!", size: "small"});
        else if ($("#growth_report_counter_type_custom_range").val().trim() == "")
            bootbox.alert({message: "Please select counter type first!", size: "small"});
        else if ($("#growth_report_region_custom_range").val().trim() == "")
            bootbox.alert({message: "Please select region first!", size: "small"});
        else {
            var splittedDateRange = $("#growth_report_date_range").val().trim().split("-");
            var beginningYear = splittedDateRange[0].trim().split("/")[2];
            var endYear = splittedDateRange[1].trim().split("/")[2];
            if (beginningYear != endYear)
                bootbox.alert({message: "Please select date range in the same year!", size: "small"});
            else {
                $.get("/growth_reports/print", {
                    date_range: $("#growth_report_date_range").val().trim(),
                    counter_type: $("#growth_report_counter_type_custom_range").val().trim(),
                    region: $("#growth_report_region_custom_range").val().trim()
                });
            }
        }
    });

    $("#export-btn-year").click(function () {
        if ($("#growth_report_year_year").val().trim() == "") {
            bootbox.alert({message: "Please select year first!", size: "small"});
            return false;
        } else if ($("#growth_report_counter_type_year").val().trim() == "") {
            bootbox.alert({message: "Please select counter type first!", size: "small"});
            return false;
        } else if ($("#growth_report_region_year").val().trim() == "") {
            bootbox.alert({message: "Please select region first!", size: "small"});
            return false;
        } else {
            $($(this).parent()).children('input[name="year"]').val($("#growth_report_year_year").val().trim());
            $($(this).parent()).children('input[name="counter_type"]').val($("#growth_report_counter_type_year").val().trim());
            $($(this).parent()).children('input[name="region"]').val($("#growth_report_region_year").val().trim());
        }
    });

    $("#export-btn-custom-range").click(function () {
        if ($("#growth_report_date_range").val().trim() == "") {
            bootbox.alert({message: "Please select date range first!", size: "small"});
            return false;
        } else if ($("#growth_report_counter_type_custom_range").val().trim() == "") {
            bootbox.alert({message: "Please select counter type first!", size: "small"});
            return false;
        } else if ($("#growth_report_region_custom_range").val().trim() == "") {
            bootbox.alert({message: "Please select region first!", size: "small"});
            return false;
        } else {
            var splittedDateRange = $("#growth_report_date_range").val().trim().split("-");
            var beginningYear = splittedDateRange[0].trim().split("/")[2];
            var endYear = splittedDateRange[1].trim().split("/")[2];
            if (beginningYear != endYear) {
                bootbox.alert({message: "Please select date range in the same year!", size: "small"});
                return false;
            } else {
                $($(this).parent()).children('input[name="date_range"]').val($("#growth_report_date_range").val().trim());
                $($(this).parent()).children('input[name="counter_type"]').val($("#growth_report_counter_type_custom_range").val().trim());
                $($(this).parent()).children('input[name="region"]').val($("#growth_report_region_custom_range").val().trim());
            }
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

    $("#profile-tab3").click(function () {
        var ytdTabProcessId = setInterval(function () {
            if ($("#tab_content4").hasClass("active") && $("#tab_content4").hasClass("in")) {
                $("#growth_report_region_custom_range").attr("data-placeholder", "Please select").chosen("destroy").chosen();
                $("#growth_report_counter_type_custom_range").attr("data-placeholder", "Please select").chosen("destroy").chosen();
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

    $("#generate-btn-custom-range").click(function () {
        if ($("#growth_report_date_range").val().trim() == "")
            bootbox.alert({message: "Please select date range first!", size: "small"});
        else if ($("#growth_report_counter_type_custom_range").val().trim() == "")
            bootbox.alert({message: "Please select counter type first!", size: "small"});
        else if ($("#growth_report_region_custom_range").val().trim() == "")
            bootbox.alert({message: "Please select region first!", size: "small"});
        else {
            var splittedDateRange = $("#growth_report_date_range").val().trim().split("-");
            var beginningYear = splittedDateRange[0].trim().split("/")[2];
            var endYear = splittedDateRange[1].trim().split("/")[2];
            if (beginningYear != endYear)
                bootbox.alert({message: "Please select date range in the same year!", size: "small"});
            else {
                $.get("/growth_reports/index", {
                    date_range: $("#growth_report_date_range").val().trim(),
                    counter_type: $("#growth_report_counter_type_custom_range").val().trim(),
                    region: $("#growth_report_region_custom_range").val().trim()
                });
            }
        }
    });

    $('#growth_report_date_range').daterangepicker(
            {
                locale: {
                    format: 'DD/MM/YYYY'
                },
                opens: "right",
                autoUpdateInput: false
            });
    $('#growth_report_date_range').on('apply.daterangepicker', function (ev, picker) {
        $(this).val(picker.startDate.format('DD/MM/YYYY') + ' - ' + picker.endDate.format('DD/MM/YYYY'));
    });

    $('#growth_report_date_range').on('cancel.daterangepicker', function (ev, picker) {
        $(this).val('');
    });

});
