using System.Data;

namespace Hotel.Areas.Unit.DTO
{
    public class UnitHomeViewModel
    {
        public string Action { get; set; }
        public string BookingId { get; set; }
        public string DocketeNo { get; set; }
        public string HotelId { get; set; }
        public int CategoryId { get; set; }
        public string CheckInDate { get; set; }
        public string CheckOutDate { get; set; }

        public string GuestName { get; set; }
        public string IdProof { get; set; }
        public string AdharNo { get; set; }
        public string GuestregNo { get; set; }
        public string GuestAddress { get; set; }
        public string BookingStatus { get; set; }

        public string RoomJson { get; set; }
        public DataTable Table1 { get; set; }
        public DataTable Table2 { get; set; }
        public DataTable Table3 { get; set; }
        
    }
    public class RoomDetails
    {
        public int CategoryId { get; set; }
        public string RoomNo { get; set; }
        public int NoOfPerson { get; set; }

    }




}
