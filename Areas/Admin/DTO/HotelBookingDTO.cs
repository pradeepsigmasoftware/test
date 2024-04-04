using System.Data;

namespace Hotel.Areas.Admin.DTO
{
    public class HotelBookingDTO
    {
        public string Action { get; set; }
        public long BookingId { get; set; }

        public string DocketeNo { get; set; }

        public string BillNo { get; set; }

        public string BookingDate { get; set; }

        public string CheckInDate { get; set; }

        public string CheckOutDate { get; set; }

        public string HotelId { get; set; }

        public decimal? HotelCharges { get; set; }

        public decimal? DiscountAmount { get; set; }

        public decimal? Gstamt { get; set; }

        public decimal? SubTotal { get; set; }

        public decimal? OtherCharges { get; set; }

        public decimal? NetPayable { get; set; }

        public decimal? PaidAmount { get; set; }

        public decimal? DueAmount { get; set; }

        public string Status { get; set; }

        public string BookingStatus { get; set; }

        public string CancelDate { get; set; }

        public string BookingSource { get; set; }

        public string GuestLoginId { get; set; }

        public string GuestMobileNo { get; set; }

        public string GuestName { get; set; }

        public string BookingGuestname { get; set; }

        public string GuestEmailId { get; set; }

        public string GuestGstno { get; set; }

        public string GuestAddress { get; set; }
        public DataTable Table1 { get; set; }
        public DataTable Table2 { get; set; }
        public int CategoryId { get; set; }

        public int convertToInt(object Val)
        {
            int Res = 0;
            int.TryParse(Val.ToString(), out Res);
            return Res;
        }


    }



    // Root myDeserializedClass = JsonConvert.DeserializeObject<Root>(myJsonResponse);
    //public class RoomDetails
    //{
    //    public int categoryId { get; set; }
    //    public string CheckInDate { get; set; }
    //    public string CheckOutDate { get; set; }
    //    public int Noofrooms { get; set; }
    //    public int NoofPerson { get; set; }
    //    public decimal roomcharge { get; set; }
    //    public decimal doublebedcharge { get; set; }
    //    public decimal extrabedprice { get; set; }
    //}

    public class BooingRoot
    {
       
        public string Action { get; set; }
        public string HotelId { get; set; }
        public string BookingGuestName { get; set; }
        public string GuestName { get; set; }
        public string GuestMobileNo { get; set; }
        public string GuestEmailId { get; set; }
        public string gstNo { get; set; }
        public string PaymentMode { get; set; }
        public string Referencenumber { get; set; }
        public string GSTNature { get; set; }
        public decimal GSTPer { get; set; }
        public decimal DiscountPer { get; set; }
        public string DiscountReason { get; set; }
        public decimal PayAmount { get; set; }
        public string RoomeDetailJson { get; set; }
    }


}
