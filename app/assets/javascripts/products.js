/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

/*
 $(function () {
 $("#product_size_group_id").change(function () {
 // split isi dari action attributnya form untuk ambil id produk
 var splittedAction = $(".form-horizontal").attr("action").split("/");
 if (splittedAction.length == 2)
 $.get("/products/populate_detail_form", {
 id: $(this).val()
 });
 else if (splittedAction.length == 3)
 $.get("/products/populate_detail_form", {
 id: $(this).val(),
 product_id: splittedAction[2]
 });
 });
 
 $("#product_cost_lists_attributes_0_effective_date").datepicker({
 dateFormat: "dd/mm/yy"
 });
 
 $('#product_cost_lists_attributes_0_cost').autoNumeric('init');  //autoNumeric with defaults
 
 if ($("#new_product").length > 0)
 $("#new_product").submit(function () {
 $(".price-effective-date").val($("#product_cost_lists_attributes_0_effective_date").val());
 });
 else if ($(".form-horizontal").length > 0)
 $(".form-horizontal").submit(function () {
 $(".price-effective-date").val($("#product_effective_date").val());
 });
 
 });
 */
// ini untuk turbolink gem
$(document).on('turbolinks:load', function () {
    $("#product_size_group_id").change(function () {
        // split isi dari action attributnya form untuk ambil id produk
        var splittedAction = $(".form-horizontal").attr("action").split("/");
        if (splittedAction.length == 2)
            $.get("/products/populate_detail_form", {
                id: $(this).val()
            });
        else if (splittedAction.length == 3)
            $.get("/products/populate_detail_form", {
                id: $(this).val(),
                product_id: splittedAction[2]
            });
    });

    $("#product_cost_lists_attributes_0_effective_date").datepicker({
        dateFormat: "dd/mm/yy"
    });

    $('#product_cost_lists_attributes_0_cost').autoNumeric('init');  //autoNumeric with defaults

    if ($("#new_product").length > 0)
        $("#new_product").submit(function () {
            $(".price-effective-date").val($("#product_cost_lists_attributes_0_effective_date").val());
        });
    else if ($(".form-horizontal").length > 0)
        $(".form-horizontal").submit(function () {
            $(".price-effective-date").val($("#product_effective_date").val());
        });

    var productColorDataTable = $('#listing_product_colors_table').DataTable({
        order: [1, 'asc'],
        dom: 'T<"clear">lfrtip',
        columns: [
            {data: null, defaultContent: '', orderable: false},
            {data: 'code'},
            {data: 'name'}
        ],
        tableTools: {
            sRowSelect: 'os',
            sRowSelector: 'td:first-child',
            aButtons: ['select_all', 'select_none']
        },
        paging: false,
        info: false,
        scrollY: "250px",
        scrollCollapse: true
    });

    $("#submit_product").click(function () {
        $(".selected-colors").val("");
        $(".color-delete-marker").val("true");
        $.each(productColorDataTable.rows('.selected')[0], function (index, value) {
            var colorId = productColorDataTable.rows(value).nodes().to$().attr("id").split("_")[2];
            $("#selected_color_id_" + colorId).val(colorId);
            $("#color_delete_marker_" + colorId).val("false");
        });

    });

    var selectedColorFields = $(".selected-colors");
    $.each(selectedColorFields, function (index, value) {
        var selectedColorId = $($(".selected-colors")[index]).val();
        if (selectedColorId != "") {
            var e = jQuery.Event("click");
            e.ctrlKey = true;
            $("#product_color_" + selectedColorId).find("td:first-child").trigger(e);
        }
    });
});