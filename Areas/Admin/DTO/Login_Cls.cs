using System.Data;

namespace Hotel.Areas.Admin.DTO
{
	public class Login_Cls
	{
		public string Action { get; set; }
		public DataTable dt { get; set; }
		public int UserId { get; set; }
		public string UserName { get; set; }
		public string? HotelId { get; set; }
		public string Password { get; set; }
		public DateTime? LastLoginDate { get; set; }
		public string OPT { get; set; }
	}
}
