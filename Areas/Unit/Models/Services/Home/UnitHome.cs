using Azure.Core;
using Hotel.Areas.Admin.DTO;
using Hotel.Areas.Unit.DTO;
using Hotel.Models;
using System.Data;
using System.Data.SqlClient;

namespace Hotel.Areas.Unit.Models.Services.Home
{
    public class UnitHome : IUnitHome
    {
        DBHelper db = new DBHelper();

        public DataTable USP_UnitHome(UnitHomeViewModel Requist)
        {
            DataTable dt = new DataTable();
            SqlParameter[] parm = new SqlParameter[] {
                  new SqlParameter("@Action" ,Requist.Action),
                   new SqlParameter("@BookingId" ,Requist.BookingId),
                  new SqlParameter("@HotelId" ,Requist.HotelId),
                  new SqlParameter("@CategoryId" ,Requist.CategoryId),
                  new SqlParameter("@CheckInDate" ,Requist.CheckInDate),
                  new SqlParameter("@CheckOutDate" ,Requist.CheckOutDate),
            };
            dt = db.ExecProcDataTable("USP_UnitHome", parm);
            return dt;
        }
        public DataTable USP_InsertCheckIn(UnitHomeViewModel Requist)
        {
            DataTable dt = new DataTable();
            SqlParameter[] parm = new SqlParameter[] {
                  new SqlParameter("@Action" ,Requist.Action),
                  new SqlParameter("@BookingId" ,Requist.BookingId),
                   new SqlParameter("@HotelId" ,Requist.HotelId),
                  new SqlParameter("@GuestName" ,Requist.GuestName),
                  new SqlParameter("@IdProof" ,Requist.IdProof),
                  new SqlParameter("@AdharNo" ,Requist.AdharNo),
                  new SqlParameter("@GuestregNo" ,Requist.GuestregNo),
                  new SqlParameter("@GuestAddress" ,Requist.GuestAddress),
                  new SqlParameter("@RoomJson" ,Requist.RoomJson),
            };
            dt = db.ExecProcDataTable("USP_InsertCheckIn", parm);
            return dt;
        }
        public DataTable GetManageBookingData(UnitHomeViewModel Requist)
        {
            DataTable dt = new DataTable();
            SqlParameter[] parm = new SqlParameter[] {
                  new SqlParameter("@Action" ,Requist.Action),
                   new SqlParameter("@BookingId" ,Requist.BookingId),
                  new SqlParameter("@HotelId" ,Requist.HotelId),
                  new SqlParameter("@CategoryId" ,Requist.CategoryId),
                  new SqlParameter("@CheckInDate" ,Requist.CheckInDate),
                  new SqlParameter("@CheckOutDate" ,Requist.CheckOutDate),
                   new SqlParameter("@BookingStatus" ,Requist.BookingStatus),
            };
            dt = db.ExecProcDataTable("USP_GetManageBookingData", parm);
            return dt;
        }


    }
}
