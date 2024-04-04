using Hotel.Areas.Admin.DTO;
using System.Data;

namespace Hotel.Areas.Admin.Models.Services.Hotel
{
    public interface IHotelDTOService
    {

        DataTable HotelMasterDTO(HotelDTO_Cls request);

        DataTable CategoryMasterService(CategoryMaster_Cls request);

        DataTable GstMasterService(GstMaster_Cls request);

        DataTable HotelImageMasterService(HotelImageMaster_Cls request);

        DataTable HotelLoginDetailsService(Login_Cls request);

        DataTable HotelRoomMasterService(RoomImages_Cls request);
        DataTable BookingRoomDetailsService(BookingRoomDetails_Cls request);

        DataTable CityMasterService(CityMaster_Cls request);

        DataTable StateMaster(StateMaster_Cls request);

        DataTable CityMasterData(CityMaster_Cls request);

        DataTable HotelMasterData(BindHotelDDLDto_cls request);

        DataTable CategoryMasterData(CategoryMaster_Cls request);
        DataTable RateMasterService(RateMaster_Cls request);



    }
}
