using Azure.Core;
using Hotel.Areas.Admin.DTO;
using Hotel.Models;
using System.Data;
using System.Data.SqlClient;

namespace Hotel.Areas.Admin.Models.Services.Booking
{
    public class BookingService : IBookingService
    {

        DBHelper db = new DBHelper();
        public DataTable USP_CategoryWiseRoomDetails(HotelBookingDTO Requist)
        {
            DataTable dt = new DataTable();
            SqlParameter[] parm = new SqlParameter[] {
                  new SqlParameter("@Action" ,Requist.Action),
                  new SqlParameter("@HotelId" ,Requist.HotelId),
                  new SqlParameter("@CategoryId" ,Requist.CategoryId),
                  new SqlParameter("@CheckInDate" ,Requist.CheckInDate),
                  new SqlParameter("@CheckOutDate" ,Requist.CheckOutDate),
            };
            dt = db.ExecProcDataTable("USP_CategoryWiseRoomDetails", parm);
            return dt;
        }
        public DataTable USP_BookingDetails(HotelBookingDTO Requist)
        {
            DataTable dt = new DataTable();
            SqlParameter[] parm = new SqlParameter[] {
                  new SqlParameter("@BookingId" ,Requist.BookingId),
                  new SqlParameter("@CheckInDate" ,Requist.CheckInDate),
                  new SqlParameter("@CheckOutDate" ,Requist.CheckOutDate),
            };
            dt = db.ExecProcDataTable("USP_BookingDetails", parm);
            return dt;
        }

        public DataTable USP_InsertBooking(BooingRoot Request)
        {
            DataTable dt = new DataTable();
            SqlParameter[] parm = new SqlParameter[] {
                  new SqlParameter("@Action" ,Request.Action),
                  new SqlParameter("@HotelId" ,Request.HotelId),
                  new SqlParameter("@BookingGuestName" ,Request.BookingGuestName),
                  new SqlParameter("@GuestName" ,Request.GuestName),
                  new SqlParameter("@GuestMobileNo" ,Request.GuestMobileNo),
                  new SqlParameter("@GuestEmailId" ,Request.GuestEmailId),
                  new SqlParameter("@gstNo" ,Request.gstNo),
                  new SqlParameter("@PaymentMode" ,Request.PaymentMode),
                  new SqlParameter("@Referencenumber" ,Request.Referencenumber),
                  new SqlParameter("@GSTNature" ,Request.GSTNature),
                  new SqlParameter("@GSTPer" ,Request.GSTPer),
                  new SqlParameter("@DiscountPer" ,Request.DiscountPer),
                  new SqlParameter("@DiscountReason" ,Request.DiscountReason),
                  new SqlParameter("@PayAmount" ,Request.PayAmount),
                  new SqlParameter("@RoomeDetailJson" ,Request.RoomeDetailJson),
            };
            dt = db.ExecProcDataTable("USP_InsertBooking", parm);
            return dt;
        }
    }
}
