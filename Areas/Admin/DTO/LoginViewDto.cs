using System.Data;

namespace Hotel.Areas.Admin.DTO
{
    public class LoginViewDto
    {  
        public int UserId { get; set; }
        public string UserName { get; set; }
        public string? Email { get; set; }
        public string Password { get; set; }
        public int? RoleId { get; set; }
        public bool? IsActive { get; set; }
        public int? CreatedBy { get; set; }
        public DateTime? CreatedOn { get; set; }
        public int? UpdateBy { get; set; }
        public DateTime? UpdatedOn { get; set; }
        public DateTime? LastLoginDate { get; set; }
        public DateTime? LastPasswordChange { get; set; }
        public string? Ip { get; set; }

    }
    public class UserSessionDto
    {
        public int? UserId { get; set; }
        public string UserName { get; set; }
        public string Name { get; set; }
        public string Email { get; set; }
        public int? RoleID { get; set; }
        public string HotelId { get; set; }
    }
}
