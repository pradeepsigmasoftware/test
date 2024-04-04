using System.Data;
using Hotel.data;
using Microsoft.EntityFrameworkCore;

namespace Hotel.Areas.Admin.DTO
{
	public class BookingRoomDetails_Cls
	{
		public string Action { get; set; }
		public DataTable dt { get; set; }		
		public int RoomId { get; set; }
		public string[] RoomNo { get; set; }
		public string strRoomNo { get; set; }
		public string HotelId { get; set; }
		public int CategoryId { get; set; }
		public bool IsActive { get; set; }
		public string EntryDate { get; set; }
		public bool IsOffLine { get; set; }
		public string OffLineDate { get; set; }
		public string OLDatefrom { get; set; }
		public string OLDateTo { get; set; }
		public DbSet<BookingRoomDetails_Cls> tbl_RoomDetail { get; set; }
	}
}
