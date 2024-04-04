function BindState(stateId, selectedVal) {
    $.post('/admin/master/BindStateData', {}, function (result) {
        $("#" + stateId).empty();
        $.each(result, function (i, data) {
            $("#" + stateId).append("<option value='" + data.value + "'> " + data.text + "</option>")
        });

        if (selectedVal != '' && selectedVal != undefined && selectedVal != '0') {
            $("#" + stateId).val(selectedVal); 
        }
    });
}

function BindCity(stateId, CityId) {
    var id = $("#" + stateId).val();
    $.post('/admin/master/BindCityData', { stateId: $("#" + stateId).val(), id: id }, function (result) {
        $("#" + CityId).empty();
        $.each(result, function (i, data) {
            $("#" + CityId).append("<option value='" + data.value + "'> " + data.text + "</option>");
        });
    });
}

function BindCityWithoutId(CityId, selectedVal) {
    $.post('/admin/master/BindCityWithoutId', {}, function (result) {
        $("#" + CityId).empty();
        $.each(result, function (i, data) {
            $("#" + CityId).append("<option value='" + data.value + "'> " + data.text + "</option>")
        });

        if (selectedVal != '' && selectedVal != undefined && selectedVal != '0') {
            $("#" + CityId).val(selectedVal);  
        }

    });
}

function BindHotelData(CityId, HotelId) {
    var id = $("#" + CityId).val();
    $.post('/admin/master/BindHotelMaster', { CityId: $("#" + CityId).val(), id: id }, function (result) {
        $("#" + HotelId).empty();
        $.each(result, function (i, data) {
            $("#" + HotelId).append("<option value='" + data.value + "'> " + data.text + "</option>");
        });
    });
}
