function getAreaManagerWarehouses(amId, amName) {
    $.get("/area_managers/" + amId + "/get_warehouses").done(function (data) {
        bootbox.alert({
            title: "Area Manager: " + amName,
            message: data
        });
    });
}