$(function () {
    $("#pie_chart_region_cs").attr("data-placeholder", "Please select").chosen("destroy").chosen();
    $("#pie_chart_brand_cs").attr("data-placeholder", "Please select").chosen("destroy").chosen();
    $("#pie_chart_counter_type_cs").attr("data-placeholder", "Please select").chosen("destroy").chosen();
    $("#pie_chart_year_cs").attr("data-placeholder", "Please select").chosen("destroy").chosen();
    //$("#pie_chart_months_cs").chosen("destroy").chosen();
    $("#generate-btn-pie-chart-cs").click(function () {
        if ($("#pie_chart_region_cs").val().trim() == "")
            bootbox.alert({message: "Please select region first!", size: "small"});
        else if ($("#pie_chart_brand_cs").val().trim() == "")
            bootbox.alert({message: "Please select brand first!", size: "small"});
        else if ($("#pie_chart_counter_type_cs").val().trim() == "")
            bootbox.alert({message: "Please select counter type first!", size: "small"});
        else if ($("#pie_chart_year_cs").val().trim() == "")
            bootbox.alert({message: "Please select year first!", size: "small"});
        else {
            $.get("/quantity_sold_charts/index", {
                //months: $.unique($("#pie_chart_months_cs").val()).join(","),
                year: $("#pie_chart_year_cs").val().trim(),
                counter_type: $("#pie_chart_counter_type_cs").val().trim(),
                region: $("#pie_chart_region_cs").val().trim(),
                brand: $("#pie_chart_brand_cs").val().trim()
            });
        }
    });
    Highcharts.setOptions({
        lang: {
            thousandsSep: '.'
        }
    });
});