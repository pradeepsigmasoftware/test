
function currTime() {
    var now = new Date();
    var pretty = [
        now.getHours()
    ].join('');
    return pretty;
}
var curTime = currTime();
function getToday(datecheckin) {
    if (datecheckin == undefined) {
        var d = new Date();
        var m = d.getMonth(); // 0 - 11
        var y = d.getFullYear();
        if (curTime >= 0 && curTime <= 7) {
            return Date.UTC(d.getFullYear(), d.getMonth(), d.getDate() - 1);
        }
        else {
            return Date.UTC(d.getFullYear(), d.getMonth(), d.getDate());
        }
    }
    else {
        var d = new Date(datecheckin);
        var m = d.getMonth(); // 0 - 11
        var y = d.getFullYear();
        return Date.UTC(d.getFullYear(), d.getMonth(), d.getDate());
    }
}
function getnextDay(datecheckout) {
    if (datecheckout == undefined) {
        var d = new Date();
        var m = d.getMonth(); // 0 - 11
        var y = d.getFullYear();
        if (curTime >= 0 && curTime <= 7) {
            return Date.UTC(d.getFullYear(), d.getMonth(), d.getDate());
        }
        else {
            return Date.UTC(d.getFullYear(), d.getMonth(), d.getDate() + 1);
        }
    }
    else {
        var d = new Date(datecheckout);
        var m = d.getMonth(); // 0 - 11
        var y = d.getFullYear();
        return Date.UTC(d.getFullYear(), d.getMonth());
    }

}

function currTime() {
    var now = new Date();
    var pretty = [
        now.getHours()
    ].join('');
    return pretty;
}
var curTime = currTime();
function getToday(datecheckin) {
    if (datecheckin == undefined) {
        var d = new Date();
        var m = d.getMonth(); // 0 - 11
        var y = d.getFullYear();
        if (curTime >= 0 && curTime <= 7) {
            return Date.UTC(d.getFullYear(), d.getMonth(), d.getDate() - 1);
        }
        else {
            return Date.UTC(d.getFullYear(), d.getMonth(), d.getDate());
        }
    }
    else {
        var d = new Date(datecheckin);
        var m = d.getMonth(); // 0 - 11
        var y = d.getFullYear();
        return Date.UTC(d.getFullYear(), d.getMonth(), d.getDate());
    }
}
function getnextDay(datecheckout) {
    if (datecheckout == undefined) {
        var d = new Date();
        var m = d.getMonth(); // 0 - 11
        var y = d.getFullYear();
        if (curTime >= 0 && curTime <= 7) {
            return Date.UTC(d.getFullYear(), d.getMonth(), d.getDate());
        }
        else {
            return Date.UTC(d.getFullYear(), d.getMonth(), d.getDate() + 1);
        }
    }
    else {
        var d = new Date(datecheckout);
        var m = d.getMonth(); // 0 - 11
        var y = d.getFullYear();
        return Date.UTC(d.getFullYear(), d.getMonth());
    }

}

var d = new Date();
var m = d.getMonth(); // 0 - 11
var y = d.getFullYear();
var toDay = Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()); // UTC
var nextDay = Date.UTC(d.getFullYear(), d.getMonth(), d.getDate() + 1);
function getToday1() {
    debugger;
    var dt = new Date();
    var now = new Date(Date.now());
    var formatted = now.getHours() + ":" + now.getMinutes() + ":" + now.getSeconds();

    var st = '00:00:01';
    var et = '05:59:59';
    if (timeToSeconds(formatted) >= timeToSeconds(st) && timeToSeconds(formatted) <= timeToSeconds(et)) {

        return Date.UTC(d.getFullYear(), d.getMonth(), d.getDate() - 1);
    }
    else {

        return Date.UTC(d.getFullYear(), d.getMonth(), d.getDate());
    }
    //  return Date.UTC(d.getFullYear(), d.getMonth(), d.getDate());
}
function timeToSeconds(time) {
    time = time.split(/:/);
    return time[0] * 3600 + time[1] * 60 + time[2];
}

$(document).ready(function () {
    debugger;
    var table = document.getElementById('tbl1');

    var rowLength = table.rows.length;

    for (var i = 0; i < rowLength; i += 1) {
        $('#t-datepicker-' + i).tDatePicker({
            autoClose: true,
            limitNextMonth: 12,
            numCalendar: 2,
            dateCheckIn: getToday1(),
            dateCheckOut: getnextDay(),
            startDate: getToday(),
        }).on('onChangeCO', function (e, changeDateCO) {
            debugger;
            var aa = new Date($("#t-datepicker-" + $.trim($(this).attr('Serialnb')) + " .t-input-check-in").val());
            var d = new Date(changeDateCO);
            var m = d.getMonth(); // 0 - 11
            var y = d.getFullYear();

            var cm = aa.getMonth();
            var cy = aa.getFullYear();

            var checkinDate = aa.getFullYear() + '-' + (aa.getMonth() + 1) + '-' + aa.getDate();

            var CheckoutDate = d.getFullYear() + '-' + (d.getMonth() + 1) + '-' + d.getDate();

            var CategoryId = $.trim($(this).attr('categoryid'));
            var serialnb = $.trim($(this).attr('serialnb'));

            UpdateRoomDetails(CategoryId, checkinDate, CheckoutDate, serialnb)

        }).on('onChangeCI', function (e, changeDateCI) {
            debugger;
            var aa = new Date($("#t-datepicker-" + $.trim($(this).attr('Serialnb')) + " .t-input-check-out").val());
            var d = new Date(changeDateCI);
            var m = d.getMonth(); // 0 - 11
            var y = d.getFullYear();

            var cm = aa.getMonth();
            var cy = aa.getFullYear();

            var date = d.getFullYear() + '-' + (d.getMonth() + 1) + '-' + (d.getDate());
            var tempStartDate = new Date(date);
            var default_end = new Date(tempStartDate.getFullYear(), tempStartDate.getMonth(), tempStartDate.getDate() + 1);

            var checkinDate = d.getFullYear() + '-' + (d.getMonth() + 1) + '-' + d.getDate()

            var CheckoutDate = aa.getFullYear() + '-' + (aa.getMonth() + 1) + '-' + aa.getDate();

            var CategoryId = $.trim($(this).attr('categoryid'));
            var serialnb = $.trim($(this).attr('serialnb'));

            UpdateRoomDetails(CategoryId, checkinDate, CheckoutDate, serialnb)

        });
    }

})

function UpdateRoomDetails(categoryId, checkinDate, CheckoutDate, serialnb) {

    $('#ddlRoom-' + serialnb).html('<option value=0>0</option>');
    $('#ddlPerson-' + serialnb).html('<option value=0>0</option>');

    var Request = {
        CategoryId: categoryId,
        CheckInDate: checkinDate,
        CheckOutDate: CheckoutDate

    }



    $.post('/Unit/Booking/GetRoomBooking', Request, function (Res) {

        var Res = eval(Res);

        if (Res != undefined && Res.length > 0) {

            var Cobj = Res[0];

            $('#ddlRoom-' + serialnb).html(MakeOption(Cobj.AvailableRoom));
            $('#ddlPerson-' + serialnb).html(MakeOption(Cobj.noofBed + 1));

            $('#row_' + serialnb).attr('doublebedcharge', Cobj.PriceDifference);
            $('#row_' + serialnb).attr('extrabedper', Cobj.ExtraBedPercentage);
            $('#row_' + serialnb).attr('extrabedprice', Cobj.ExtraBedAmt);

            $('#spn1-' + serialnb).text(Cobj.PricePerDay);
            $('#spn2-' + serialnb).text(Cobj.DoubleOccupancy);


            FincalCalculation();
        }

    })


}
function MakeOption(Num) {
    var option = '';
    for (var i = 0; i <= Num; i++) {
        option += '<option value="' + i + '">' + i + '</option>';
    }
    return option;
}


function RoomOnChange(Sno) {
    // $('#ddlRoom-' + Sno).html('<option value=0>0</option>');

    var noofbed = parseInt($('#row_' + Sno).attr('noofbed') || 0);
    var noofRoom = parseInt($('#ddlRoom-' + Sno).val() || 0);

    var NoofPerson = (noofbed * noofRoom) + noofRoom;

    $('#ddlPerson-' + Sno).html(MakeOption(NoofPerson));

    $('#ddlPerson-' + Sno).val(noofRoom)

    FincalCalculation();
}
function PersonOnChange(Sno) {
    FincalCalculation();
}


function FincalCalculation() {
    debugger

    $('#mainCalculation').html('');

    var GSTPer = 12;
    var GstNature = $('input.chkgst:checked').val();

   

    var DiscountPer = parseFloat($('#txtDiscount').val() || 0);

 

    var FinalAmount = 0;
    var FinalGST = 0;
    var DiscountableAmt = 0;
    var FinalPayable = 0;
    $('#tbl1 tbody tr').each(function () {
        debugger;
        var sno = $(this).attr('indexnew');


        var startDay = new Date($("#t-datepicker-" + sno + " .t-input-check-in").val());
        var endDay = new Date($("#t-datepicker-" + sno + " .t-input-check-out").val());

        var millisecondsPerDay = 1000 * 60 * 60 * 24;

        var millisBetween = endDay.getTime() - startDay.getTime();
        var days = millisBetween / millisecondsPerDay;






        var Noofrooms = parseInt($('#ddlRoom-' + sno).val() || 0);
        var NoofPerson = parseInt($('#ddlPerson-' + sno).val() || 0);






        if (Noofrooms === 0) {
            return; // Use return instead of continue to exit the current iteration
        }

        var noofbed = parseInt($(this).attr('noofbed') || 0);
        var roomcharge = parseFloat($(this).attr('roomcharge') || 0);
        var doublebedcharge = parseFloat($(this).attr('doublebedcharge') || 0);
        var extrabedper = parseFloat($(this).attr('extrabedper') || 0);
        var extrabedprice = parseFloat($(this).attr('extrabedprice') || 0);
        var categoryId = parseInt($(this).attr('categoryId') || 0);



        var TotalRoomCharge = Noofrooms * roomcharge * days;

        //Calculate Double Bed
        var DoubleBedAmt = 0;
        var DoubleBedPerson = 0;
        if (NoofPerson > Noofrooms) {
            DoubleBedPerson = NoofPerson - Noofrooms;
            if (DoubleBedPerson > Noofrooms) {
                DoubleBedPerson = Noofrooms;
            }
            DoubleBedAmt = DoubleBedPerson * doublebedcharge * days;
        }

        //Calculate Extra bed
        var ExtrabedAmt = 0;
        var ExtraPerson = 0;
        if (NoofPerson > (Noofrooms * noofbed)) {
            ExtraPerson = NoofPerson - (Noofrooms * noofbed);
            ExtrabedAmt = ExtraPerson * extrabedprice * days;
        }


        var FinalAmt = (TotalRoomCharge + DoubleBedAmt + ExtrabedAmt);

        DiscountableAmt = DiscountableAmt + TotalRoomCharge + DoubleBedAmt;

        var html = '<div class="col-sm-12 charges3" id="paymentdiv_' + sno + '">';
        html += '<div class="col-sm-4">';
        html += '<span>' + Noofrooms + ' AC Deluxe &nbsp;';
        html += '<span>' + NoofPerson + ' Persons </span>';
        html += '<a href="#" onclick="DeleteCategoryBooking(' + sno + ')">';
        html += '<i class="fa fa-close" style="color: white;background: red;padding: 3px 5px;border-radius: 25px;font-weight: 700;"></i>';
        html += '</a>';
        if (ExtrabedAmt > 0) {
            html += '<span style="font-size:12px;color:#c3000b;">Includes extra bed charge &nbsp;<i class="fa fa-rupee"></i>&nbsp;' + ExtrabedAmt + '</span>';
        }

        html += '</span>';
        html += '</div>';
        html += '<div class="col-sm-6">';
        //html += '<input type="text" class="customizerate" oninput="this.value = this.value.replace(/[^0-9.]/g, "")" value="' + roomcharge +'" />';
        //html += '<input type="text" class="customizerate" oninput="this.value = this.value.replace(/[^0-9.]/g, "")" value="' + doublebedcharge +'" />';
        //html += '<input type="text" class="customizerate" oninput="this.value = this.value.replace(/[^0-9.]/g, "")" value="' + extrabedprice +'" />';
        html += '</div>';
        html += '<div class="col-sm-2">';
        html += '<span class="pull-right text-right CWtotalRoomcharge">' + FinalAmt + '</span>';
        html += '</div>';
        html += '</div>';



        $('#cat_RoomCharge_' + sno).text(TotalRoomCharge + DoubleBedAmt);
        $('#cat_ExtraCharge_' + sno).text(ExtrabedAmt);
        $('#cat_TotalCharge_' + sno).text(FinalAmt);



        FinalAmount = FinalAmount + FinalAmt;


        $('#mainCalculation').append(html);
    })


   var DiscountAmt =  (DiscountableAmt * DiscountPer / 100);

    var taxableAmt = FinalAmount - DiscountAmt;

    if (GstNature == 'Exclude') {
        FinalGST = (taxableAmt * GSTPer / 100);
        FinalAmount = FinalAmount + FinalGST;
    }
    else {
        FinalGST = taxableAmt * GSTPer / (100 + GSTPer);
    }

    FinalPayable = FinalAmount - DiscountAmt;

    if (FinalAmount > 0) {
        $('#FinalCalculation').show();

        $('#lblFinalAmtPayable').text(FinalAmount.toFixed());
        $('#lblFinalgst').text(FinalGST.toFixed());
               
        $('#txtDiscountAmt').text(DiscountAmt.toFixed());
        $('#txtFinalPayable').text(FinalPayable.toFixed());
    }
    else {
        $('#FinalCalculation').hide();

        $('#lblFinalAmtPayable').text(0);
        $('#lblFinalgst').text(0);
        $('#lblFinalgst').text(0);
        $('#txtDiscountAmt').text(0);
        $('#txtFinalPayable').text(0);

    }
}

function DeleteCategoryBooking(sno) {
    $('#ddlRoom-' + sno).val('0');
    $('#ddlPerson-' + sno).val('0');
    FincalCalculation();
}

function ChangeRoomRate(Sno) {
    debugger;
    var PricePerDay = $('#customizeratePricePerDay_' + Sno).val() || 0;
    var PriceDifference = $('#customizeratePriceDifference_' + Sno).val() || 0;
    var ExtraBedAmt = $('#customizerateExtraBedAmt_' + Sno).val() || 0;


    $('#row_' + Sno).attr('roomcharge', PricePerDay);
    $('#row_' + Sno).attr('doublebedcharge', PriceDifference);
    $('#row_' + Sno).attr('extrabedprice', ExtraBedAmt);

    $('#spn1-' + Sno).text(PricePerDay);
    $('#spn2-' + Sno).text(PriceDifference);




    FincalCalculation();
}

function makePay() {

    $('#txtDueAmount').val($('#txtFinalPayable').text());

    $('#modalGuestInformation').modal('show');
}

function CalculateDue() {

    var Payable = parseInt($('#txtFinalPayable').text() || 0);
    var PaidAmt= parseInt($('#txtPayAmount').val() || 0);

    $('#txtDueAmount').val(Payable - PaidAmt);
}
function NameEqualGuestName() {
    $('#txtGuestName').val($('#txtBookingGuestname').val());
}


function insertBooking() {

    var PaymentMode = $('input[name=paymentmode]:checked').val()

    if ($("#txtGuestName").val() == "") {
        alert("Please Enter Name!");
        $("#txtGuestName").focus();
        return;
    }
    debugger;
    if ($("#txtBookingGuestname").val() == "") {
        alert("Please Enter Guest Name!");
        $("#txtBookingGuestname").focus();
        return;
    }
    if ($("#txtMobileNo").val() == "") {
        alert("Please Enter Mobile No!");
        $("#txtMobileNo").focus();
        return;
    }
    if (PaymentMode == 'Cash') {
        if ($('#txtPayAmount').val() == '') {
            alert('Please Enter Payable Amount');
            $('#txtPayAmount').focus();
            return false;
        }
    }
    if (PaymentMode == 'NFT' || PaymentMode == 'Card' || PaymentMode == 'IMPS') {
        if ($('#txtPayAmount').val() == '') {
            alert('Please Enter Payable Amount');
            $('#txtPayAmount').focus();
            return false;
        }
        if ($('#txtReferencenumber').val() == '') {
            alert('Please Enter Reference number');
            $('#txtReferencenumber').focus();
            return false;
        }

    }


    var conf = confirm('Are you sure to create this Booking?');
    if (!conf) {
        return;
    }
    $(':input[type="submit"]').prop('disabled', true);



    // Get Booking Data


    var GSTPer = 12;
    var GstNature = $('input.chkgst:checked').val();


    var RoomDetailsLst = [];
    $('#tbl1 tbody tr').each(function () {
        debugger;

        var CatObj = {};

        var sno = $(this).attr('indexnew');


        var Noofrooms = parseInt($('#ddlRoom-' + sno).val() || 0);
        var NoofPerson = parseInt($('#ddlPerson-' + sno).val() || 0);

        var startDay = $("#t-datepicker-" + sno + " .t-input-check-in").val();
        var endDay = $("#t-datepicker-" + sno + " .t-input-check-out").val();

        if (Noofrooms === 0) {
            return; // Use return instead of continue to exit the current iteration
        }

        var noofbed = parseInt($(this).attr('noofbed') || 0);
        var roomcharge = parseFloat($(this).attr('roomcharge') || 0);
        var doublebedcharge = parseFloat($(this).attr('doublebedcharge') || 0);
        var extrabedper = parseFloat($(this).attr('extrabedper') || 0);
        var extrabedprice = parseFloat($(this).attr('extrabedprice') || 0);
        var categoryId = parseInt($(this).attr('categoryId') || 0);




        CatObj["categoryId"] = categoryId;
        CatObj["CheckInDate"] = startDay;
        CatObj["CheckOutDate"] = endDay;
        CatObj["Noofrooms"] = Noofrooms;
        CatObj["NoofPerson"] = NoofPerson;
        CatObj["roomcharge"] = roomcharge;
        CatObj["doublebedcharge"] = doublebedcharge;
        CatObj["extrabedprice"] = extrabedprice;

        RoomDetailsLst.push(CatObj);

    })


    var Request = {
        
        BookingGuestName: $("#txtBookingGuestname").val(),
        GuestName: $("#txtBookingGuestname").val(),
        GuestMobileNo: $("#txtMobileNo").val(),
        GuestEmailId: $("#txtemailId").val(),
        gstNo: $("#txtgstNo").val(),
        PaymentMode: $('input[name=paymentmode]:checked').val(),
        Referencenumber: $('#txtReferencenumber').val(),
        GSTNature: $('input.chkgst:checked').val(),
        GSTPer: 12,
        DiscountPer: $('#txtDiscount').val(),
        DiscountReason: $('#txtDiscountReason').val(),
        PayAmount: $('#txtPayAmount').val(),
        RoomeDetailJson: JSON.stringify(RoomDetailsLst)

    }

   // console.log(JSON.stringify(Request));



    $.post('/Unit/Booking/InsertBooking', Request, function (Res) {
        debugger;
        Res = eval(Res)[0];
        alert(Res.msg);
        $(':input[type="submit"]').prop('disabled', false);
        if (Res.flag == '1') {
            window.location.href = window.location.href;
        }


    });



}
