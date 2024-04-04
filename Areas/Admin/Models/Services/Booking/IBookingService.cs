using Hotel.Areas.Admin.DTO;
using System.Data;

namespace Hotel.Areas.Admin.Models.Services.Booking
{
    public interface IBookingService
    {
        public DataTable USP_BookingDetails(HotelBookingDTO Requist);
        public DataTable USP_CategoryWiseRoomDetails(HotelBookingDTO Requist);
        DataTable USP_InsertBooking(BooingRoot request);
    }













}
