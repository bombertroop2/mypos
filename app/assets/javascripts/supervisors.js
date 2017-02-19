function getAreaManagerWarehouses(amId, amName) {
    $.get("/area_managers/" + amId + "/get_warehouses").done(function (data) {
        bootbox.alert({
            title: "Warehouses managed by " + amName,
            message: data
        });
    });
}