function CheckIn_Step1(BookingId, DocketeNo) {
    debugger;

    $.post('/Unit/Dashboard/CheckInRoomDetails', { BookingId: BookingId, DocketeNo: DocketeNo }, function (Res) {
        
        $('#CheckInMainDiv').html($(Res).find('#CheckInRoomDetailsContainer')[0].outerHTML);
        

    })




}


function CheckValidation(_this) {
    debugger;

    //if (!$(_this).prop('checked')) {
    //    $(_this).parent().find('.selectedExtraBed').hide();
    //    $(_this).parent().find('.selectedExtrabedinput').prop('checked', false);
    //    return;
    //}



    var noofbed = parseInt($(_this).attr('noofbed') || 0);
    var noofrooms = parseInt($(_this).attr('noofrooms') || 0);
    var catid = parseInt($(_this).attr('catid') || 0);
    var roomno = parseInt($(_this).attr('roomno') || 0);
    var extrabed = parseInt($(_this).attr('extrabed') || 0);


    var SelectedRooms = $('#CategoryCantainer_' + catid + ' .selectedRooms:checked').length;


    if (SelectedRooms > noofrooms) {
        alert('You can select only ' + noofrooms + ' room.');
        $(_this).prop('checked', false);
        return;
    }

    if (extrabed > 0) {
        var SelectedRooms = $('#CategoryCantainer_' + catid + ' .selectedExtraBed:checked').length;

        if (extrabed > SelectedRooms) {
            $(_this).parent().find('.selectedExtraBed').show()
            return;
        }


    }






}

function FinalCheckIn()
{
    debugger;

    var GuestName = $('#txtGuestName112').val();
    var IdProof = $('#ddlIdProof').val();
    var AdharNo = $('#txtAdharNo').val();
    var GuestregNo = $('#txtGuestregNo').val();
    var GuestAddress = $('#txtGuestAddress').val();

    if (GuestName == '') {
        alert('Please Select Guest Name');
        $('#txtGuestName112').focus();
        return;
    }
    if (AdharNo == '') {
        alert('Please Select Id Proof No');
        $('#txtAdharNo').focus();
        return;
    }



    var RoomList = [];
    $('.selectedRooms:checked').each(function () {
        var Cobj = {};
        Cobj["CategoryId"] = parseInt($(this).attr('catid') || 0);
        Cobj["RoomNo"] = $(this).attr('roomno');
        Cobj["NoOfPerson"] = parseInt($(this).parent().find('.selectedExtrabedinput').val() || 0);

        RoomList.push(Cobj);
    })

    if (RoomList.length == 0) {
        alert('Please Select Room');
        return;
    }

    var Request = {
        BookingId: $('#BookingId').val(),
        GuestName: GuestName,
        IdProof: IdProof,
        AdharNo: AdharNo,
        GuestregNo: GuestregNo,
        GuestAddress: GuestAddress,
        RoomJson: JSON.stringify(RoomList),
    }

    $('#btnFinalCheckIn').prop('disabled', true);
    $.post('/Unit/Dashboard/InsertCheckIn', Request, function (Res) {

        Res = eval(Res)[0];
        alert(Res.msg);
        if (Res.flag == '1') {
            window.location.href = window.location.href;
        }
        
    })




    
}