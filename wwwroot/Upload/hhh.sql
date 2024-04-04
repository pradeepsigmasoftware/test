USE [UPSTDCHoteldb]
GO
/****** Object:  UserDefinedFunction [dbo].[GetAvailableRooms]    Script Date: 04-Apr-2024 15:17:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[GetAvailableRooms]
(
@HotelId VARCHAR(32),
@CategoryId INT,
@CheckInDate DATE,
@CheckOutDate DATE
)
RETURNS INT
BEGIN

DECLARE @Res INT=1

DECLARE @TotalRoom INT=0;
DECLARE @BookedRoom INT=0;

SELECT @TotalRoom=TotalRoom FROM RoomDetail_CategoryWise_ForBooking WHERE HotelId=@HotelId AND CategoryId=@CategoryId

SET @BookedRoom = dbo.GetBookedRooms(@HotelId,@CategoryId,@CheckInDate,@CheckOutDate);

SET @Res = isnull(@TotalRoom,0)-isnull(@BookedRoom,0)

RETURN isnull(@Res,0);

END
GO
/****** Object:  UserDefinedFunction [dbo].[GetBookedRooms]    Script Date: 04-Apr-2024 15:17:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[GetBookedRooms]
(
@HotelId VARCHAR(32),
@CategoryId INT = 24,
@CheckInDate DATE,
@CheckOutDate DATE
)
RETURNS INT
BEGIN
DECLARE @Res INT=0

DECLARE @NewCheckoutDate DATE=dateadd(dd,-1,@CheckOutDate);

WITH GetDates AS  
(  
    SELECT @CheckInDate AS Dates
    UNION ALL  
    SELECT DATEADD(day, 1, Dates) AS Dates 
    FROM GetDates  
    WHERE Dates < @NewCheckoutDate 
)  

SELECT @Res=sum(NoofRooms) FROM (
SELECT distinct B02_BookingRoom_ID,NoofRooms FROM GetDates a
JOIN B02_BookingRoomDetails b ON a.Dates BETWEEN b.CheckInDate AND dateadd(dd,-1,b.CheckOutDate)
WHERE b.HotelId=@HotelId AND b.CategoryId=@CategoryId
)tt
    
RETURN isnull(@Res,0);    

END
GO
/****** Object:  UserDefinedFunction [dbo].[GetBookingDays]    Script Date: 04-Apr-2024 15:17:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetBookingDays]
(
@CheckInDate DATE,
@CheckOutDate DATE
)
RETURNS INT
BEGIN

DECLARE @Res INT


SET @Res= datediff(dd,@CheckOutDate,@CheckInDate)


RETURN iif(isnull(@Res,0)=0,1,@Res);

END
GO
/****** Object:  UserDefinedFunction [dbo].[GetDoubleOccupancy]    Script Date: 04-Apr-2024 15:17:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetDoubleOccupancy]
(
@NoofRooms INT,
@NoOfPerson INT,
@NoOfBed INT
)
RETURNS INT
BEGIN

DECLARE @Res INT

   IF(@NoOfPerson > @NoofRooms) 
   BEGIN
     SET @Res = @NoOfPerson - @NoofRooms;
       IF(@Res > @NoofRooms) 
       BEGIN
         SET  @Res = @NoofRooms;
       END 
   END 



RETURN isnull(@Res,0);

END
GO
/****** Object:  UserDefinedFunction [dbo].[GetExtraBed]    Script Date: 04-Apr-2024 15:17:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetExtraBed]
(
@NoofRooms INT,
@NoOfPerson INT,
@NoOfBed INT
)
RETURNS INT
BEGIN

DECLARE @Res INT

 if (@NoOfPerson > (@NoofRooms * @NoOfBed)) 
 BEGIN
    set @Res = @NoOfPerson - (@NoofRooms * @NoOfBed);
 END 




RETURN isnull(@Res,0);

END
GO
/****** Object:  UserDefinedFunction [dbo].[GetGSTAmt]    Script Date: 04-Apr-2024 15:17:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetGSTAmt]
(
@GrossAmount INT,
@GStPer INT,
@GSTNature VARCHAR(32)
)
RETURNS DECIMAL(18,2)
BEGIN

DECLARE @Res DECIMAL(18,2)

 if (@GSTNature = 'Exclude')
     SET @Res = (@GrossAmount * @GStPer / 100.0)
 else 
    SET  @Res = @GrossAmount * @GStPer / (100.0 + @GStPer);
 



RETURN isnull(@Res,0);

END
GO
/****** Object:  Table [dbo].[tbl_RoomDetail]    Script Date: 04-Apr-2024 15:17:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_RoomDetail](
	[RoomId] [int] IDENTITY(1,1) NOT NULL,
	[RoomNo] [varchar](16) NOT NULL,
	[HotelId] [varchar](32) NOT NULL,
	[CategoryId] [int] NOT NULL,
	[IsActive] [bit] NULL,
	[EntryDate] [datetime] NULL,
	[IsOffLine] [bit] NULL,
	[OffLineDate] [datetime] NULL,
	[OLDatefrom] [date] NULL,
	[OLDateTo] [date] NULL,
PRIMARY KEY CLUSTERED 
(
	[RoomId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[RoomDetail_CategoryWise_ForBooking]    Script Date: 04-Apr-2024 15:17:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[RoomDetail_CategoryWise_ForBooking]
AS
SELECT HotelId, CategoryId,count(1)TotalRoom FROM tbl_RoomDetail WHERE isnull(IsActive,0)=1 AND isnull(IsOffLine,0)=0
GROUP BY HotelId, CategoryId
GO
/****** Object:  Table [dbo].[RateMaster]    Script Date: 04-Apr-2024 15:17:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RateMaster](
	[RateID] [int] IDENTITY(1,1) NOT NULL,
	[HotelId] [varchar](32) NOT NULL,
	[CategoryId] [int] NOT NULL,
	[PricePerDay] [decimal](18, 2) NOT NULL,
	[PriceDifference] [decimal](18, 2) NULL,
	[ExtraBedPercentage] [decimal](18, 4) NULL,
	[RateStartDate] [date] NOT NULL,
	[RateEndDate] [date] NOT NULL,
	[IsActive] [bit] NULL,
	[EntryBy] [varchar](50) NULL,
	[EntryDate] [datetime] NULL,
	[ExtraBadPriceMode] [varchar](20) NULL,
PRIMARY KEY CLUSTERED 
(
	[RateID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[GetRateCategoryWise]    Script Date: 04-Apr-2024 15:17:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[GetRateCategoryWise]
(
    @HotelId VARCHAR(32),
    @BooingDate DATE
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        HotelId, 
        CategoryId, 
        PricePerDay, 
        PriceDifference, 
        ExtraBedPercentage 
    FROM (
        SELECT 
            ROW_NUMBER() OVER (PARTITION BY CategoryId ORDER BY RateID DESC) AS Sno,
            RateID,
            HotelId, 
            CategoryId, 
            PricePerDay, 
            PriceDifference, 
            ExtraBedPercentage 
        FROM RateMaster 
        WHERE 
            HotelId = @HotelId
            AND @BooingDate BETWEEN RateStartDate AND RateEndDate
    ) AS tt 
    WHERE 
        tt.Sno = 1
);
GO
/****** Object:  Table [dbo].[B04_ChickInDetails]    Script Date: 04-Apr-2024 15:17:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[B04_ChickInDetails](
	[B04_ChickIn_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[BookingId] [bigint] NOT NULL,
	[HotelId] [varchar](32) NOT NULL,
	[CategoryId] [int] NOT NULL,
	[CheckInDate] [datetime] NOT NULL,
	[CheckOutDate] [datetime] NOT NULL,
	[UpdateStatus] [varchar](32) NULL,
	[UpdateDate] [datetime] NULL,
	[NoOfDays] [int] NOT NULL,
	[RoomNo] [varchar](32) NOT NULL,
	[BookingStatus] [varchar](32) NULL,
	[NoofAdults] [int] NULL,
	[NoofChilds] [int] NULL,
	[ExtraBed] [int] NULL,
	[RoomChargesPerDay] [decimal](18, 2) NULL,
	[DoubleOccupancyPer] [decimal](18, 2) NULL,
	[ExtraBedPricePer] [decimal](18, 2) NULL,
	[TotalRoomCharge] [decimal](18, 2) NULL,
	[DiscountPer] [decimal](18, 2) NULL,
	[DisountAmount_Per] [decimal](18, 2) NULL,
	[DisountAmount] [decimal](18, 2) NULL,
	[GrossAmount] [decimal](18, 2) NULL,
	[GStPer] [decimal](18, 2) NULL,
	[GStAmount] [decimal](18, 2) NULL,
	[CGST] [decimal](18, 2) NULL,
	[SGST] [decimal](18, 2) NULL,
	[TotalGST] [decimal](18, 2) NULL,
	[TotalPayable] [decimal](18, 2) NULL,
	[GSTNature] [varchar](32) NULL,
	[IsActive] [bit] NULL,
	[EntryBy] [varchar](50) NULL,
	[EntryDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[B04_ChickIn_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[VW_ChickedInRooms_Booking_And_CategoryWise]    Script Date: 04-Apr-2024 15:17:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  VIEW [dbo].[VW_ChickedInRooms_Booking_And_CategoryWise]
as
 SELECT BookingId,CategoryId,count(DISTINCT RoomNo)CheckedInRooms,sum(NoofAdults)NoofAdults 
 FROM B04_ChickInDetails GROUP BY HotelId,BookingId,CategoryId
GO
/****** Object:  Table [dbo].[B01_BookingDetails]    Script Date: 04-Apr-2024 15:17:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[B01_BookingDetails](
	[BookingId] [bigint] IDENTITY(1000,1) NOT NULL,
	[DocketeNo] [varchar](16) NULL,
	[BillNo] [varchar](16) NULL,
	[BookingDate] [datetime] NOT NULL,
	[CheckInDate] [date] NULL,
	[CheckOutDate] [date] NULL,
	[CheckInDate1] [datetime] NULL,
	[CheckOutDate1] [datetime] NULL,
	[HotelId] [varchar](32) NOT NULL,
	[NetPayable] [decimal](18, 2) NULL,
	[PaidAmount] [decimal](18, 2) NULL,
	[DueAmount] [decimal](18, 2) NULL,
	[Status] [varchar](32) NULL,
	[BookingStatus] [varchar](32) NULL,
	[CancelDate] [datetime] NULL,
	[BookingSource] [varchar](16) NULL,
	[GuestLoginId] [varchar](50) NULL,
	[GuestMobileNo] [varchar](16) NULL,
	[GuestName] [nvarchar](250) NULL,
	[BookingGuestname] [varchar](250) NULL,
	[GuestEmailID] [varchar](50) NULL,
	[GuestGSTNo] [varchar](32) NULL,
	[GuestAddress] [nvarchar](250) NULL,
	[IsActive] [bit] NULL,
	[EntryBy] [varchar](50) NULL,
	[EntryDate] [datetime] NULL,
	[IdProof] [varchar](50) NULL,
	[IdProofNo] [varchar](150) NULL,
	[GuestregNo] [varchar](150) NULL,
PRIMARY KEY CLUSTERED 
(
	[BookingId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[B02_BookingRoomDetails]    Script Date: 04-Apr-2024 15:17:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[B02_BookingRoomDetails](
	[B02_BookingRoom_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[BookingId] [bigint] NOT NULL,
	[HotelId] [varchar](32) NOT NULL,
	[CategoryId] [int] NOT NULL,
	[CheckInDate] [date] NULL,
	[CheckOutDate] [date] NULL,
	[Days] [int] NULL,
	[NoOfBed] [int] NULL,
	[NoofRooms] [int] NULL,
	[NoofAdults] [int] NULL,
	[NoofChilds] [int] NULL,
	[ExtraBed] [int] NULL,
	[DoubleOccupancy] [int] NULL,
	[RoomCharge] [decimal](18, 2) NULL,
	[DoubleOccupancyCharge] [decimal](18, 2) NULL,
	[ExtraBedCharge] [decimal](18, 2) NULL,
	[RoomAmt] [decimal](18, 2) NULL,
	[DoubleOccupancyAmt] [decimal](18, 2) NULL,
	[ExtraBedamt] [decimal](18, 2) NULL,
	[TotalRoomAmt] [decimal](18, 2) NULL,
	[DiscountPer] [decimal](18, 2) NULL,
	[DisountAmount] [decimal](18, 2) NULL,
	[GrossAmount] [decimal](18, 2) NULL,
	[GStPer] [decimal](18, 2) NULL,
	[CGST] [decimal](18, 2) NULL,
	[SGST] [decimal](18, 2) NULL,
	[TotalGST] [decimal](18, 2) NULL,
	[TotalPayable] [decimal](18, 2) NULL,
	[GSTNature] [varchar](32) NULL,
	[BookingStatus] [varchar](32) NULL,
	[CancelRoom] [int] NULL,
	[RefundPer] [decimal](18, 2) NULL,
	[RefundAmt] [decimal](18, 2) NULL,
	[CancelDate] [datetime] NULL,
	[cancelBy] [varchar](100) NULL,
	[IsActive] [bit] NULL,
	[EntryBy] [varchar](50) NULL,
	[EntryDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[B02_BookingRoom_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[B03_TransactionDetails]    Script Date: 04-Apr-2024 15:17:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[B03_TransactionDetails](
	[B03_Transaction_ID] [bigint] IDENTITY(1000,1) NOT NULL,
	[BookingId] [bigint] NOT NULL,
	[PaymentSourse] [varchar](32) NULL,
	[NetPayable] [decimal](18, 2) NULL,
	[DiscountAmt] [decimal](18, 2) NULL,
	[PaidAmount] [decimal](18, 2) NULL,
	[DueAmount] [decimal](18, 2) NULL,
	[BillNo] [varchar](32) NULL,
	[PaymentMode] [varchar](500) NULL,
	[ResponseURL] [nvarchar](500) NULL,
	[TransactionID] [varchar](50) NULL,
	[TransactionDate] [datetime] NULL,
	[TID] [varchar](100) NULL,
	[TMode] [varchar](100) NULL,
	[mihpayid] [varchar](200) NULL,
	[hashResponce] [varchar](max) NULL,
	[NameOnCard] [varchar](500) NULL,
	[CardNo] [varchar](100) NULL,
	[requestKey] [varchar](500) NULL,
	[IsActive] [bit] NULL,
	[EntryBy] [varchar](50) NULL,
	[EntryDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[B03_Transaction_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CityMaster]    Script Date: 04-Apr-2024 15:17:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CityMaster](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[StateId] [int] NOT NULL,
	[CityName] [nvarchar](500) NOT NULL,
	[IsDeleted] [bit] NULL,
	[EntryDate] [datetime] NULL,
	[UnitAbbr] [nvarchar](100) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[GSTMaster]    Script Date: 04-Apr-2024 15:17:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GSTMaster](
	[GSTID] [int] NOT NULL,
	[StartAmt] [decimal](18, 2) NULL,
	[EndAmt] [decimal](18, 2) NULL,
	[GSTPer] [decimal](18, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[GSTID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[InvoiceNotbl]    Script Date: 04-Apr-2024 15:17:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InvoiceNotbl](
	[pk_InvoiceNoid] [bigint] IDENTITY(1,1) NOT NULL,
	[Invoiceno] [bigint] NULL,
	[RestaurentInvoiceno] [bigint] NULL,
	[RBSno] [bigint] NULL,
	[Billno] [bigint] NULL,
	[GRegNo] [bigint] NULL,
	[BanquetBookinInvoice] [bigint] NULL,
	[AgentSrNo] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[pk_InvoiceNoid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Login]    Script Date: 04-Apr-2024 15:17:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Login](
	[USER_Id] [int] IDENTITY(1,1) NOT NULL,
	[UserName] [varchar](100) NOT NULL,
	[Password] [varchar](32) NOT NULL,
	[M_Role_Id] [int] NOT NULL,
	[HotelId] [varchar](32) NULL,
	[LastLoginDate] [datetime] NULL,
	[Created_By] [int] NULL,
	[Created_Date] [datetime] NULL,
	[Is_Active] [bit] NULL,
	[OPT] [varchar](10) NULL,
PRIMARY KEY CLUSTERED 
(
	[UserName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[StateMaster]    Script Date: 04-Apr-2024 15:17:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StateMaster](
	[StateId] [int] IDENTITY(1,1) NOT NULL,
	[StateName] [varchar](100) NOT NULL,
	[StateCode] [varchar](10) NULL,
	[EntryDate] [datetime] NULL,
	[DeleteStatus] [int] NULL,
 CONSTRAINT [PK_StateMaster] PRIMARY KEY CLUSTERED 
(
	[StateId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tbl_BedMaster]    Script Date: 04-Apr-2024 15:17:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_BedMaster](
	[bed_id] [int] IDENTITY(1,1) NOT NULL,
	[BedName] [varchar](100) NULL,
	[noofBed] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[bed_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tbl_CategoryMaster]    Script Date: 04-Apr-2024 15:17:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_CategoryMaster](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Category] [nvarchar](500) NOT NULL,
	[IsActive] [bit] NULL,
	[EntryDate] [datetime] NULL,
	[hotelid] [varchar](32) NOT NULL,
	[MMTCategoryCode] [varchar](50) NULL,
	[MMTHotelCode] [varchar](50) NULL,
	[IRCTcHotelCode] [varchar](200) NULL,
	[IRCTCCategoryCode] [varchar](200) NULL,
	[IsOffline] [bit] NULL,
	[bed_id] [int] NOT NULL,
 CONSTRAINT [PK_tbl_CategoryMaster] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tbl_HotelImageMaster]    Script Date: 04-Apr-2024 15:17:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_HotelImageMaster](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ImagePath] [nvarchar](max) NULL,
	[EntryDate] [datetime] NULL,
	[IsActive] [bit] NULL,
	[HotelId] [varchar](50) NULL,
	[ImgExt] [nvarchar](50) NULL,
 CONSTRAINT [PK_tbl_HotelImageMaster] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tbl_HotelMaster]    Script Date: 04-Apr-2024 15:17:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_HotelMaster](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[HotelId] [varchar](32) NOT NULL,
	[HotelName] [nvarchar](500) NOT NULL,
	[StateId] [int] NULL,
	[CityId] [int] NULL,
	[isOffline] [bit] NULL,
	[Address] [varchar](250) NULL,
	[ContactNo] [varchar](50) NULL,
	[Description] [nvarchar](max) NOT NULL,
	[Longitude] [numeric](18, 6) NULL,
	[Latitude] [numeric](18, 6) NULL,
	[EntryDate] [datetime] NULL,
	[IsActive] [bit] NULL,
	[EmailId] [varchar](100) NULL,
	[ImageURL] [nvarchar](250) NULL,
	[Landline] [varchar](100) NULL,
	[GSTNo] [varchar](100) NULL,
	[HotalCodenew] [varchar](100) NULL,
	[HotelName_City] [varchar](500) NULL,
	[Counter_BillNo] [int] NULL,
	[MMT_HotelCode] [varchar](50) NULL,
	[MMT_AccessToken] [varchar](100) NULL,
	[PatternID] [bigint] NULL,
	[IRCTC_HotelCode] [varchar](50) NULL,
	[FSSAINo] [varchar](50) NULL,
	[ValidDate] [date] NULL,
	[HOtel_UrlNew] [varchar](250) NULL,
	[RedirectURL] [varchar](250) NULL,
	[AccessToken] [varchar](100) NULL,
	[Category] [int] NULL,
	[NoOfRooms] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[HotelId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tbl_RoomImages]    Script Date: 04-Apr-2024 15:17:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_RoomImages](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[hotelId] [nvarchar](50) NULL,
	[CategoryId] [int] NULL,
	[ImagePath] [nvarchar](max) NULL,
	[ImageExt] [nvarchar](50) NULL,
	[EntryDate] [datetime] NULL,
 CONSTRAINT [PK_tbl_RoomImages] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET IDENTITY_INSERT [dbo].[B01_BookingDetails] ON 
GO
INSERT [dbo].[B01_BookingDetails] ([BookingId], [DocketeNo], [BillNo], [BookingDate], [CheckInDate], [CheckOutDate], [CheckInDate1], [CheckOutDate1], [HotelId], [NetPayable], [PaidAmount], [DueAmount], [Status], [BookingStatus], [CancelDate], [BookingSource], [GuestLoginId], [GuestMobileNo], [GuestName], [BookingGuestname], [GuestEmailID], [GuestGSTNo], [GuestAddress], [IsActive], [EntryBy], [EntryDate], [IdProof], [IdProofNo], [GuestregNo]) VALUES (1001, N'LUC2400002', NULL, CAST(N'2024-02-09T10:24:00.500' AS DateTime), CAST(N'2024-02-09' AS Date), CAST(N'2024-02-10' AS Date), NULL, NULL, N'HTL82734', CAST(8434.00 AS Decimal(18, 2)), CAST(634.00 AS Decimal(18, 2)), CAST(7800.00 AS Decimal(18, 2)), N'Success', N'CheckIn', NULL, N'Hotel', N'9415793918', N'9415793918', N'LUCKNOW', N'LUCKNOW', NULL, NULL, NULL, 1, NULL, CAST(N'2024-02-09T10:24:00.500' AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[B01_BookingDetails] ([BookingId], [DocketeNo], [BillNo], [BookingDate], [CheckInDate], [CheckOutDate], [CheckInDate1], [CheckOutDate1], [HotelId], [NetPayable], [PaidAmount], [DueAmount], [Status], [BookingStatus], [CancelDate], [BookingSource], [GuestLoginId], [GuestMobileNo], [GuestName], [BookingGuestname], [GuestEmailID], [GuestGSTNo], [GuestAddress], [IsActive], [EntryBy], [EntryDate], [IdProof], [IdProofNo], [GuestregNo]) VALUES (1002, N'LUC2400003', NULL, CAST(N'2024-02-09T10:26:50.010' AS DateTime), CAST(N'2024-02-09' AS Date), CAST(N'2024-02-10' AS Date), NULL, NULL, N'HTL82734', CAST(5634.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(5634.00 AS Decimal(18, 2)), N'Success', N'CheckIn', NULL, N'Hotel', N'9415793918', N'9415793918', N'LUCKNOW', N'LUCKNOW', NULL, NULL, NULL, 1, NULL, CAST(N'2024-02-09T10:26:50.010' AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[B01_BookingDetails] ([BookingId], [DocketeNo], [BillNo], [BookingDate], [CheckInDate], [CheckOutDate], [CheckInDate1], [CheckOutDate1], [HotelId], [NetPayable], [PaidAmount], [DueAmount], [Status], [BookingStatus], [CancelDate], [BookingSource], [GuestLoginId], [GuestMobileNo], [GuestName], [BookingGuestname], [GuestEmailID], [GuestGSTNo], [GuestAddress], [IsActive], [EntryBy], [EntryDate], [IdProof], [IdProofNo], [GuestregNo]) VALUES (1003, N'LUC2400004', NULL, CAST(N'2024-02-09T10:31:10.590' AS DateTime), CAST(N'2024-02-09' AS Date), CAST(N'2024-02-10' AS Date), NULL, NULL, N'HTL82734', CAST(2240.00 AS Decimal(18, 2)), CAST(834.00 AS Decimal(18, 2)), CAST(1406.00 AS Decimal(18, 2)), N'Success', N'CheckIn', NULL, N'Hotel', N'9415793918', N'9415793918', N'LUCKNOW', N'LUCKNOW', NULL, NULL, NULL, 1, NULL, CAST(N'2024-02-09T10:31:10.590' AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[B01_BookingDetails] ([BookingId], [DocketeNo], [BillNo], [BookingDate], [CheckInDate], [CheckOutDate], [CheckInDate1], [CheckOutDate1], [HotelId], [NetPayable], [PaidAmount], [DueAmount], [Status], [BookingStatus], [CancelDate], [BookingSource], [GuestLoginId], [GuestMobileNo], [GuestName], [BookingGuestname], [GuestEmailID], [GuestGSTNo], [GuestAddress], [IsActive], [EntryBy], [EntryDate], [IdProof], [IdProofNo], [GuestregNo]) VALUES (1004, N'LUC2400005', NULL, CAST(N'2024-02-14T11:17:27.410' AS DateTime), CAST(N'2024-02-14' AS Date), CAST(N'2024-02-16' AS Date), NULL, NULL, N'HTL82734', CAST(6362.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(6362.00 AS Decimal(18, 2)), N'Success', N'CheckIn', NULL, N'Hotel', N'9415793918', N'9415793918', N'Anoopsharms Sharma', N'LUCKNOW', NULL, NULL, N'2/517, Vijay Khand, Gomti Nagar, Lucknow (U.P)- 226010', 1, NULL, CAST(N'2024-02-14T11:17:27.410' AS DateTime), N'Aadhar', N'5459-7878-7787-8778', N'8678768')
GO
INSERT [dbo].[B01_BookingDetails] ([BookingId], [DocketeNo], [BillNo], [BookingDate], [CheckInDate], [CheckOutDate], [CheckInDate1], [CheckOutDate1], [HotelId], [NetPayable], [PaidAmount], [DueAmount], [Status], [BookingStatus], [CancelDate], [BookingSource], [GuestLoginId], [GuestMobileNo], [GuestName], [BookingGuestname], [GuestEmailID], [GuestGSTNo], [GuestAddress], [IsActive], [EntryBy], [EntryDate], [IdProof], [IdProofNo], [GuestregNo]) VALUES (1005, N'LUC2400006', NULL, CAST(N'2024-02-14T12:58:46.180' AS DateTime), CAST(N'2024-02-14' AS Date), CAST(N'2024-02-15' AS Date), NULL, NULL, N'HTL82734', CAST(3175.00 AS Decimal(18, 2)), CAST(175.00 AS Decimal(18, 2)), CAST(3000.00 AS Decimal(18, 2)), N'Success', N'Booked', NULL, N'Hotel', N'9415793918', N'9415793918', N'LUCKNOW', N'LUCKNOW', NULL, NULL, NULL, 1, NULL, CAST(N'2024-02-14T12:58:46.180' AS DateTime), NULL, NULL, NULL)
GO
INSERT [dbo].[B01_BookingDetails] ([BookingId], [DocketeNo], [BillNo], [BookingDate], [CheckInDate], [CheckOutDate], [CheckInDate1], [CheckOutDate1], [HotelId], [NetPayable], [PaidAmount], [DueAmount], [Status], [BookingStatus], [CancelDate], [BookingSource], [GuestLoginId], [GuestMobileNo], [GuestName], [BookingGuestname], [GuestEmailID], [GuestGSTNo], [GuestAddress], [IsActive], [EntryBy], [EntryDate], [IdProof], [IdProofNo], [GuestregNo]) VALUES (1006, N'LUC2400007', NULL, CAST(N'2024-02-14T13:08:21.960' AS DateTime), CAST(N'2024-02-14' AS Date), CAST(N'2024-02-15' AS Date), NULL, NULL, N'HTL82734', CAST(13055.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(13055.00 AS Decimal(18, 2)), N'Success', N'CheckIn', NULL, N'Hotel', N'9415793918', N'9415793918', N'DR. S.K. MISHRA', N'nadeema', N'n@gmail.com', NULL, N'nadeema', 1, NULL, CAST(N'2024-02-14T13:08:21.960' AS DateTime), N'Aadhar', N'5459-7878-7787-8778', NULL)
GO
SET IDENTITY_INSERT [dbo].[B01_BookingDetails] OFF
GO
SET IDENTITY_INSERT [dbo].[B02_BookingRoomDetails] ON 
GO
INSERT [dbo].[B02_BookingRoomDetails] ([B02_BookingRoom_ID], [BookingId], [HotelId], [CategoryId], [CheckInDate], [CheckOutDate], [Days], [NoOfBed], [NoofRooms], [NoofAdults], [NoofChilds], [ExtraBed], [DoubleOccupancy], [RoomCharge], [DoubleOccupancyCharge], [ExtraBedCharge], [RoomAmt], [DoubleOccupancyAmt], [ExtraBedamt], [TotalRoomAmt], [DiscountPer], [DisountAmount], [GrossAmount], [GStPer], [CGST], [SGST], [TotalGST], [TotalPayable], [GSTNature], [BookingStatus], [CancelRoom], [RefundPer], [RefundAmt], [CancelDate], [cancelBy], [IsActive], [EntryBy], [EntryDate]) VALUES (1, 1001, N'HTL82734', 23, CAST(N'2024-02-09' AS Date), CAST(N'2024-02-10' AS Date), 1, 2, 1, 1, NULL, 0, 0, CAST(2500.00 AS Decimal(18, 2)), CAST(200.00 AS Decimal(18, 2)), CAST(405.00 AS Decimal(18, 2)), CAST(2500.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(2500.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(2500.00 AS Decimal(18, 2)), CAST(12.00 AS Decimal(18, 2)), CAST(150.00 AS Decimal(18, 2)), CAST(150.00 AS Decimal(18, 2)), CAST(300.00 AS Decimal(18, 2)), CAST(2800.00 AS Decimal(18, 2)), N'Exclude', N'CheckIn', NULL, NULL, NULL, NULL, NULL, 1, NULL, CAST(N'2024-02-09T10:24:00.520' AS DateTime))
GO
INSERT [dbo].[B02_BookingRoomDetails] ([B02_BookingRoom_ID], [BookingId], [HotelId], [CategoryId], [CheckInDate], [CheckOutDate], [Days], [NoOfBed], [NoofRooms], [NoofAdults], [NoofChilds], [ExtraBed], [DoubleOccupancy], [RoomCharge], [DoubleOccupancyCharge], [ExtraBedCharge], [RoomAmt], [DoubleOccupancyAmt], [ExtraBedamt], [TotalRoomAmt], [DiscountPer], [DisountAmount], [GrossAmount], [GStPer], [CGST], [SGST], [TotalGST], [TotalPayable], [GSTNature], [BookingStatus], [CancelRoom], [RefundPer], [RefundAmt], [CancelDate], [cancelBy], [IsActive], [EntryBy], [EntryDate]) VALUES (2, 1001, N'HTL82734', 24, CAST(N'2024-02-09' AS Date), CAST(N'2024-02-11' AS Date), 1, 2, 1, 3, NULL, 1, 1, CAST(2000.00 AS Decimal(18, 2)), CAST(200.00 AS Decimal(18, 2)), CAST(330.00 AS Decimal(18, 2)), CAST(2000.00 AS Decimal(18, 2)), CAST(200.00 AS Decimal(18, 2)), CAST(330.00 AS Decimal(18, 2)), CAST(2530.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(2530.00 AS Decimal(18, 2)), CAST(12.00 AS Decimal(18, 2)), CAST(151.80 AS Decimal(18, 2)), CAST(151.80 AS Decimal(18, 2)), CAST(303.60 AS Decimal(18, 2)), CAST(2833.60 AS Decimal(18, 2)), N'Exclude', N'CheckIn', NULL, NULL, NULL, NULL, NULL, 1, NULL, CAST(N'2024-02-09T10:24:00.520' AS DateTime))
GO
INSERT [dbo].[B02_BookingRoomDetails] ([B02_BookingRoom_ID], [BookingId], [HotelId], [CategoryId], [CheckInDate], [CheckOutDate], [Days], [NoOfBed], [NoofRooms], [NoofAdults], [NoofChilds], [ExtraBed], [DoubleOccupancy], [RoomCharge], [DoubleOccupancyCharge], [ExtraBedCharge], [RoomAmt], [DoubleOccupancyAmt], [ExtraBedamt], [TotalRoomAmt], [DiscountPer], [DisountAmount], [GrossAmount], [GStPer], [CGST], [SGST], [TotalGST], [TotalPayable], [GSTNature], [BookingStatus], [CancelRoom], [RefundPer], [RefundAmt], [CancelDate], [cancelBy], [IsActive], [EntryBy], [EntryDate]) VALUES (3, 1002, N'HTL82734', 23, CAST(N'2024-02-09' AS Date), CAST(N'2024-02-10' AS Date), 1, 2, 1, 1, NULL, 0, 0, CAST(2500.00 AS Decimal(18, 2)), CAST(200.00 AS Decimal(18, 2)), CAST(405.00 AS Decimal(18, 2)), CAST(2500.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(2500.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(2500.00 AS Decimal(18, 2)), CAST(12.00 AS Decimal(18, 2)), CAST(150.00 AS Decimal(18, 2)), CAST(150.00 AS Decimal(18, 2)), CAST(300.00 AS Decimal(18, 2)), CAST(2800.00 AS Decimal(18, 2)), N'Exclude', N'CheckIn', NULL, NULL, NULL, NULL, NULL, 1, NULL, CAST(N'2024-02-09T10:26:50.030' AS DateTime))
GO
INSERT [dbo].[B02_BookingRoomDetails] ([B02_BookingRoom_ID], [BookingId], [HotelId], [CategoryId], [CheckInDate], [CheckOutDate], [Days], [NoOfBed], [NoofRooms], [NoofAdults], [NoofChilds], [ExtraBed], [DoubleOccupancy], [RoomCharge], [DoubleOccupancyCharge], [ExtraBedCharge], [RoomAmt], [DoubleOccupancyAmt], [ExtraBedamt], [TotalRoomAmt], [DiscountPer], [DisountAmount], [GrossAmount], [GStPer], [CGST], [SGST], [TotalGST], [TotalPayable], [GSTNature], [BookingStatus], [CancelRoom], [RefundPer], [RefundAmt], [CancelDate], [cancelBy], [IsActive], [EntryBy], [EntryDate]) VALUES (4, 1002, N'HTL82734', 24, CAST(N'2024-02-10' AS Date), CAST(N'2024-02-15' AS Date), 1, 2, 1, 3, NULL, 1, 1, CAST(2000.00 AS Decimal(18, 2)), CAST(200.00 AS Decimal(18, 2)), CAST(330.00 AS Decimal(18, 2)), CAST(2000.00 AS Decimal(18, 2)), CAST(200.00 AS Decimal(18, 2)), CAST(330.00 AS Decimal(18, 2)), CAST(2530.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(2530.00 AS Decimal(18, 2)), CAST(12.00 AS Decimal(18, 2)), CAST(151.80 AS Decimal(18, 2)), CAST(151.80 AS Decimal(18, 2)), CAST(303.60 AS Decimal(18, 2)), CAST(2833.00 AS Decimal(18, 2)), N'Exclude', N'CheckIn', NULL, NULL, NULL, NULL, NULL, 1, NULL, CAST(N'2024-02-09T10:26:50.030' AS DateTime))
GO
INSERT [dbo].[B02_BookingRoomDetails] ([B02_BookingRoom_ID], [BookingId], [HotelId], [CategoryId], [CheckInDate], [CheckOutDate], [Days], [NoOfBed], [NoofRooms], [NoofAdults], [NoofChilds], [ExtraBed], [DoubleOccupancy], [RoomCharge], [DoubleOccupancyCharge], [ExtraBedCharge], [RoomAmt], [DoubleOccupancyAmt], [ExtraBedamt], [TotalRoomAmt], [DiscountPer], [DisountAmount], [GrossAmount], [GStPer], [CGST], [SGST], [TotalGST], [TotalPayable], [GSTNature], [BookingStatus], [CancelRoom], [RefundPer], [RefundAmt], [CancelDate], [cancelBy], [IsActive], [EntryBy], [EntryDate]) VALUES (5, 1003, N'HTL82734', 24, CAST(N'2024-02-09' AS Date), CAST(N'2024-02-10' AS Date), 1, 2, 1, 3, NULL, 1, 1, CAST(2000.00 AS Decimal(18, 2)), CAST(200.00 AS Decimal(18, 2)), CAST(330.00 AS Decimal(18, 2)), CAST(2000.00 AS Decimal(18, 2)), CAST(200.00 AS Decimal(18, 2)), CAST(330.00 AS Decimal(18, 2)), CAST(2530.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(2530.00 AS Decimal(18, 2)), CAST(12.00 AS Decimal(18, 2)), CAST(151.80 AS Decimal(18, 2)), CAST(151.80 AS Decimal(18, 2)), CAST(303.60 AS Decimal(18, 2)), CAST(2834.00 AS Decimal(18, 2)), N'Exclude', N'CheckIn', NULL, NULL, NULL, NULL, NULL, 1, NULL, CAST(N'2024-02-09T10:31:10.607' AS DateTime))
GO
INSERT [dbo].[B02_BookingRoomDetails] ([B02_BookingRoom_ID], [BookingId], [HotelId], [CategoryId], [CheckInDate], [CheckOutDate], [Days], [NoOfBed], [NoofRooms], [NoofAdults], [NoofChilds], [ExtraBed], [DoubleOccupancy], [RoomCharge], [DoubleOccupancyCharge], [ExtraBedCharge], [RoomAmt], [DoubleOccupancyAmt], [ExtraBedamt], [TotalRoomAmt], [DiscountPer], [DisountAmount], [GrossAmount], [GStPer], [CGST], [SGST], [TotalGST], [TotalPayable], [GSTNature], [BookingStatus], [CancelRoom], [RefundPer], [RefundAmt], [CancelDate], [cancelBy], [IsActive], [EntryBy], [EntryDate]) VALUES (6, 1004, N'HTL82734', 23, CAST(N'2024-02-14' AS Date), CAST(N'2024-02-16' AS Date), 2, 2, 2, 5, NULL, 1, 2, CAST(1500.00 AS Decimal(18, 2)), CAST(100.00 AS Decimal(18, 2)), CAST(50.00 AS Decimal(18, 2)), CAST(6000.00 AS Decimal(18, 2)), CAST(400.00 AS Decimal(18, 2)), CAST(100.00 AS Decimal(18, 2)), CAST(6500.00 AS Decimal(18, 2)), CAST(10.00 AS Decimal(18, 2)), CAST(640.00 AS Decimal(18, 2)), CAST(5860.00 AS Decimal(18, 2)), CAST(12.00 AS Decimal(18, 2)), CAST(351.60 AS Decimal(18, 2)), CAST(351.60 AS Decimal(18, 2)), CAST(703.20 AS Decimal(18, 2)), CAST(6563.00 AS Decimal(18, 2)), N'Exclude', N'CheckIn', NULL, NULL, NULL, NULL, NULL, 1, NULL, CAST(N'2024-02-14T11:17:27.433' AS DateTime))
GO
INSERT [dbo].[B02_BookingRoomDetails] ([B02_BookingRoom_ID], [BookingId], [HotelId], [CategoryId], [CheckInDate], [CheckOutDate], [Days], [NoOfBed], [NoofRooms], [NoofAdults], [NoofChilds], [ExtraBed], [DoubleOccupancy], [RoomCharge], [DoubleOccupancyCharge], [ExtraBedCharge], [RoomAmt], [DoubleOccupancyAmt], [ExtraBedamt], [TotalRoomAmt], [DiscountPer], [DisountAmount], [GrossAmount], [GStPer], [CGST], [SGST], [TotalGST], [TotalPayable], [GSTNature], [BookingStatus], [CancelRoom], [RefundPer], [RefundAmt], [CancelDate], [cancelBy], [IsActive], [EntryBy], [EntryDate]) VALUES (7, 1005, N'HTL82734', 23, CAST(N'2024-02-14' AS Date), CAST(N'2024-02-15' AS Date), 1, 2, 1, 3, NULL, 1, 1, CAST(2500.00 AS Decimal(18, 2)), CAST(200.00 AS Decimal(18, 2)), CAST(405.00 AS Decimal(18, 2)), CAST(2500.00 AS Decimal(18, 2)), CAST(200.00 AS Decimal(18, 2)), CAST(405.00 AS Decimal(18, 2)), CAST(3105.00 AS Decimal(18, 2)), CAST(10.00 AS Decimal(18, 2)), CAST(270.00 AS Decimal(18, 2)), CAST(2835.00 AS Decimal(18, 2)), CAST(12.00 AS Decimal(18, 2)), CAST(170.10 AS Decimal(18, 2)), CAST(170.10 AS Decimal(18, 2)), CAST(340.20 AS Decimal(18, 2)), CAST(3175.00 AS Decimal(18, 2)), N'Exclude', N'Booked', NULL, NULL, NULL, NULL, NULL, 1, NULL, CAST(N'2024-02-14T12:58:46.183' AS DateTime))
GO
INSERT [dbo].[B02_BookingRoomDetails] ([B02_BookingRoom_ID], [BookingId], [HotelId], [CategoryId], [CheckInDate], [CheckOutDate], [Days], [NoOfBed], [NoofRooms], [NoofAdults], [NoofChilds], [ExtraBed], [DoubleOccupancy], [RoomCharge], [DoubleOccupancyCharge], [ExtraBedCharge], [RoomAmt], [DoubleOccupancyAmt], [ExtraBedamt], [TotalRoomAmt], [DiscountPer], [DisountAmount], [GrossAmount], [GStPer], [CGST], [SGST], [TotalGST], [TotalPayable], [GSTNature], [BookingStatus], [CancelRoom], [RefundPer], [RefundAmt], [CancelDate], [cancelBy], [IsActive], [EntryBy], [EntryDate]) VALUES (8, 1006, N'HTL82734', 23, CAST(N'2024-02-14' AS Date), CAST(N'2024-02-15' AS Date), 1, 2, 3, 7, NULL, 1, 3, CAST(2500.00 AS Decimal(18, 2)), CAST(200.00 AS Decimal(18, 2)), CAST(405.00 AS Decimal(18, 2)), CAST(7500.00 AS Decimal(18, 2)), CAST(600.00 AS Decimal(18, 2)), CAST(405.00 AS Decimal(18, 2)), CAST(8505.00 AS Decimal(18, 2)), CAST(10.00 AS Decimal(18, 2)), CAST(810.00 AS Decimal(18, 2)), CAST(7695.00 AS Decimal(18, 2)), CAST(12.00 AS Decimal(18, 2)), CAST(461.70 AS Decimal(18, 2)), CAST(461.70 AS Decimal(18, 2)), CAST(923.40 AS Decimal(18, 2)), CAST(8618.00 AS Decimal(18, 2)), N'Exclude', N'CheckIn', NULL, NULL, NULL, NULL, NULL, 1, NULL, CAST(N'2024-02-14T13:08:21.977' AS DateTime))
GO
INSERT [dbo].[B02_BookingRoomDetails] ([B02_BookingRoom_ID], [BookingId], [HotelId], [CategoryId], [CheckInDate], [CheckOutDate], [Days], [NoOfBed], [NoofRooms], [NoofAdults], [NoofChilds], [ExtraBed], [DoubleOccupancy], [RoomCharge], [DoubleOccupancyCharge], [ExtraBedCharge], [RoomAmt], [DoubleOccupancyAmt], [ExtraBedamt], [TotalRoomAmt], [DiscountPer], [DisountAmount], [GrossAmount], [GStPer], [CGST], [SGST], [TotalGST], [TotalPayable], [GSTNature], [BookingStatus], [CancelRoom], [RefundPer], [RefundAmt], [CancelDate], [cancelBy], [IsActive], [EntryBy], [EntryDate]) VALUES (9, 1006, N'HTL82734', 24, CAST(N'2024-02-14' AS Date), CAST(N'2024-02-15' AS Date), 1, 2, 2, 2, NULL, 0, 0, CAST(2000.00 AS Decimal(18, 2)), CAST(200.00 AS Decimal(18, 2)), CAST(330.00 AS Decimal(18, 2)), CAST(4000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(4000.00 AS Decimal(18, 2)), CAST(10.00 AS Decimal(18, 2)), CAST(400.00 AS Decimal(18, 2)), CAST(3600.00 AS Decimal(18, 2)), CAST(12.00 AS Decimal(18, 2)), CAST(216.00 AS Decimal(18, 2)), CAST(216.00 AS Decimal(18, 2)), CAST(432.00 AS Decimal(18, 2)), CAST(4032.00 AS Decimal(18, 2)), N'Exclude', N'CheckIn', NULL, NULL, NULL, NULL, NULL, 1, NULL, CAST(N'2024-02-14T13:08:21.977' AS DateTime))
GO
SET IDENTITY_INSERT [dbo].[B02_BookingRoomDetails] OFF
GO
SET IDENTITY_INSERT [dbo].[B03_TransactionDetails] ON 
GO
INSERT [dbo].[B03_TransactionDetails] ([B03_Transaction_ID], [BookingId], [PaymentSourse], [NetPayable], [DiscountAmt], [PaidAmount], [DueAmount], [BillNo], [PaymentMode], [ResponseURL], [TransactionID], [TransactionDate], [TID], [TMode], [mihpayid], [hashResponce], [NameOnCard], [CardNo], [requestKey], [IsActive], [EntryBy], [EntryDate]) VALUES (1000, 1001, N'Room', CAST(5633.60 AS Decimal(18, 2)), NULL, CAST(634.00 AS Decimal(18, 2)), CAST(4999.60 AS Decimal(18, 2)), NULL, N'Cash', NULL, NULL, CAST(N'2024-02-09T10:24:00.520' AS DateTime), NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, CAST(N'2024-02-09T10:24:00.520' AS DateTime))
GO
INSERT [dbo].[B03_TransactionDetails] ([B03_Transaction_ID], [BookingId], [PaymentSourse], [NetPayable], [DiscountAmt], [PaidAmount], [DueAmount], [BillNo], [PaymentMode], [ResponseURL], [TransactionID], [TransactionDate], [TID], [TMode], [mihpayid], [hashResponce], [NameOnCard], [CardNo], [requestKey], [IsActive], [EntryBy], [EntryDate]) VALUES (1001, 1002, N'Room', CAST(5633.00 AS Decimal(18, 2)), NULL, CAST(0.00 AS Decimal(18, 2)), CAST(5633.00 AS Decimal(18, 2)), NULL, N'Cash', NULL, NULL, CAST(N'2024-02-09T10:26:50.030' AS DateTime), NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, CAST(N'2024-02-09T10:26:50.030' AS DateTime))
GO
INSERT [dbo].[B03_TransactionDetails] ([B03_Transaction_ID], [BookingId], [PaymentSourse], [NetPayable], [DiscountAmt], [PaidAmount], [DueAmount], [BillNo], [PaymentMode], [ResponseURL], [TransactionID], [TransactionDate], [TID], [TMode], [mihpayid], [hashResponce], [NameOnCard], [CardNo], [requestKey], [IsActive], [EntryBy], [EntryDate]) VALUES (1002, 1003, N'Room', CAST(2834.00 AS Decimal(18, 2)), NULL, CAST(834.00 AS Decimal(18, 2)), CAST(2000.00 AS Decimal(18, 2)), NULL, N'IMPS', NULL, N'6498', CAST(N'2024-02-09T10:31:10.607' AS DateTime), NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, CAST(N'2024-02-09T10:31:10.607' AS DateTime))
GO
INSERT [dbo].[B03_TransactionDetails] ([B03_Transaction_ID], [BookingId], [PaymentSourse], [NetPayable], [DiscountAmt], [PaidAmount], [DueAmount], [BillNo], [PaymentMode], [ResponseURL], [TransactionID], [TransactionDate], [TID], [TMode], [mihpayid], [hashResponce], [NameOnCard], [CardNo], [requestKey], [IsActive], [EntryBy], [EntryDate]) VALUES (1003, 1004, N'Room', CAST(6563.00 AS Decimal(18, 2)), NULL, CAST(0.00 AS Decimal(18, 2)), CAST(6563.00 AS Decimal(18, 2)), NULL, N'Cash', NULL, NULL, CAST(N'2024-02-14T11:17:27.437' AS DateTime), NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, CAST(N'2024-02-14T11:17:27.437' AS DateTime))
GO
INSERT [dbo].[B03_TransactionDetails] ([B03_Transaction_ID], [BookingId], [PaymentSourse], [NetPayable], [DiscountAmt], [PaidAmount], [DueAmount], [BillNo], [PaymentMode], [ResponseURL], [TransactionID], [TransactionDate], [TID], [TMode], [mihpayid], [hashResponce], [NameOnCard], [CardNo], [requestKey], [IsActive], [EntryBy], [EntryDate]) VALUES (1004, 1005, N'Room', CAST(3175.00 AS Decimal(18, 2)), NULL, CAST(175.00 AS Decimal(18, 2)), CAST(3000.00 AS Decimal(18, 2)), NULL, N'Cash', NULL, NULL, CAST(N'2024-02-14T12:58:46.183' AS DateTime), NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, CAST(N'2024-02-14T12:58:46.183' AS DateTime))
GO
INSERT [dbo].[B03_TransactionDetails] ([B03_Transaction_ID], [BookingId], [PaymentSourse], [NetPayable], [DiscountAmt], [PaidAmount], [DueAmount], [BillNo], [PaymentMode], [ResponseURL], [TransactionID], [TransactionDate], [TID], [TMode], [mihpayid], [hashResponce], [NameOnCard], [CardNo], [requestKey], [IsActive], [EntryBy], [EntryDate]) VALUES (1005, 1006, N'Room', CAST(12650.00 AS Decimal(18, 2)), NULL, CAST(0.00 AS Decimal(18, 2)), CAST(12650.00 AS Decimal(18, 2)), NULL, N'Cash', NULL, NULL, CAST(N'2024-02-14T13:08:21.977' AS DateTime), NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, CAST(N'2024-02-14T13:08:21.977' AS DateTime))
GO
SET IDENTITY_INSERT [dbo].[B03_TransactionDetails] OFF
GO
SET IDENTITY_INSERT [dbo].[B04_ChickInDetails] ON 
GO
INSERT [dbo].[B04_ChickInDetails] ([B04_ChickIn_ID], [BookingId], [HotelId], [CategoryId], [CheckInDate], [CheckOutDate], [UpdateStatus], [UpdateDate], [NoOfDays], [RoomNo], [BookingStatus], [NoofAdults], [NoofChilds], [ExtraBed], [RoomChargesPerDay], [DoubleOccupancyPer], [ExtraBedPricePer], [TotalRoomCharge], [DiscountPer], [DisountAmount_Per], [DisountAmount], [GrossAmount], [GStPer], [GStAmount], [CGST], [SGST], [TotalGST], [TotalPayable], [GSTNature], [IsActive], [EntryBy], [EntryDate]) VALUES (1, 1001, N'HTL82734', 24, CAST(N'2024-02-09T00:00:00.000' AS DateTime), CAST(N'2024-02-11T00:00:00.000' AS DateTime), NULL, NULL, 1, N'107', N'CheckIn', 3, NULL, 1, CAST(2000.00 AS Decimal(18, 2)), CAST(200.00 AS Decimal(18, 2)), CAST(330.00 AS Decimal(18, 2)), CAST(2530.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(2530.00 AS Decimal(18, 2)), CAST(12.00 AS Decimal(18, 2)), CAST(303.60 AS Decimal(18, 2)), CAST(151.80 AS Decimal(18, 2)), CAST(151.80 AS Decimal(18, 2)), CAST(303.60 AS Decimal(18, 2)), CAST(2834.00 AS Decimal(18, 2)), N'Exclude', 1, NULL, CAST(N'2024-02-13T17:42:40.880' AS DateTime))
GO
INSERT [dbo].[B04_ChickInDetails] ([B04_ChickIn_ID], [BookingId], [HotelId], [CategoryId], [CheckInDate], [CheckOutDate], [UpdateStatus], [UpdateDate], [NoOfDays], [RoomNo], [BookingStatus], [NoofAdults], [NoofChilds], [ExtraBed], [RoomChargesPerDay], [DoubleOccupancyPer], [ExtraBedPricePer], [TotalRoomCharge], [DiscountPer], [DisountAmount_Per], [DisountAmount], [GrossAmount], [GStPer], [GStAmount], [CGST], [SGST], [TotalGST], [TotalPayable], [GSTNature], [IsActive], [EntryBy], [EntryDate]) VALUES (2, 1001, N'HTL82734', 23, CAST(N'2024-02-09T00:00:00.000' AS DateTime), CAST(N'2024-02-10T00:00:00.000' AS DateTime), NULL, NULL, 1, N'101', N'CheckIn', 2, NULL, 0, CAST(2500.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(2500.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(2500.00 AS Decimal(18, 2)), CAST(12.00 AS Decimal(18, 2)), CAST(300.00 AS Decimal(18, 2)), CAST(150.00 AS Decimal(18, 2)), CAST(150.00 AS Decimal(18, 2)), CAST(300.00 AS Decimal(18, 2)), CAST(2800.00 AS Decimal(18, 2)), N'Exclude', 1, NULL, CAST(N'2024-02-14T10:36:25.080' AS DateTime))
GO
INSERT [dbo].[B04_ChickInDetails] ([B04_ChickIn_ID], [BookingId], [HotelId], [CategoryId], [CheckInDate], [CheckOutDate], [UpdateStatus], [UpdateDate], [NoOfDays], [RoomNo], [BookingStatus], [NoofAdults], [NoofChilds], [ExtraBed], [RoomChargesPerDay], [DoubleOccupancyPer], [ExtraBedPricePer], [TotalRoomCharge], [DiscountPer], [DisountAmount_Per], [DisountAmount], [GrossAmount], [GStPer], [GStAmount], [CGST], [SGST], [TotalGST], [TotalPayable], [GSTNature], [IsActive], [EntryBy], [EntryDate]) VALUES (4, 1002, N'HTL82734', 24, CAST(N'2024-02-10T00:00:00.000' AS DateTime), CAST(N'2024-02-15T00:00:00.000' AS DateTime), NULL, NULL, 1, N'112', N'CheckIn', 3, NULL, 1, CAST(2000.00 AS Decimal(18, 2)), CAST(200.00 AS Decimal(18, 2)), CAST(330.00 AS Decimal(18, 2)), CAST(2530.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(2530.00 AS Decimal(18, 2)), CAST(12.00 AS Decimal(18, 2)), CAST(303.60 AS Decimal(18, 2)), CAST(151.80 AS Decimal(18, 2)), CAST(151.80 AS Decimal(18, 2)), CAST(303.60 AS Decimal(18, 2)), CAST(2834.00 AS Decimal(18, 2)), N'Exclude', 1, NULL, CAST(N'2024-02-14T11:12:20.143' AS DateTime))
GO
INSERT [dbo].[B04_ChickInDetails] ([B04_ChickIn_ID], [BookingId], [HotelId], [CategoryId], [CheckInDate], [CheckOutDate], [UpdateStatus], [UpdateDate], [NoOfDays], [RoomNo], [BookingStatus], [NoofAdults], [NoofChilds], [ExtraBed], [RoomChargesPerDay], [DoubleOccupancyPer], [ExtraBedPricePer], [TotalRoomCharge], [DiscountPer], [DisountAmount_Per], [DisountAmount], [GrossAmount], [GStPer], [GStAmount], [CGST], [SGST], [TotalGST], [TotalPayable], [GSTNature], [IsActive], [EntryBy], [EntryDate]) VALUES (5, 1002, N'HTL82734', 23, CAST(N'2024-02-09T00:00:00.000' AS DateTime), CAST(N'2024-02-10T00:00:00.000' AS DateTime), NULL, NULL, 1, N'105', N'CheckIn', 1, NULL, 0, CAST(2500.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(2500.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(2500.00 AS Decimal(18, 2)), CAST(12.00 AS Decimal(18, 2)), CAST(300.00 AS Decimal(18, 2)), CAST(150.00 AS Decimal(18, 2)), CAST(150.00 AS Decimal(18, 2)), CAST(300.00 AS Decimal(18, 2)), CAST(2800.00 AS Decimal(18, 2)), N'Exclude', 1, NULL, CAST(N'2024-02-14T11:12:20.143' AS DateTime))
GO
INSERT [dbo].[B04_ChickInDetails] ([B04_ChickIn_ID], [BookingId], [HotelId], [CategoryId], [CheckInDate], [CheckOutDate], [UpdateStatus], [UpdateDate], [NoOfDays], [RoomNo], [BookingStatus], [NoofAdults], [NoofChilds], [ExtraBed], [RoomChargesPerDay], [DoubleOccupancyPer], [ExtraBedPricePer], [TotalRoomCharge], [DiscountPer], [DisountAmount_Per], [DisountAmount], [GrossAmount], [GStPer], [GStAmount], [CGST], [SGST], [TotalGST], [TotalPayable], [GSTNature], [IsActive], [EntryBy], [EntryDate]) VALUES (6, 1003, N'HTL82734', 24, CAST(N'2024-02-09T00:00:00.000' AS DateTime), CAST(N'2024-02-10T00:00:00.000' AS DateTime), NULL, NULL, 1, N'116', N'CheckIn', 2, NULL, 0, CAST(2000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(2000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(2000.00 AS Decimal(18, 2)), CAST(12.00 AS Decimal(18, 2)), CAST(240.00 AS Decimal(18, 2)), CAST(120.00 AS Decimal(18, 2)), CAST(120.00 AS Decimal(18, 2)), CAST(240.00 AS Decimal(18, 2)), CAST(2240.00 AS Decimal(18, 2)), N'Exclude', 1, NULL, CAST(N'2024-02-14T11:15:55.413' AS DateTime))
GO
INSERT [dbo].[B04_ChickInDetails] ([B04_ChickIn_ID], [BookingId], [HotelId], [CategoryId], [CheckInDate], [CheckOutDate], [UpdateStatus], [UpdateDate], [NoOfDays], [RoomNo], [BookingStatus], [NoofAdults], [NoofChilds], [ExtraBed], [RoomChargesPerDay], [DoubleOccupancyPer], [ExtraBedPricePer], [TotalRoomCharge], [DiscountPer], [DisountAmount_Per], [DisountAmount], [GrossAmount], [GStPer], [GStAmount], [CGST], [SGST], [TotalGST], [TotalPayable], [GSTNature], [IsActive], [EntryBy], [EntryDate]) VALUES (7, 1004, N'HTL82734', 23, CAST(N'2024-02-14T00:00:00.000' AS DateTime), CAST(N'2024-02-16T00:00:00.000' AS DateTime), NULL, NULL, 2, N'203', N'CheckIn', 2, NULL, 0, CAST(1500.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(3000.00 AS Decimal(18, 2)), CAST(10.00 AS Decimal(18, 2)), CAST(150.00 AS Decimal(18, 2)), CAST(300.00 AS Decimal(18, 2)), CAST(2700.00 AS Decimal(18, 2)), CAST(12.00 AS Decimal(18, 2)), CAST(162.00 AS Decimal(18, 2)), CAST(162.00 AS Decimal(18, 2)), CAST(162.00 AS Decimal(18, 2)), CAST(324.00 AS Decimal(18, 2)), CAST(3024.00 AS Decimal(18, 2)), N'Exclude', 1, NULL, CAST(N'2024-02-14T13:17:53.273' AS DateTime))
GO
INSERT [dbo].[B04_ChickInDetails] ([B04_ChickIn_ID], [BookingId], [HotelId], [CategoryId], [CheckInDate], [CheckOutDate], [UpdateStatus], [UpdateDate], [NoOfDays], [RoomNo], [BookingStatus], [NoofAdults], [NoofChilds], [ExtraBed], [RoomChargesPerDay], [DoubleOccupancyPer], [ExtraBedPricePer], [TotalRoomCharge], [DiscountPer], [DisountAmount_Per], [DisountAmount], [GrossAmount], [GStPer], [GStAmount], [CGST], [SGST], [TotalGST], [TotalPayable], [GSTNature], [IsActive], [EntryBy], [EntryDate]) VALUES (8, 1004, N'HTL82734', 23, CAST(N'2024-02-14T00:00:00.000' AS DateTime), CAST(N'2024-02-16T00:00:00.000' AS DateTime), NULL, NULL, 2, N'301', N'CheckIn', 3, NULL, 1, CAST(1500.00 AS Decimal(18, 2)), CAST(100.00 AS Decimal(18, 2)), CAST(50.00 AS Decimal(18, 2)), CAST(3300.00 AS Decimal(18, 2)), CAST(10.00 AS Decimal(18, 2)), CAST(160.00 AS Decimal(18, 2)), CAST(320.00 AS Decimal(18, 2)), CAST(2980.00 AS Decimal(18, 2)), CAST(12.00 AS Decimal(18, 2)), CAST(178.80 AS Decimal(18, 2)), CAST(178.80 AS Decimal(18, 2)), CAST(178.80 AS Decimal(18, 2)), CAST(357.60 AS Decimal(18, 2)), CAST(3338.00 AS Decimal(18, 2)), N'Exclude', 1, NULL, CAST(N'2024-02-14T13:17:53.273' AS DateTime))
GO
INSERT [dbo].[B04_ChickInDetails] ([B04_ChickIn_ID], [BookingId], [HotelId], [CategoryId], [CheckInDate], [CheckOutDate], [UpdateStatus], [UpdateDate], [NoOfDays], [RoomNo], [BookingStatus], [NoofAdults], [NoofChilds], [ExtraBed], [RoomChargesPerDay], [DoubleOccupancyPer], [ExtraBedPricePer], [TotalRoomCharge], [DiscountPer], [DisountAmount_Per], [DisountAmount], [GrossAmount], [GStPer], [GStAmount], [CGST], [SGST], [TotalGST], [TotalPayable], [GSTNature], [IsActive], [EntryBy], [EntryDate]) VALUES (9, 1006, N'HTL82734', 24, CAST(N'2024-02-14T00:00:00.000' AS DateTime), CAST(N'2024-02-15T00:00:00.000' AS DateTime), NULL, NULL, 1, N'109', N'CheckIn', 2, NULL, 0, CAST(2000.00 AS Decimal(18, 2)), CAST(200.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(2200.00 AS Decimal(18, 2)), CAST(10.00 AS Decimal(18, 2)), CAST(220.00 AS Decimal(18, 2)), CAST(220.00 AS Decimal(18, 2)), CAST(1980.00 AS Decimal(18, 2)), CAST(12.00 AS Decimal(18, 2)), CAST(237.60 AS Decimal(18, 2)), CAST(118.80 AS Decimal(18, 2)), CAST(118.80 AS Decimal(18, 2)), CAST(237.60 AS Decimal(18, 2)), CAST(2218.00 AS Decimal(18, 2)), N'Exclude', 1, NULL, CAST(N'2024-02-14T13:32:53.540' AS DateTime))
GO
INSERT [dbo].[B04_ChickInDetails] ([B04_ChickIn_ID], [BookingId], [HotelId], [CategoryId], [CheckInDate], [CheckOutDate], [UpdateStatus], [UpdateDate], [NoOfDays], [RoomNo], [BookingStatus], [NoofAdults], [NoofChilds], [ExtraBed], [RoomChargesPerDay], [DoubleOccupancyPer], [ExtraBedPricePer], [TotalRoomCharge], [DiscountPer], [DisountAmount_Per], [DisountAmount], [GrossAmount], [GStPer], [GStAmount], [CGST], [SGST], [TotalGST], [TotalPayable], [GSTNature], [IsActive], [EntryBy], [EntryDate]) VALUES (10, 1006, N'HTL82734', 24, CAST(N'2024-02-14T00:00:00.000' AS DateTime), CAST(N'2024-02-15T00:00:00.000' AS DateTime), NULL, NULL, 1, N'110', N'CheckIn', 2, NULL, 0, CAST(2000.00 AS Decimal(18, 2)), CAST(200.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(2200.00 AS Decimal(18, 2)), CAST(10.00 AS Decimal(18, 2)), CAST(220.00 AS Decimal(18, 2)), CAST(220.00 AS Decimal(18, 2)), CAST(1980.00 AS Decimal(18, 2)), CAST(12.00 AS Decimal(18, 2)), CAST(237.60 AS Decimal(18, 2)), CAST(118.80 AS Decimal(18, 2)), CAST(118.80 AS Decimal(18, 2)), CAST(237.60 AS Decimal(18, 2)), CAST(2218.00 AS Decimal(18, 2)), N'Exclude', 1, NULL, CAST(N'2024-02-14T13:32:53.540' AS DateTime))
GO
INSERT [dbo].[B04_ChickInDetails] ([B04_ChickIn_ID], [BookingId], [HotelId], [CategoryId], [CheckInDate], [CheckOutDate], [UpdateStatus], [UpdateDate], [NoOfDays], [RoomNo], [BookingStatus], [NoofAdults], [NoofChilds], [ExtraBed], [RoomChargesPerDay], [DoubleOccupancyPer], [ExtraBedPricePer], [TotalRoomCharge], [DiscountPer], [DisountAmount_Per], [DisountAmount], [GrossAmount], [GStPer], [GStAmount], [CGST], [SGST], [TotalGST], [TotalPayable], [GSTNature], [IsActive], [EntryBy], [EntryDate]) VALUES (11, 1006, N'HTL82734', 23, CAST(N'2024-02-14T00:00:00.000' AS DateTime), CAST(N'2024-02-15T00:00:00.000' AS DateTime), NULL, NULL, 1, N'102', N'CheckIn', 2, NULL, 0, CAST(2500.00 AS Decimal(18, 2)), CAST(200.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(2700.00 AS Decimal(18, 2)), CAST(10.00 AS Decimal(18, 2)), CAST(270.00 AS Decimal(18, 2)), CAST(270.00 AS Decimal(18, 2)), CAST(2430.00 AS Decimal(18, 2)), CAST(12.00 AS Decimal(18, 2)), CAST(291.60 AS Decimal(18, 2)), CAST(145.80 AS Decimal(18, 2)), CAST(145.80 AS Decimal(18, 2)), CAST(291.60 AS Decimal(18, 2)), CAST(2722.00 AS Decimal(18, 2)), N'Exclude', 1, NULL, CAST(N'2024-02-14T13:32:53.540' AS DateTime))
GO
INSERT [dbo].[B04_ChickInDetails] ([B04_ChickIn_ID], [BookingId], [HotelId], [CategoryId], [CheckInDate], [CheckOutDate], [UpdateStatus], [UpdateDate], [NoOfDays], [RoomNo], [BookingStatus], [NoofAdults], [NoofChilds], [ExtraBed], [RoomChargesPerDay], [DoubleOccupancyPer], [ExtraBedPricePer], [TotalRoomCharge], [DiscountPer], [DisountAmount_Per], [DisountAmount], [GrossAmount], [GStPer], [GStAmount], [CGST], [SGST], [TotalGST], [TotalPayable], [GSTNature], [IsActive], [EntryBy], [EntryDate]) VALUES (12, 1006, N'HTL82734', 23, CAST(N'2024-02-14T00:00:00.000' AS DateTime), CAST(N'2024-02-15T00:00:00.000' AS DateTime), NULL, NULL, 1, N'103', N'CheckIn', 2, NULL, 0, CAST(2500.00 AS Decimal(18, 2)), CAST(200.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(18, 2)), CAST(2700.00 AS Decimal(18, 2)), CAST(10.00 AS Decimal(18, 2)), CAST(270.00 AS Decimal(18, 2)), CAST(270.00 AS Decimal(18, 2)), CAST(2430.00 AS Decimal(18, 2)), CAST(12.00 AS Decimal(18, 2)), CAST(291.60 AS Decimal(18, 2)), CAST(145.80 AS Decimal(18, 2)), CAST(145.80 AS Decimal(18, 2)), CAST(291.60 AS Decimal(18, 2)), CAST(2722.00 AS Decimal(18, 2)), N'Exclude', 1, NULL, CAST(N'2024-02-14T13:32:53.540' AS DateTime))
GO
INSERT [dbo].[B04_ChickInDetails] ([B04_ChickIn_ID], [BookingId], [HotelId], [CategoryId], [CheckInDate], [CheckOutDate], [UpdateStatus], [UpdateDate], [NoOfDays], [RoomNo], [BookingStatus], [NoofAdults], [NoofChilds], [ExtraBed], [RoomChargesPerDay], [DoubleOccupancyPer], [ExtraBedPricePer], [TotalRoomCharge], [DiscountPer], [DisountAmount_Per], [DisountAmount], [GrossAmount], [GStPer], [GStAmount], [CGST], [SGST], [TotalGST], [TotalPayable], [GSTNature], [IsActive], [EntryBy], [EntryDate]) VALUES (13, 1006, N'HTL82734', 23, CAST(N'2024-02-14T00:00:00.000' AS DateTime), CAST(N'2024-02-15T00:00:00.000' AS DateTime), NULL, NULL, 1, N'104', N'CheckIn', 3, NULL, 1, CAST(2500.00 AS Decimal(18, 2)), CAST(200.00 AS Decimal(18, 2)), CAST(405.00 AS Decimal(18, 2)), CAST(3105.00 AS Decimal(18, 2)), CAST(10.00 AS Decimal(18, 2)), CAST(270.00 AS Decimal(18, 2)), CAST(270.00 AS Decimal(18, 2)), CAST(2835.00 AS Decimal(18, 2)), CAST(12.00 AS Decimal(18, 2)), CAST(340.20 AS Decimal(18, 2)), CAST(170.10 AS Decimal(18, 2)), CAST(170.10 AS Decimal(18, 2)), CAST(340.20 AS Decimal(18, 2)), CAST(3175.00 AS Decimal(18, 2)), N'Exclude', 1, NULL, CAST(N'2024-02-14T13:32:53.540' AS DateTime))
GO
SET IDENTITY_INSERT [dbo].[B04_ChickInDetails] OFF
GO
SET IDENTITY_INSERT [dbo].[CityMaster] ON 
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (1, 1, N'Agra', 0, CAST(N'2024-03-18T15:38:05.863' AS DateTime), N'AGR')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (2, 1, N'Ayodhya', 0, NULL, N'AYO')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (3, 1, N'Balrampur', 0, CAST(N'2019-07-05T17:43:11.110' AS DateTime), N'BAL')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (4, 1, N'Bareilly', 0, CAST(N'2019-07-05T17:43:34.640' AS DateTime), N'BAR')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (5, 1, N'Chitrakoot', 0, CAST(N'2019-07-05T17:44:00.890' AS DateTime), N'CHI')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (6, 1, N'Fatehpur Sikri, Agra', 0, NULL, N'FAT')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (7, 1, N'Haridwar', 0, CAST(N'2019-07-05T17:45:01.110' AS DateTime), N'HAR')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (8, 1, N'Jhansi', 0, CAST(N'2019-07-05T17:45:21.113' AS DateTime), N'JHA')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (9, 1, N'Kannauj', 0, CAST(N'2019-07-05T17:45:31.830' AS DateTime), N'KAN')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (10, 1, N'Kushinagar', 0, CAST(N'2019-07-05T17:46:06.817' AS DateTime), N'KUS')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (11, 1, N'Lucknow', 0, CAST(N'2019-07-05T17:46:17.097' AS DateTime), N'LKO')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (12, 1, N'Mirzapur', 0, CAST(N'2019-07-05T17:46:40.457' AS DateTime), N'MIR')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (13, 1, N'Moradabad', 0, CAST(N'2019-07-05T17:46:50.737' AS DateTime), N'MOR')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (14, 1, N'Nawabganj', 0, CAST(N'2019-07-05T17:47:01.443' AS DateTime), N'NAW')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (15, 1, N'Prayagraj', 0, NULL, N'ALL')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (16, 1, N'Raebareli', 0, NULL, N'RAI')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (17, 1, N'Sarnath, Varanasi', 0, NULL, N'SAR')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (18, 1, N'Shahjahanpur', 0, CAST(N'2019-07-05T17:48:27.507' AS DateTime), N'SHA')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (19, 1, N'Shravasti', 0, CAST(N'2019-07-05T17:48:39.630' AS DateTime), N'SHR')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (20, 1, N'Varanasi', 0, CAST(N'2019-07-05T17:48:49.647' AS DateTime), N'VAR')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (21, 1, N'Budaun', 0, NULL, N'BAD')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (29, 1, N'Sumer Singh Qila , Etawah', 0, CAST(N'2020-09-11T14:10:44.697' AS DateTime), N'ETW')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (30, 1, N'Sankisa, Farrukhabad', 0, CAST(N'2020-09-11T14:11:27.017' AS DateTime), N'FRK')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (31, 1, N'Ghazipur', 0, CAST(N'2020-09-11T14:22:17.593' AS DateTime), N'GHZ')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (32, 1, N'DohriGhat , Mau', 0, CAST(N'2020-09-11T14:25:07.103' AS DateTime), N'MAU')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (36, 1, N'Bithoor , Kanpur ', 0, CAST(N'2020-09-11T14:45:14.927' AS DateTime), N'BTH')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (37, 1, N'Sonauli', 0, CAST(N'2020-09-11T14:51:04.847' AS DateTime), N'MHJ')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (39, 1, N'Garhmukteshwar', 0, CAST(N'2021-02-07T22:07:52.413' AS DateTime), N'GZH')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (40, 1, N'Vindhyachal', 0, CAST(N'2021-02-07T22:11:22.137' AS DateTime), N'MIR')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (41, 1, N'Neemsar', 0, CAST(N'2021-02-07T22:12:44.607' AS DateTime), N'MIR')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (42, 1, N'Gorakhpur', 0, CAST(N'2024-03-12T18:56:12.057' AS DateTime), N'GKP')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (43, 1, N'Kanpur', 0, CAST(N'2021-12-07T13:21:04.493' AS DateTime), NULL)
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (44, 1, N'Bahraich', 0, CAST(N'2021-12-07T13:21:04.493' AS DateTime), NULL)
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (45, 1, N'Balrampur', 1, CAST(N'2021-12-07T15:09:38.217' AS DateTime), NULL)
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (46, 1, N'Ballia', 0, CAST(N'2021-12-07T15:09:38.217' AS DateTime), NULL)
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (47, 1, N'Basti', 0, CAST(N'2021-12-08T10:32:00.687' AS DateTime), NULL)
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (50, 1, N'TESTING11', 0, CAST(N'2024-03-18T12:16:22.253' AS DateTime), N'TTT11')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (51, 1, N'TESTING', 0, CAST(N'2024-03-18T12:16:33.690' AS DateTime), N'TTT')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (52, 1, N'TESTING', NULL, CAST(N'2024-03-12T14:18:04.777' AS DateTime), N'TTT')
GO
INSERT [dbo].[CityMaster] ([ID], [StateId], [CityName], [IsDeleted], [EntryDate], [UnitAbbr]) VALUES (53, 1, N'Mathura', 0, CAST(N'2024-03-18T15:37:28.730' AS DateTime), N'MTJ')
GO
SET IDENTITY_INSERT [dbo].[CityMaster] OFF
GO
INSERT [dbo].[GSTMaster] ([GSTID], [StartAmt], [EndAmt], [GSTPer]) VALUES (1, CAST(1001.00 AS Decimal(18, 2)), CAST(5000.00 AS Decimal(18, 2)), CAST(9.00 AS Decimal(18, 2)))
GO
INSERT [dbo].[GSTMaster] ([GSTID], [StartAmt], [EndAmt], [GSTPer]) VALUES (101, CAST(0.00 AS Decimal(18, 2)), CAST(1000.00 AS Decimal(18, 2)), CAST(5.00 AS Decimal(18, 2)))
GO
INSERT [dbo].[GSTMaster] ([GSTID], [StartAmt], [EndAmt], [GSTPer]) VALUES (102, CAST(5001.00 AS Decimal(18, 2)), CAST(10000.00 AS Decimal(18, 2)), CAST(18.00 AS Decimal(18, 2)))
GO
INSERT [dbo].[GSTMaster] ([GSTID], [StartAmt], [EndAmt], [GSTPer]) VALUES (103, NULL, NULL, NULL)
GO
INSERT [dbo].[GSTMaster] ([GSTID], [StartAmt], [EndAmt], [GSTPer]) VALUES (104, CAST(45345.00 AS Decimal(18, 2)), CAST(34353.00 AS Decimal(18, 2)), CAST(444.00 AS Decimal(18, 2)))
GO
SET IDENTITY_INSERT [dbo].[InvoiceNotbl] ON 
GO
INSERT [dbo].[InvoiceNotbl] ([pk_InvoiceNoid], [Invoiceno], [RestaurentInvoiceno], [RBSno], [Billno], [GRegNo], [BanquetBookinInvoice], [AgentSrNo]) VALUES (1, 0, 0, 7, 0, 0, 0, 0)
GO
SET IDENTITY_INSERT [dbo].[InvoiceNotbl] OFF
GO
SET IDENTITY_INSERT [dbo].[Login] ON 
GO
INSERT [dbo].[Login] ([USER_Id], [UserName], [Password], [M_Role_Id], [HotelId], [LastLoginDate], [Created_By], [Created_Date], [Is_Active], [OPT]) VALUES (3, N'9415793918', N'123456', 3, NULL, NULL, -1, CAST(N'2024-02-14T13:08:21.977' AS DateTime), 1, NULL)
GO
INSERT [dbo].[Login] ([USER_Id], [UserName], [Password], [M_Role_Id], [HotelId], [LastLoginDate], [Created_By], [Created_Date], [Is_Active], [OPT]) VALUES (1, N'Admin', N'ok', 1, N'', NULL, NULL, CAST(N'2024-02-09T17:38:26.813' AS DateTime), 1, NULL)
GO
INSERT [dbo].[Login] ([USER_Id], [UserName], [Password], [M_Role_Id], [HotelId], [LastLoginDate], [Created_By], [Created_Date], [Is_Active], [OPT]) VALUES (2, N'gomti@upstdc.co.in', N'ok', 2, N'HTL82734', NULL, NULL, CAST(N'2024-02-09T17:38:26.813' AS DateTime), 1, NULL)
GO
SET IDENTITY_INSERT [dbo].[Login] OFF
GO
SET IDENTITY_INSERT [dbo].[RateMaster] ON 
GO
INSERT [dbo].[RateMaster] ([RateID], [HotelId], [CategoryId], [PricePerDay], [PriceDifference], [ExtraBedPercentage], [RateStartDate], [RateEndDate], [IsActive], [EntryBy], [EntryDate], [ExtraBadPriceMode]) VALUES (1, N'HTL82734', 23, CAST(2500.00 AS Decimal(18, 2)), CAST(200.00 AS Decimal(18, 2)), CAST(0.1500 AS Decimal(18, 4)), CAST(N'2024-01-01' AS Date), CAST(N'2024-02-29' AS Date), 1, N'system', CAST(N'2024-02-06T14:16:45.563' AS DateTime), N'P')
GO
INSERT [dbo].[RateMaster] ([RateID], [HotelId], [CategoryId], [PricePerDay], [PriceDifference], [ExtraBedPercentage], [RateStartDate], [RateEndDate], [IsActive], [EntryBy], [EntryDate], [ExtraBadPriceMode]) VALUES (2, N'HTL82734', 24, CAST(2000.00 AS Decimal(18, 2)), CAST(200.00 AS Decimal(18, 2)), CAST(1500.0000 AS Decimal(18, 4)), CAST(N'2024-01-01' AS Date), CAST(N'2024-02-29' AS Date), 1, N'1', CAST(N'2024-03-20T12:22:48.470' AS DateTime), N'A')
GO
INSERT [dbo].[RateMaster] ([RateID], [HotelId], [CategoryId], [PricePerDay], [PriceDifference], [ExtraBedPercentage], [RateStartDate], [RateEndDate], [IsActive], [EntryBy], [EntryDate], [ExtraBadPriceMode]) VALUES (3, N'HTL82734', 23, CAST(2600.00 AS Decimal(18, 2)), CAST(200.00 AS Decimal(18, 2)), CAST(0.1500 AS Decimal(18, 4)), CAST(N'2024-03-01' AS Date), CAST(N'2024-03-31' AS Date), 1, N'system', CAST(N'2024-02-06T14:16:45.563' AS DateTime), N'P')
GO
INSERT [dbo].[RateMaster] ([RateID], [HotelId], [CategoryId], [PricePerDay], [PriceDifference], [ExtraBedPercentage], [RateStartDate], [RateEndDate], [IsActive], [EntryBy], [EntryDate], [ExtraBadPriceMode]) VALUES (4, N'HTL82734', 24, CAST(2100.00 AS Decimal(18, 2)), CAST(200.00 AS Decimal(18, 2)), CAST(0.1500 AS Decimal(18, 4)), CAST(N'2024-03-01' AS Date), CAST(N'2024-03-31' AS Date), 1, N'system', CAST(N'2024-03-18T13:12:08.720' AS DateTime), N'P')
GO
INSERT [dbo].[RateMaster] ([RateID], [HotelId], [CategoryId], [PricePerDay], [PriceDifference], [ExtraBedPercentage], [RateStartDate], [RateEndDate], [IsActive], [EntryBy], [EntryDate], [ExtraBadPriceMode]) VALUES (5, N'AYO66', 139, CAST(25000.00 AS Decimal(18, 2)), CAST(1000.00 AS Decimal(18, 2)), CAST(0.5000 AS Decimal(18, 4)), CAST(N'2024-03-18' AS Date), CAST(N'2024-03-18' AS Date), 1, N'system', CAST(N'2024-03-18T12:14:29.060' AS DateTime), N'P')
GO
INSERT [dbo].[RateMaster] ([RateID], [HotelId], [CategoryId], [PricePerDay], [PriceDifference], [ExtraBedPercentage], [RateStartDate], [RateEndDate], [IsActive], [EntryBy], [EntryDate], [ExtraBadPriceMode]) VALUES (6, N'106', 177, CAST(3000.00 AS Decimal(18, 2)), CAST(1000.00 AS Decimal(18, 2)), CAST(0.2000 AS Decimal(18, 4)), CAST(N'2024-03-18' AS Date), CAST(N'2024-03-19' AS Date), 1, N'system', CAST(N'2024-03-18T13:38:49.000' AS DateTime), N'P')
GO
INSERT [dbo].[RateMaster] ([RateID], [HotelId], [CategoryId], [PricePerDay], [PriceDifference], [ExtraBedPercentage], [RateStartDate], [RateEndDate], [IsActive], [EntryBy], [EntryDate], [ExtraBadPriceMode]) VALUES (16, N'AYO66', 140, CAST(2200.00 AS Decimal(18, 2)), CAST(2000.00 AS Decimal(18, 2)), CAST(0.2000 AS Decimal(18, 4)), CAST(N'2024-03-06' AS Date), CAST(N'2024-02-28' AS Date), 1, N'1', CAST(N'2024-03-18T17:11:53.063' AS DateTime), N'P')
GO
INSERT [dbo].[RateMaster] ([RateID], [HotelId], [CategoryId], [PricePerDay], [PriceDifference], [ExtraBedPercentage], [RateStartDate], [RateEndDate], [IsActive], [EntryBy], [EntryDate], [ExtraBadPriceMode]) VALUES (17, N'ALL33', 113, CAST(5000.00 AS Decimal(18, 2)), CAST(1000.00 AS Decimal(18, 2)), CAST(2500.0000 AS Decimal(18, 4)), CAST(N'2024-03-18' AS Date), CAST(N'2024-03-20' AS Date), 1, N'1', CAST(N'2024-03-20T12:22:17.740' AS DateTime), N'A')
GO
INSERT [dbo].[RateMaster] ([RateID], [HotelId], [CategoryId], [PricePerDay], [PriceDifference], [ExtraBedPercentage], [RateStartDate], [RateEndDate], [IsActive], [EntryBy], [EntryDate], [ExtraBadPriceMode]) VALUES (18, N'AYO66', 139, CAST(1000.00 AS Decimal(18, 2)), CAST(200.00 AS Decimal(18, 2)), CAST(500.0000 AS Decimal(18, 4)), CAST(N'2024-03-21' AS Date), CAST(N'2024-03-22' AS Date), 1, N'1', CAST(N'2024-03-20T12:22:02.383' AS DateTime), N'A')
GO
SET IDENTITY_INSERT [dbo].[RateMaster] OFF
GO
SET IDENTITY_INSERT [dbo].[StateMaster] ON 
GO
INSERT [dbo].[StateMaster] ([StateId], [StateName], [StateCode], [EntryDate], [DeleteStatus]) VALUES (1, N'Uttar Pradesh', N'UP', CAST(N'2018-02-10T19:17:14.320' AS DateTime), 0)
GO
SET IDENTITY_INSERT [dbo].[StateMaster] OFF
GO
SET IDENTITY_INSERT [dbo].[tbl_BedMaster] ON 
GO
INSERT [dbo].[tbl_BedMaster] ([bed_id], [BedName], [noofBed]) VALUES (1, N'Single bed', 2)
GO
INSERT [dbo].[tbl_BedMaster] ([bed_id], [BedName], [noofBed]) VALUES (2, N'Double bed', 2)
GO
INSERT [dbo].[tbl_BedMaster] ([bed_id], [BedName], [noofBed]) VALUES (3, N'Triple bed', 3)
GO
INSERT [dbo].[tbl_BedMaster] ([bed_id], [BedName], [noofBed]) VALUES (4, N'Four bedded', 4)
GO
SET IDENTITY_INSERT [dbo].[tbl_BedMaster] OFF
GO
SET IDENTITY_INSERT [dbo].[tbl_CategoryMaster] ON 
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (2, N'AC Deluxe', 1, CAST(N'2019-12-07T11:17:20.733' AS DateTime), N'HTL10191', N'45000730695', N'1000299580', N'RTBAGRA', N'5722', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (3, N'AC Executive', 1, CAST(N'2019-07-06T11:29:27.040' AS DateTime), N'HTL10191', N'45000757489', N'1000299580', N'RTBAGRA', N'5723', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (4, N'Air Cooled', 1, CAST(N'2019-07-06T11:29:36.460' AS DateTime), N'HTL10191', N'45000757490', N'1000299580', N'RTBAGRA', N'5724', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (5, N'Suite Room', 1, CAST(N'2019-07-06T11:29:45.853' AS DateTime), N'HTL10191', N'45000757488', N'1000299580', N'RTBAGRA', N'5721', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (10, N'AC Deluxe', 1, CAST(N'2019-07-06T12:25:31.913' AS DateTime), N'HTL97314', N'45000730788', N'1000299650', N'HTJK', N'10602', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (11, N'AC Executive', 1, CAST(N'2019-07-06T12:25:49.443' AS DateTime), N'HTL97314', N'45000757491', N'1000299650', N'HTJK', N'10603', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (12, N'Swiss Cottage', 1, CAST(N'2019-07-06T12:26:00.053' AS DateTime), N'HTL97314', NULL, NULL, N'HTJK', N'10601', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (14, N'AC Four Beded', 1, CAST(N'2021-07-29T15:47:14.420' AS DateTime), N'HTL63683', N'45000852067', N'1000299691', N'HSAY', N'10724', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (16, N'Ordinary Three Bedded', 1, CAST(N'2020-06-29T12:13:38.067' AS DateTime), N'HTL63683', N'45000852070', N'1000299691', N'HSAY', N'10723', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (19, N'AC Deluxe', 1, CAST(N'2019-07-25T19:02:01.987' AS DateTime), N'HTL68300', N'45000757577', N'1000299864', N'RTBBP', N'10681', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (20, N'AC Executive', 1, CAST(N'2019-07-25T19:02:11.597' AS DateTime), N'HTL68300', N'45000731506', N'1000299864', N'RTBBP', N'10682', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (21, N'Air Cooled', 1, CAST(N'2019-07-25T19:02:23.613' AS DateTime), N'HTL68300', N'45000757578', N'1000299864', N'RTBBP', N'10683', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (23, N'AC Deluxe', 1, CAST(N'2019-07-25T18:16:22.547' AS DateTime), N'HTL82734', N'45000730487', N'1000299488', N'HGOMTI', N'6581', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (24, N'AC Executive', 1, CAST(N'2019-07-25T18:16:34.170' AS DateTime), N'HTL82734', N'45000757467', N'1000299488', N'HGOMTI', N'6582', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (25, N'AC Ordinary', 1, CAST(N'2019-07-06T13:45:07.863' AS DateTime), N'HTL82734', N'45000757469', N'1000299488', N'HGOMTI', N'6583', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (26, N'AC Deluxe', 1, CAST(N'2019-07-25T19:02:46.520' AS DateTime), N'HTL39354', N'45000757579', N'1000299868', N'RTBNAWAB', N'6501', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (27, N'Super Deluxe', 1, CAST(N'2021-10-20T18:47:13.773' AS DateTime), N'HTL39354', NULL, NULL, N'RTBNAWAB', N'6502', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (42, N'Non AC Four Bedded', 1, CAST(N'2021-07-29T15:45:59.980' AS DateTime), N'HTL63683', N'45000852069', N'1000299691', N'HSAY', N'11101', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (43, N'AC Deluxe', 1, CAST(N'2019-07-25T18:37:06.370' AS DateTime), N'HTL99957', N'45000730935', N'1000299676', N'RHRBY', N'10649', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (44, N'Air Cooled', 1, CAST(N'2019-07-25T18:37:16.697' AS DateTime), N'HTL99957', N'45000757544', N'1000299676', N'RHRBY', N'10650', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (45, N'AC Deluxe', 1, CAST(N'2019-07-25T18:36:03.070' AS DateTime), N'HTL87951', N'45000735061', N'1000301262', N'RTBCK', N'10702', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (46, N'AC Executive', 1, CAST(N'2019-07-25T18:36:22.150' AS DateTime), N'HTL87951', N'45000757520', N'1000301262', N'RTBCK', N'10704', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (47, N'AC Executive 3 Beded', 1, CAST(N'2019-07-13T15:18:53.733' AS DateTime), N'HTL87951', N'45000757521', N'1000301262', N'RTBCK', N'10703', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (50, N'AC Executive Double Bedded', 1, CAST(N'2019-07-13T15:37:51.023' AS DateTime), N'HTL10191', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (51, N'Air-Cooled', 1, CAST(N'2019-07-25T17:58:04.337' AS DateTime), N'HTL10389', N'45000757505', N'1000299661', N'RGTC', N'10623', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (52, N'A.C. Deluxe', 1, CAST(N'2019-07-25T17:57:52.053' AS DateTime), N'HTL10389', N'45000757503', N'1000299661', N'RGTC', N'10621', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (53, N'AC Executive', 1, CAST(N'2019-07-25T16:52:52.067' AS DateTime), N'HTL91324', N'45000757572', N'1000299699', N'VEERA', N'10730', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (55, N'AC Executive', 1, CAST(N'2019-07-25T19:07:34.623' AS DateTime), N'HTL33373', N'45000733463', N'1000300692', N'RTBKJ', N'10655', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (56, N'AC Deluxe', 1, CAST(N'2019-07-25T19:07:45.530' AS DateTime), N'HTL33373', N'45000757582', N'1000300692', N'RTBKJ', N'10654', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (57, N'AC Deluxe', 1, CAST(N'2019-07-25T18:48:14.687' AS DateTime), N'HTL24279', N'45000731497', N'1000299863', N'RPNK', N'6182', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (58, N'AC Executive', 1, CAST(N'2019-07-25T18:50:18.797' AS DateTime), N'HTL24279', N'45000757575', N'1000299863', N'RPNK', N'6183', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (59, N'Air Cooled', 1, CAST(N'2019-07-25T18:50:36.610' AS DateTime), N'HTL24279', N'45000757576', N'1000299863', N'RPNK', N'6184', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (63, N'AC Executive', 1, CAST(N'2019-07-25T18:46:54.700' AS DateTime), N'HTL51674', N'45000731460', N'1000299823', N'HJAHNAVI', N'6621', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (64, N'Air Cooled', 1, CAST(N'2019-07-25T18:46:44.810' AS DateTime), N'HTL51674', N'45000757548', N'1000299823', N'HJAHNAVI', N'6622', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (65, N'AC Deluxe', 1, CAST(N'2019-07-25T18:37:34.587' AS DateTime), N'HTL18824', N'45000757563', N'1000299684', N'RTBMORA', N'6641', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (66, N'AC Executive', 1, CAST(N'2019-07-25T18:37:45.777' AS DateTime), N'HTL18824', N'45000730940', N'1000299684', N'RTBMORA', N'6642', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (67, N'Air Cooled 4 Beded', 1, CAST(N'2019-07-13T17:10:14.313' AS DateTime), N'HTL18824', N'45000757565', N'1000299684', N'RTBMORA', N'6643', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (68, N'AC Deluxe', 1, CAST(N'2019-07-25T19:17:18.323' AS DateTime), N'HTL87980', N'45000730883', N'1000299670', N'RHI', N'10643', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (69, N'AC Executive Room', 1, CAST(N'2019-07-25T19:17:41.013' AS DateTime), N'HTL87980', N'45000757529', N'1000299670', N'RHI', N'10661', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (70, N'Suite Room 4 Beded', 1, CAST(N'2019-07-13T17:26:25.020' AS DateTime), N'HTL87980', N'45000757528', N'1000299670', N'RHI', N'10642', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (72, N'Suite Room', 1, CAST(N'2019-07-13T17:28:28.383' AS DateTime), N'HTL38049', N'45000757580', N'1000300707', N'RTDA', N'10644', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (73, N'AC Deluxe', 1, CAST(N'2019-07-25T19:14:30.210' AS DateTime), N'HTL38049', N'45000733527', N'1000300707', N'RTDA', N'10645', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (74, N'AC Deluxe', 1, CAST(N'2019-07-25T18:45:43.573' AS DateTime), N'HTL92418', N'45000731117', N'1000299724', N'SARAS', N'5743', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (75, N'AC Executive', 1, CAST(N'2019-07-25T18:45:53.043' AS DateTime), N'HTL92418', N'45000757545', N'1000299724', N'SARAS', N'5744', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (80, N'Ordinary', 1, CAST(N'2019-07-25T18:05:53.847' AS DateTime), N'HTL16720', N'45000757500', N'1000299657', N'RTBVAR', N'6483', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (81, N'Suite Room', 1, CAST(N'2019-07-13T17:45:31.750' AS DateTime), N'HTL16720', N'45000757492', N'1000299657', N'RTBVAR', N'6461', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (82, N'AC Executive', 1, CAST(N'2019-07-25T18:47:25.763' AS DateTime), N'HTL66042', N'45000731487', N'1000299860', N'RTBS', N'5742', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (83, N'AC Executive 4 Beded', 1, CAST(N'2019-07-13T17:48:18.567' AS DateTime), N'HTL66042', N'45000757546', N'1000299860', N'RTBS', N'5741', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (84, N'AC Deluxe', 1, CAST(N'2019-07-25T19:05:34.303' AS DateTime), N'HTL91840', N'45000757585', N'1000306306', N'RTBSH', N'6161', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (85, N'AC Executive', 1, CAST(N'2019-07-25T19:05:43.787' AS DateTime), N'HTL91840', N'45000757586', N'1000306306', N'RTBSH', N'6162', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (86, N'Air Cooled', 1, CAST(N'2019-07-25T19:05:53.570' AS DateTime), N'HTL91840', N'45000745392', N'1000306306', N'RTBSH', N'6163', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (90, N'AC Deluxe', 1, CAST(N'2019-07-25T16:53:13.643' AS DateTime), N'HTL91324', N'45000731012', N'1000299699', N'VEERA', N'10729', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (91, N'Suite Room', 1, CAST(N'2019-07-25T16:53:36.253' AS DateTime), N'HTL91324', N'45000757571', N'1000299699', N'VEERA', N'10728', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (92, N'AC Executive', 1, CAST(N'2019-07-25T17:11:04.087' AS DateTime), N'HTL63683', N'45000730965', N'1000299691', N'HSAY', N'10721', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (93, N'Suite Room', 1, CAST(N'2019-07-25T17:31:44.370' AS DateTime), N'HTL87951', N'45000757519', N'1000301262', N'RTBCK', N'10701', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (94, N'Suite Room', 1, CAST(N'2024-03-21T10:52:28.893' AS DateTime), N'HTL78404', N'45000757508', N'1000306325', N'HAKND', N'10651', NULL, 4)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (95, N'A C Ordinary', 1, CAST(N'2019-07-25T17:39:10.283' AS DateTime), N'HTL78404', N'45000745428', N'1000306325', N'HAKND', N'10653', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (96, N'Air Cooled', 1, CAST(N'2019-07-25T17:39:24.253' AS DateTime), N'HTL78404', N'45000757513', N'1000306325', N'HAKND', N'10726', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (97, N'Air Cooled 4 Beded', 1, CAST(N'2019-07-25T17:39:46.517' AS DateTime), N'HTL78404', N'45000757514', N'1000306325', N'HAKND', N'10727', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (98, N'A.C.Executive', 1, CAST(N'2019-07-25T17:57:40.320' AS DateTime), N'HTL10389', N'45000730840', N'1000299661', N'RGTC', N'10622', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (99, N'AC Deluxe', 1, CAST(N'2019-07-25T18:06:47.613' AS DateTime), N'HTL16720', N'45000730823', N'1000299657', N'RTBVAR', N'6462', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (100, N'AC Economy', 1, CAST(N'2019-07-25T18:07:05.190' AS DateTime), N'HTL16720', N'45000757494', N'1000299657', N'RTBVAR', N'6463', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (101, N'AC Ordinary', 1, CAST(N'2019-12-16T14:27:05.567' AS DateTime), N'HTL16720', N'45000757495', N'1000299657', N'RTBVAR', N'6481', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (102, N'Air Cooled', 1, CAST(N'2019-07-25T18:07:43.427' AS DateTime), N'HTL16720', N'45000757498', N'1000299657', N'RTBVAR', N'6482', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (103, N'Air Cooled', 1, CAST(N'2019-07-25T18:16:53.123' AS DateTime), N'HTL82734', N'45000757470', N'1000299488', NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (104, N'AC Executive', 1, CAST(N'2019-07-25T18:29:18.123' AS DateTime), N'HTL78404', N'45000757511', N'1000306325', N'HAKND', N'10725', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (105, N'AC Deluxe', 1, CAST(N'2019-07-25T18:29:43.810' AS DateTime), N'HTL78404', N'45000757510', N'1000306325', N'HAKND', N'10652', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (106, N'Air Cooled', 1, CAST(N'2019-07-25T18:38:57.310' AS DateTime), N'HTL91324', N'45000757574', N'1000299699', N'VEERA', N'10731', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (107, N'Suite Room', 1, CAST(N'2019-07-25T19:18:15.250' AS DateTime), N'HTL87980', N'45000757526', N'1000299670', N'RHI', N'10641', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (108, N'AC 4 Beded', 1, CAST(N'2019-12-17T16:44:55.663' AS DateTime), N'HTL87980', N'45000757532', N'1000299670', N'RHI', N'10662', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (112, N'AC Executive(Double Bedded)', 1, CAST(N'2019-11-26T13:23:15.377' AS DateTime), N'ALL33', N'45000738682', N'1000302637', N'RTBSHAH', N'6521', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (113, N'Air Cooled', 1, CAST(N'2019-11-26T13:23:32.590' AS DateTime), N'ALL33', N'45000757583', N'1000302637', N'RTBSHAH', N'6522', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (117, N'Deluxe Tent', 1, CAST(N'2020-01-27T10:19:48.653' AS DateTime), N'LKO52', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (118, N'Super Deluxe Tent', 1, CAST(N'2020-01-27T10:20:03.393' AS DateTime), N'LKO52', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (119, N'Dormitory', 0, CAST(N'2020-11-22T16:12:41.200' AS DateTime), N'HTL38049', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (120, N'Suits', 1, CAST(N'2020-12-31T17:57:25.240' AS DateTime), N'HTL24279', NULL, NULL, N'RPNK', N'6181', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (121, N'ac exc', 1, CAST(N'2021-01-19T12:23:21.940' AS DateTime), N'HTL87951', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (122, N'AC Executive', 1, CAST(N'2021-01-21T12:59:16.660' AS DateTime), N'MHJ60', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (123, N'Ordinary', 1, CAST(N'2021-01-21T12:59:30.980' AS DateTime), N'MHJ60', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (124, N'Dormitory', 1, CAST(N'2021-01-21T13:00:02.400' AS DateTime), N'MHJ60', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (125, N'Ordinary', 1, CAST(N'2021-01-21T13:32:10.407' AS DateTime), N'FRK61', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (126, N'Dormitory', 1, CAST(N'2021-01-21T13:33:01.563' AS DateTime), N'FRK61', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (127, N'A C Deluxe', 1, CAST(N'2021-01-21T14:04:56.867' AS DateTime), N'SIT62', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (128, N'AC Ordinary', 1, CAST(N'2021-01-21T14:05:18.203' AS DateTime), N'SIT62', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (129, N'Ordinary', 1, CAST(N'2021-01-21T14:05:31.287' AS DateTime), N'HTL10191', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (130, N'AC Deluxe', 1, CAST(N'2021-01-21T14:06:00.697' AS DateTime), N'MIR63', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (131, N'AC', 1, CAST(N'2021-01-21T14:06:18.973' AS DateTime), N'MIR63', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (132, N'Air Cooled', 1, CAST(N'2021-01-21T14:06:41.317' AS DateTime), N'MIR63', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (133, N'Dormitory', 1, CAST(N'2021-01-21T14:07:28.013' AS DateTime), N'MIR63', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (134, N'A.C. Room', 1, CAST(N'2021-10-08T13:08:49.477' AS DateTime), N'MAU64', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (135, N'Air Cooled Room', 1, CAST(N'2021-10-08T13:09:11.603' AS DateTime), N'MAU64', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (136, N'AC Deluxe', 1, CAST(N'2021-01-21T14:09:45.983' AS DateTime), N'GHZ65', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (137, N'AC Executive', 1, CAST(N'2021-01-21T14:10:09.553' AS DateTime), N'GHZ65', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (138, N'Air Cooled', 1, CAST(N'2021-01-21T14:10:23.707' AS DateTime), N'GHZ65', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (139, N'AC Suite', 1, CAST(N'2021-01-21T14:11:03.037' AS DateTime), N'AYO66', N'45000852221', N'1000353148', NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (140, N'AC Ordinary', 1, CAST(N'2021-01-21T14:11:21.373' AS DateTime), N'AYO66', N'45000852227', N'1000353148', NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (141, N'AC Deluxe', 1, CAST(N'2021-01-21T14:11:45.753' AS DateTime), N'BAD67', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (142, N'AC', 1, CAST(N'2021-01-21T14:11:57.967' AS DateTime), N'BAD67', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (143, N'Air Cooled Ordinary', 1, CAST(N'2021-01-21T14:12:27.750' AS DateTime), N'BAD67', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (144, N'Dormitory', 1, CAST(N'2021-01-21T14:13:07.373' AS DateTime), N'BAD67', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (145, N'AC Executive', 1, CAST(N'2021-01-21T14:13:33.540' AS DateTime), N'GZH45', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (146, N'Air Cooled', 1, CAST(N'2021-01-21T14:13:53.037' AS DateTime), N'GZH45', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (147, N'Dormitory (AirCooled)', 1, CAST(N'2021-01-21T14:14:20.260' AS DateTime), N'GZH45', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (148, N'AC Deluxe', 1, CAST(N'2021-01-21T14:14:50.543' AS DateTime), N'BTH70', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (149, N'Ordinary', 1, CAST(N'2021-01-21T14:22:15.773' AS DateTime), N'SIT62', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (150, N'AC Deluxe', 1, CAST(N'2021-01-21T15:14:00.887' AS DateTime), N'ETW71', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (151, N'AC', 1, CAST(N'2021-01-21T15:14:29.987' AS DateTime), N'ETW71', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (152, N'Air Cooled', 1, CAST(N'2021-07-29T15:46:27.583' AS DateTime), N'HTL63683', N'45000852068', N'1000299691', N'HSAY', N'10722', NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (153, N'Suit', 1, CAST(N'2021-09-02T16:45:22.240' AS DateTime), N'HTL78999', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (154, N'A.C. Room', 1, CAST(N'2021-09-02T16:47:58.377' AS DateTime), N'HTL78999', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (159, N'AC Executive 2', 1, CAST(N'2021-10-11T20:01:36.817' AS DateTime), N'HTL33373', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (160, N'AC Deluxe 2', 1, CAST(N'2021-10-11T20:22:46.780' AS DateTime), N'HTL33373', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (163, N'AC DELUX', 1, CAST(N'2022-12-07T14:11:56.633' AS DateTime), N'AYO66', N'45001058806', N'1000353148', NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (164, N'Triveni Tent City', 1, CAST(N'2023-01-14T19:02:59.307' AS DateTime), N'TTC00001', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (165, N'SUPER DELUXE ', 1, CAST(N'2023-02-08T16:52:15.443' AS DateTime), N'LTC00001', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (166, N'DELUXE', 1, CAST(N'2023-02-08T16:52:30.287' AS DateTime), N'LTC00001', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (167, N'Dormitory', 1, CAST(N'2023-06-07T11:14:43.957' AS DateTime), N'HTL16720', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (168, N'AC Dormitory(134)', 1, CAST(N'2023-06-07T11:15:24.003' AS DateTime), N'HTL16720', NULL, NULL, NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (174, N'AC Deluxe Premium', 1, CAST(N'2019-07-25T17:11:04.087' AS DateTime), N'HTL63683', N'45001226775', N'1000299691', NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (175, N'AC Executive Premium', 1, CAST(N'2021-07-29T15:46:27.583' AS DateTime), N'HTL63683', N'45001226778', N'1000299691', NULL, NULL, NULL, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (177, N'Deluxe', 0, CAST(N'2024-03-07T12:36:44.447' AS DateTime), N'106', NULL, NULL, NULL, NULL, 0, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (178, N'AC Deluxe', 1, CAST(N'2024-03-21T10:51:56.613' AS DateTime), N'104', NULL, NULL, NULL, NULL, 0, 1)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (179, N'AC Ordinary', 0, CAST(N'2024-03-18T12:44:53.730' AS DateTime), N'104', NULL, NULL, NULL, NULL, 0, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (180, N'Air Cooled', 0, CAST(N'2024-03-18T12:44:27.613' AS DateTime), N'104', NULL, NULL, NULL, NULL, 0, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (181, N'Deluxe', 0, CAST(N'2024-03-08T10:32:11.803' AS DateTime), N'104', NULL, NULL, NULL, NULL, 0, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (182, N'Deluxe', 0, CAST(N'2024-03-08T12:12:17.200' AS DateTime), N'106', NULL, NULL, NULL, NULL, 0, 2)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (183, N'Deluxe 1', 1, CAST(N'2024-03-21T10:52:10.290' AS DateTime), N'106', NULL, NULL, NULL, NULL, 0, 3)
GO
INSERT [dbo].[tbl_CategoryMaster] ([ID], [Category], [IsActive], [EntryDate], [hotelid], [MMTCategoryCode], [MMTHotelCode], [IRCTcHotelCode], [IRCTCCategoryCode], [IsOffline], [bed_id]) VALUES (184, N'Non AC Room', 1, CAST(N'2024-03-21T10:57:56.733' AS DateTime), N'HTL97314', NULL, NULL, NULL, NULL, 0, 4)
GO
SET IDENTITY_INSERT [dbo].[tbl_CategoryMaster] OFF
GO
SET IDENTITY_INSERT [dbo].[tbl_HotelImageMaster] ON 
GO
INSERT [dbo].[tbl_HotelImageMaster] ([Id], [ImagePath], [EntryDate], [IsActive], [HotelId], [ImgExt]) VALUES (1, N'/Upload/HotelImages/9a0acbe3-f32c-4a3f-b401-b898fd1bd080_.jpg', CAST(N'2024-03-13T19:16:16.393' AS DateTime), 0, N'ALL33', NULL)
GO
INSERT [dbo].[tbl_HotelImageMaster] ([Id], [ImagePath], [EntryDate], [IsActive], [HotelId], [ImgExt]) VALUES (2, N'/Upload/HotelImages/dc909c3c-3b7f-4249-8368-ce927f17066f_.jpg', CAST(N'2024-03-13T19:16:25.390' AS DateTime), 0, N'BAD67', NULL)
GO
INSERT [dbo].[tbl_HotelImageMaster] ([Id], [ImagePath], [EntryDate], [IsActive], [HotelId], [ImgExt]) VALUES (3, N'/Upload/HotelImages/9256420c-7cce-4c43-832d-53f30538dada_.jpg', CAST(N'2024-03-13T19:16:30.923' AS DateTime), 0, N'BAD67', NULL)
GO
INSERT [dbo].[tbl_HotelImageMaster] ([Id], [ImagePath], [EntryDate], [IsActive], [HotelId], [ImgExt]) VALUES (4, N'/Upload/HotelImages/bc8c1675-ee10-4c7e-b461-7de755f27df0_.jpg', CAST(N'2024-03-13T19:16:36.487' AS DateTime), 0, N'BAD67', NULL)
GO
INSERT [dbo].[tbl_HotelImageMaster] ([Id], [ImagePath], [EntryDate], [IsActive], [HotelId], [ImgExt]) VALUES (5, N'/Upload/HotelImages/b703e8da-c6ba-4b3b-acc4-f6191e310f3c_.jpg', CAST(N'2024-03-13T19:16:44.657' AS DateTime), 0, N'ALL33', NULL)
GO
INSERT [dbo].[tbl_HotelImageMaster] ([Id], [ImagePath], [EntryDate], [IsActive], [HotelId], [ImgExt]) VALUES (6, N'/Upload/HotelImages/bef8e91c-d852-4bdd-a25a-5f9099e3b8ef_.jpg', CAST(N'2024-03-14T11:06:16.533' AS DateTime), 0, N'HTL91324', NULL)
GO
INSERT [dbo].[tbl_HotelImageMaster] ([Id], [ImagePath], [EntryDate], [IsActive], [HotelId], [ImgExt]) VALUES (7, N'/Upload/HotelImages/2187332a-7e0a-427f-bd71-48087318b490_.jpg', CAST(N'2024-03-18T13:09:03.000' AS DateTime), 0, N'HTL91324', NULL)
GO
INSERT [dbo].[tbl_HotelImageMaster] ([Id], [ImagePath], [EntryDate], [IsActive], [HotelId], [ImgExt]) VALUES (8, N'/Upload/HotelImages/28bde981-29ad-4c9d-a3ec-42e4a2e357b5_.jpg', CAST(N'2024-03-18T13:09:10.767' AS DateTime), 0, N'HTL91324', NULL)
GO
INSERT [dbo].[tbl_HotelImageMaster] ([Id], [ImagePath], [EntryDate], [IsActive], [HotelId], [ImgExt]) VALUES (9, N'/Upload/HotelImages/4d683ad1-a2e8-4fee-bfa2-b41d911f9f14_.jpg', CAST(N'2024-03-18T13:37:10.317' AS DateTime), 0, N'HTL99957', NULL)
GO
INSERT [dbo].[tbl_HotelImageMaster] ([Id], [ImagePath], [EntryDate], [IsActive], [HotelId], [ImgExt]) VALUES (10, N'/Upload/HotelImages/', CAST(N'2024-03-18T16:46:18.947' AS DateTime), 0, N'HTL10191', NULL)
GO
INSERT [dbo].[tbl_HotelImageMaster] ([Id], [ImagePath], [EntryDate], [IsActive], [HotelId], [ImgExt]) VALUES (11, N'/Upload/HotelImages/6087e2dc-1276-4a80-b146-d72269d66eb0_.jpg', CAST(N'2024-03-18T16:49:49.127' AS DateTime), 0, N'113', NULL)
GO
INSERT [dbo].[tbl_HotelImageMaster] ([Id], [ImagePath], [EntryDate], [IsActive], [HotelId], [ImgExt]) VALUES (12, N'/Upload/HotelImages/1da640ca-b81e-475b-8c4a-03af6981404f_.jpg', CAST(N'2024-03-18T16:51:14.713' AS DateTime), 0, N'113', NULL)
GO
SET IDENTITY_INSERT [dbo].[tbl_HotelImageMaster] OFF
GO
SET IDENTITY_INSERT [dbo].[tbl_HotelMaster] ON 
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (105, N'104', N'Alaknanda Hotel', 1, 11, NULL, N'6, Tej Bahadur Sapru Marg, Near Sahara Ganj Mall, Hazratganj, Lucknow, Uttar Pradesh-226001', N'7007446342', N'<p>The hotel was amazing and located in a good location The rooms are good and the food quality was great overall this goes to the management team specially for Tarun Srivastav the hotel manager.</p>', NULL, NULL, CAST(N'2024-03-06T17:11:15.570' AS DateTime), 1, N'testhotel@gmail.com', N'/Upload/IconImages/6e979459-a795-4125-95fd-cf3d2ab71d2c_.jpg', N'5653345', NULL, N'ALKND', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (106, N'106', N'BASERA', 1, 11, NULL, N'aliganj lucknow', N'7896541235', N'<p>BASERA</p>', NULL, NULL, CAST(N'2024-03-06T17:15:43.320' AS DateTime), 1, N'test@gmail.com', N'/Upload/IconImages/9f0243d1-5c8a-4d4d-96d5-c8b5165f818b_.jpg', N'78965412', NULL, N'BSR', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (110, N'107', N'BASERA', 1, 11, NULL, N'aliganj', N'7007446342', N'<p>Located on the Banks of Garra river, the tourist Bungalow&amp;nbsp;is a good place in the city&amp;nbsp;to stay.</p>', NULL, NULL, CAST(N'2024-03-09T13:43:42.610' AS DateTime), 1, N'test@gmail.com', N'/Upload/IconImages/e48a08f7-1a80-46d3-a49d-820f0b27a889_.jpg', N'659656', NULL, N'BSR', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (112, N'111', N'awara', 1, 11, NULL, N'lucknow', N'7896541233', N'<p>this hotel not exit it is only for testing&nbsp;</p>', NULL, NULL, CAST(N'2024-03-18T12:23:39.823' AS DateTime), 1, N'awaratest@gmail.com', N'/Upload/IconImages/faef9bc7-0cd7-4d44-aec8-793c735592ad_.jpg', N'000000000', NULL, N'AW', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (113, N'113', N'Ram Shyam Residency', 1, 2, NULL, N'ayodhya up', N'7896541235', N'<p>it is not residency. it is only for &nbsp;testing</p>', NULL, NULL, CAST(N'2024-03-18T13:16:30.160' AS DateTime), 1, N'ramshyamrrrr@gmail.com', N'/Upload/IconImages/3d83fabe-5b81-4578-99c9-fca8980390f3_.jpg', N'000000000', NULL, N'RRSSRR', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (116, N'114', N'dfgdgd', 1, 51, NULL, N'dfgdfgsdf', N'dgdf', N'<p>fgfdgdfgf</p>', NULL, NULL, CAST(N'2024-03-18T16:00:16.650' AS DateTime), 1, N'gdfgdfgdf', N'/Upload/IconImages/1e85f180-4536-4061-a318-a5a5a47b6109_.jpg', N'gsdfg', NULL, N'gdgdfg', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (32, N'ALL33', N'Rahi Tourist Bungalow', 1, 11, NULL, N'Bank of Garra River, Shahjahanpur, Uttar Pradesh-242406', N'9415608122', N'<p>Located on the Banks of Garra river, the tourist Bungalow&amp;nbsp;is a good place in the city&amp;nbsp;to stay. Celebrate a quiet evening with near and dear ones in the cosy bar or on the open terrace with a view of the river</p>', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2019-07-13T17:56:03.653' AS DateTime), 1, N'shahjahanpur@upstdc.co.in', N'/Upload/IconImages/78b28773-b2c8-4f73-a960-db9d6d0f9bad_.jpg', N'9456286258', N'09AAACU4990N1ZM', N'SPN', N'Rahi Tourist Bungalow-Shahjahanpur', NULL, N'1000302637', N'7b501425fe', 21, N'RTBSHAH', NULL, NULL, NULL, NULL, NULL, 21, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (65, N'AYO66', N'Saryu Atithi Grah', 1, 2, NULL, N'Saryu Ghat, Near Ram Katha Park, Naya Ghat, Ayodhya, Uttar Pradesh-224123', N'9412526465', N'<p>Yatri Niwas</p>', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2021-01-21T13:51:21.220' AS DateTime), 1, N'hotelsaryu@upstdc.co.in', N'/Upload/IconImages/7d502fa9-2dac-4ae1-8392-12ffac18ca73_.jpg', N'9412526465', N'09AAACU4990N1ZM', N'RTA', N'Saryu Atithi Grah', NULL, N'1000353148', N'3d13b7c474', 4, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (66, N'BAD67', N'Rahi Tourist Bungalow', 1, 11, NULL, N'Civil Lines, Budaun, Uttar Pradesh-243601', N'9415608122', N'<p>Rahi Tourist Bungalow</p>', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2021-01-21T13:52:40.063' AS DateTime), 1, N'uptbadaun@gmail.com', N'/Upload/IconImages/ae7b889d-62a2-48fc-ade6-22f4e6c6ccbd_.jpg', N'05832-268941', N'09AAACU4990N1ZM', N'BUD', N'Rahi Tourist Bungalow-Badaun', NULL, NULL, NULL, 24, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (69, N'BTH70', N'Rahi Tourist Bungalow', 1, 36, NULL, N'Nana Rao Peshwa Smarak park, Bithoor , Kanpur, Uttar Pradesh-209203', N'9415013039', N'<p>Rahi Tourist Bungalow</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2021-01-21T13:58:23.887' AS DateTime), 1, N'uptbithoor@gmail.com', N'HotelImages/11.jpeg', N'9415609464', N'09AAACU4990N1ZM', N'BTH', N'Rahi Tourist Bungalow-Bithoor', NULL, NULL, NULL, 25, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (70, N'ETW71', N'Rahi Tourist Bungalow', 1, 29, NULL, N'Sumer Singh Qila Etawah, Uttar Pradesh-206001', N'9415013045', N'<p>Rahi Tourist Bungalow</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2021-01-21T13:59:47.333' AS DateTime), 1, N'uptetawah@gmail.com', N'HotelImages/20170912_061038.jpg', N'8077783084', N'09AAACU4990N1ZM', N'ETW', N'Rahi Tourist Bungalow-Etawah', NULL, NULL, NULL, 33, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (60, N'FRK61', N'Rahi Tourist Bungalow ', 1, 30, NULL, N'Sankisa Tiraha, Opp- Sri Lanka Temple, Basantpur, Sankisa Uttar Pradesh-209652', N'9415013045', N'<p>Sankisa Road, Sankisa Basantpur, Uttar Pradesh 209652</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2021-01-21T13:30:25.470' AS DateTime), 1, N'uptsankisa@gmail.com', N'HotelImages/IMG-20210123-WA0028.jpg', N'8077783084', N'09AAACU4990N1ZM', N'SNK', N'Rahi Tourist Bungalow, Sankisa-Farukhkhabad', NULL, NULL, NULL, 30, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (64, N'GHZ65', N'Rahi Tourist Bungalow', 1, 31, NULL, N'NH-29, Chhavani Line, Varanasi Road, Ghazipur, Uttar Pradesh-233002', N'9415013039', N'<p>Rahi Tourist Bungalow</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2021-01-21T13:48:48.993' AS DateTime), 1, N'uptghazipur@gmail.com', N'HotelImages/IMG-20210123-WA0007.jpg', N'9415013039', N'09AAACU4990N1ZM', N'GHZ', N'Rahi Tourist Bungalow-Ghazipur', NULL, NULL, NULL, 28, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (68, N'GZH45', N'Rahi Tourist Bungalow', 1, 39, NULL, N'NH-24, Garhmukteswar Chauraha, Garhmukteswar, Hapur, Uttar Pradesh-245205', N'8859096644', N'<p>Rahi Tourist Bungalow</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2021-01-21T13:57:04.857' AS DateTime), 1, N'rahitbgarhmukteshwar@upstdc.co.in', N'HotelImages/1584643081645.jpg', N'9720733445', N'09AAACU4990N1ZM', N'GZH', N'Rahi Tourist Bungalow-Ghaziabad', NULL, NULL, NULL, 27, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (1, N'HTL10191', N'Rahi Tourist Bungalow', 1, 1, 1, N'Delhi Gate, Near Raja Ki Mandi Railway Station, Agra, Uttar Pradesh-282002', N'8005488871', N'<p>This property is located in the heart of this historic city which is home to the great monument of love, the Taj and the loved residence of the early Moughals, the Fort. The property is 10 km and 7 km away from the two monuments respectively and has the famed shopping areas nearby. Do not forget to shop for mouth-watering Petha, Gajak, Dal-moth, and of course, a replica of the Taj, carved by the traditional artisans, to carry back home. Enjoy the green spaces within the property and beyond.</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2019-07-06T11:20:57.140' AS DateTime), 0, N'agra@upstdc.co.in', N'HotelImages/03002019_HTL1019120190828_092439.JPG', N'0562-2850120', N'09AAACU4990N1ZM', N'RKM', N'Rahi Tourist Bungalow-Agra', 3, N'1000299580', N'7188fed84b', 1, N'RTBAGRA', NULL, NULL, NULL, NULL, NULL, 8, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (21, N'HTL10389', N'Rahi Gulistan Tourist Complex', 1, 6, NULL, N'Shahkuli, Fatehpur Sikri, Agra, Uttar Pradesh-283110', N'9415233448', N'<p>The Gulistan Tourist Complex is located at a short distance from the World Heritage site of Fatehpur Sikri. The complex itself has been contructed in an unque style in red brick finish with an interesting layout. Stay immersed in the history.&nbsp;Stay here to witness a piece of history, an important heritage to the humankind and to pay respect at the dargah of Sufi Saint Salim Chishti.&nbsp;The property has a nice restaurant to serve sumptous food.</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2019-07-13T15:37:17.273' AS DateTime), 1, N'gulistan@upstdc.co.in', N'HotelImages/03002019_HTL10389IMG_1844.JPG', N'05613-282840', N'09AAACU4990N1ZM', N'SIK', N'Rahi Gulistan Tourist Complex-Fatehpur Sikri, Agra', 1, N'1000299661', N'56a8a8992d', 8, N'RGTC', N'12720001000005', NULL, NULL, NULL, NULL, 10, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (29, N'HTL16720', N'Rahi Tourist Bungalow ', 1, 20, NULL, N'Parade Kothi,Near Cantt. Railway Station, Varanasi,Uttar Pradesh- 221002', N'9415902707', N'<p>Rahi Tourist Bungalow is located at a short distance from the Cantt Railway Station and offers 45 rooms of various types and ample parking space. Whether you visit the city to seek blessing of lord Kashi Vishwanath, to explore the culture of the world&#39;s&nbsp;longest continuously alive city, to seek treatment from the health experts, or for business, this is the place to stay. It has a nice restaurant serving variety of food and a great bar to celebrate a quiet evening. It has a well manicured lawn for a cosy get together.</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2019-07-13T17:43:59.187' AS DateTime), 1, N'varanasi@upstdc.co.in', N'HotelImages/03002019_HTL16720IMG_1257.JPG', N'0542-2208545, 2208413', N'09AAACU4990N1ZM', N'VAR', N'Rahi Tourist Bungalow-Varanasi', NULL, N'1000299657', N'9b63b936ef', 22, N'RTBVAR', N'12714038000995', CAST(N'2021-12-19' AS Date), NULL, NULL, NULL, 3, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (26, N'HTL18824', N'Rahi Tourist Bungalow', 1, 13, NULL, N'Near Circuit House Delhi Road, Moradabad, Uttar Pradesh- 244001', N'9149099890', N'<p>The Rahi Tourist Bungalow is nicely located in the heart of the city on the National Highway adjoining the Circuit House. The property has nice spacious rooms for a comfortable stay. The Restaurant serves sumptous food. It has major landmarks of&nbsp;the city like the railway station,&nbsp;the bus station as well as traditional handicraft shopping areas nearby. The Hotel is strategically located and facilitates easy&nbsp;access to the reputed educational as well as business destinations of the city and around.</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2019-07-13T17:08:37.950' AS DateTime), 1, N'moradabad@upstdc.co.in', N'HotelImages/28002019_HTL1882420190828_083446.jpg', N'0591-2480037', N'09AAACU4990N1ZM', N'MBD', N'Rahi Tourist Bungalow-Moradabad', 17, N'1000299684', N'f791f6584e', 15, N'RTBMORA', NULL, NULL, NULL, NULL, NULL, 18, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (24, N'HTL24279', N'Rahi Pathik Niwas', 1, 10, NULL, N'Buddha Marg, Kushinagar, Uttar Pradesh-274403', N'8004910698', N'<p>Pathik Niwas is the choice to stay at Kushinagar when you are exploring the path of the Lord Buddha. Located at a stone&#39;s throw&nbsp;from the Mahanirvana temple as well as the Japanese temple,&nbsp;the hotel gives its guests a&nbsp;feeling of being under the refuge of the Lord himself. The property has well designed rooms and a formal multi-cuisine restaurant and gardens to enjoy evenings. The hotel has ample parking space.</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2019-07-13T16:10:25.027' AS DateTime), 1, N'pathikniwas@upstdc.co.in', N'HotelImages/03002019_HTL24279IMG_1340.JPG', N'05564-273045', N'09AAACU4990N1ZM', N'KUS', N'Rahi Pathik Niwas-Kushinagar', 33, N'1000299863', N'ba084b3859', 12, N'RPNK', N'12719034000046', NULL, NULL, NULL, NULL, 7, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (23, N'HTL33373', N'Rahi Tourist Bungalow', 1, 9, NULL, N'G.T. Road Makrand Nagar , Kannauj, Uttar Pradesh-209726', N'9415013045', N'<p>Strategically laocated in the city, the Rahi Tourist Bungalow is the ideal place to stay in the city, whether you are travelling for business or to experience various facets of the Itra making, the traditional art of the city.</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2019-07-13T15:57:46.857' AS DateTime), 1, N'kannauj@upstdc.co.in', N'HotelImages/03002019_HTL33373IMG_1919.JPG', N'8077783084', N'09AAACU4990N1ZM', N'KAN', N'Rahi Tourist Bungalow-Kannauj', NULL, N'1000300692', N'efec11755e', 11, N'RTBKJ', NULL, NULL, NULL, NULL, NULL, 19, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (28, N'HTL38049', N'Rahi Triveni Darshan', 1, 15, NULL, N'Yamuna Bank Road, Kydganj, Prayagraj (Allahabad), Uttar Pradesh-211003', N'9415311133', N'<p>The Hotel Triveni Darshan is located on the banks of the river Yamuna, just upstream the holy Sangam. The property has been tastefully done up. Enjoy a serene evening watching the&nbsp;quietly flowing Yamuna from the expansive lawn in the property. Access the Sangam for a holy dip directly from here on a boat. Watch the beautifully lit up Shastri Bridge and appreciate the piece of history while you pass by the great Akbar&#39;s Fort before you reach Sangam.&nbsp;Also enjoy a great view of the Yamuna from within the room.</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2019-07-13T17:24:58.377' AS DateTime), 1, N'trivenidarshan@upstdc.co.in', N'HotelImages/03002019_HTL38049IMG_1039.JPG', N'0532-2558646', N'09AAACU4990N1ZM', N'TVD', N'Rahi Triveni Darshan-Prayagraj (Allahabad)', 10, N'1000300707', N'0f1d2d77d7', 18, N'RTDA', N'12714005000315', NULL, NULL, NULL, NULL, 6, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (7, N'HTL39354', N'Rahi Tourist Bungalow', 1, 14, NULL, N'Pakshi Vihar Lucknow- Kanpur Road, Nawabganj, Unnao, Uttar Pradesh-209859', N'9415311134', N'<p>The Tourist Bungalow is located in the serene surroundings of the Nawabganj Bird Sanctuary. The&nbsp;rooms have been done up tastefully. Ideal place to stay when&nbsp;visiting the Sanctuary to watch the birds. Witness scores of butterflies occupying the diverse habitat maintained within the property, as well as beyond.&nbsp;Also suitable&nbsp;for a comfortable break, away from hustle-bustle of the cities. Organise consultations in the nice conference room, enjoy cosy sit-outs in the nice big lawn before retiring into comfortable rooms.</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2019-07-06T14:48:46.983' AS DateTime), 1, N'nawabganj@upstdc.co.in', N'HotelImages/30002019_HTL393542908-2019-090011331207338334963.jpeg', N'0514-3297297', N'09AAACU4990N1ZM', N'NBJ', N'Rahi Tourist Bungalow-Nawabganj', 10, N'1000299868', N'81466184ff', 16, N'RTBNAWAB', NULL, NULL, NULL, NULL, NULL, 14, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (25, N'HTL51674', N'Hotel Jahnavi', 1, 12, NULL, N'Near Shashtri Bridge, Mirzapur, Uttar Pradesh-231312', N'8004494476', N'<p>The Hotel Jahnavi is located on the banks of the holy Ganga. It affords a nice view of the river from within the propoerty as well as from the expansive lawn. Stay at Jahnavi for a quite evening and to enjoy the serene flow the holy Ganga. Be a part of aarti at the Ma Vindhyavasini Devi temple located at Vindhyachal hills.</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2019-07-13T16:56:22.950' AS DateTime), 1, N'mirzapur@upstdc.co.in', N'HotelImages/14002019_HTL51674IMG_1124.JPG', N'8004494476', N'09AAACU4990N1ZM', N'MZP', N'Hotel Jahnavi-Mirzapur', NULL, N'1000299823', N'b20a46a01c', 14, N'HJAHNAVI', NULL, NULL, NULL, NULL, NULL, 20, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (3, N'HTL63683', N'Hotel Saket', 1, 2, NULL, N'Near Ayodhya Railway Station, Ayodhya, Uttar Pradesh-224123', N'9412526465', N'<p>Hotel Saket is situated at a&nbsp;walking distance from the Ayodhya Railway Station making it easily accessible any time of the day. The hotel has variety of rooms to suit everyone&#39;s needs. Stay at Saket to conveniently visit the historical and religious landmarks of the city.</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2019-07-06T12:45:28.717' AS DateTime), 1, N'ayodhya@upstdc.co.in', N'HotelImages/03002019_HTL63683IMG_0905.JPG', N'05278-232435', N'09AAACU4990N1ZM', N'TBA', N'Hotel Saket-Ayodhya', NULL, N'1000299691', N'dfe9496fac', 3, N'HSAY', NULL, NULL, NULL, NULL, NULL, 22, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (30, N'HTL66042', N'Rahi Tourist Bungalow Sarnath', 1, 17, NULL, N'Sarnath Station Road, Near Maha Bodhi Inter College, Ashok Rd, Baraipur, Sarnath, Varanasi, Uttar Pradesh-221007', N'9415902707', N'<p>The Tourist Bungalow Sarnath is located within walking distances from the Sarnath landmarks, the Dhamek Stupa, the&nbsp;Dharmarajika Stupa and the Chaukhandi Stupa as well as the Archeological Museum, the present home to the Lion Capital.&nbsp;The birthplace of thirteenth Jain Theerthankar is also nearby. Stay at&nbsp;Tourist Bungalow Sarnath while you experience the all-pervasive presence of Lord Buddha and learn his teachings. The Tourist Bungalow assures you a serene feeling and a comfortable stay.</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2019-07-13T17:47:33.813' AS DateTime), 1, N'sarnath@upstdc.co.in', N'HotelImages/14002019_HTL66042IMG_1_1332.JPG', N'0542-2595965', N'09AAACU4990N1ZM', N'SAR', N'Rahi Tourist Bungalow Sarnath-Sarnath, Varanasi', 11, N'1000299860', N'f80fed451b', 23, N'RTBS', N'12714038000198', CAST(N'2026-04-22' AS Date), NULL, NULL, NULL, 4, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (4, N'HTL68300', N'Rahi Tourist Bungalow', 1, 3, NULL, N'Bahraich Rd, Pahalwara, Balrampur, Uttar Pradesh-271201', N'9415013781', N'<p>Nicely loacted in the heart of the city, the Rahi Toursit Bungalow, Balrampur is the ideal place to stay. The Restaurant serves its guests delicious food to complete the stay experience. The Tourist Bungalow has a banquet hall for gatherings as well as open lawn for bigger events.</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2019-07-06T13:05:08.657' AS DateTime), 1, N'balrampur@upstdc.co.in', N'HotelImages/03002019_HTL68300IMG_1644.JPG', N'05263-232456', N'09AAACU4990N1ZM', N'BLM', N'Rahi Tourist Bungalow-Balrampur', NULL, N'1000299864', N'97bb31fa61', 5, N'RTBBP', NULL, NULL, NULL, NULL, NULL, 15, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (20, N'HTL78404', N'Hotel Alaknanda', 1, 7, 1, N'Near Belwala Delhi Road Bypass, P.O.-Kankhel, Haridwar, Uttrakhand-249401', N'9415019751', N'<p>The Alaknanda hotel is located on the Haridwar bypass road and has ample parking. Away from hustle-bustle of the city, it provides peaceful environs to enjoy the serenity of the swiftly flowing Ganga. Witness the forever flowing water from the beautiful lawn&nbsp;of the property, or from the steps of the Ghat maintained by us. Purify yourself by taking a dip. Stroll on the promenade along the river in the morning to watch the interplay of sun-rays, or walk all the way to Har ki Paidi to witness the Maha-Arati in the evening.</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2019-07-13T15:26:36.463' AS DateTime), 1, N'alaknanda@upstdc.co.in', N'HotelImages/03002019_HTL78404IMG_2.JPG', N'01334-226379, 225788', N'05AAACU4990N2ZT', N'HWR', N'Hotel Alaknanda-Haridwar', NULL, N'1000306325', N'8ca145a5a5', 9, N'HAKND', N'12616006000048', NULL, NULL, NULL, NULL, 1, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (88, N'HTL78999', N'Hotel Bhagirathi', 1, 7, 1, N'Near Belwala Delhi Road Bypass, P.O.-Kankhel, Haridwar, Uttrakhand-249401', N'9415019751', N'<p>The Bhagirathi hotel is located on the Haridwar bypass road and has ample parking. Away from hustle-bustle of the city, it provides peaceful environs to enjoy the serenity of the swiftly flowing Ganga. Witness the forever flowing water from the beautiful lawn&nbsp;of the property, or from the steps of the Ghat maintained by us. Purify yourself by taking a dip. Stroll on the promenade along the river in the morning to watch the interplay of sun-rays, or walk all the way to Har ki Paidi to witness the Maha-Arati in the evening.</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2021-08-26T19:25:36.570' AS DateTime), 1, N'upbhagirathi@upstdc.co.in', N'HotelImages/03002021_HTL789991432332324.jpg', N'01334-226379, 225788', N'05AAACU4990N2ZT', N'BHA', N'Hotel Bhagirathi', NULL, NULL, NULL, 35, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (6, N'HTL82734', N'Hotel Gomti', 1, 11, NULL, N'6, Tej Bahadur Sapru Marg, Near Sahara Ganj Mall, Hazratganj, Lucknow, Uttar Pradesh-226001', N'9415233498', N'<p>Hotel Gomti is ideally located in the heart of town, close to Hazratganj. All major cultural, historical and shopping&nbsp;landmarks of the city are nearby.&nbsp;It has well furnished and tastefully done up rooms equipped with modern amenities including wi-fi. There are various types of rooms to suit every budget. The restaurant serves great food. The hotel has&nbsp;a&nbsp;bar with a nice lush green lawn for the&nbsp;evening drink. It also&nbsp;has a full fledged travel division to meet the guests&#39;&nbsp;travel needs as well to conduct&nbsp;tours to witness the history and culture of the city. The hotel has ample parking space and faciltiies to conduct meetings and events.</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2019-07-06T13:42:08.673' AS DateTime), 1, N'gomti@upstdc.co.in', N'HotelImages/19002019_HTL82734DSC_0189.jpg', N'0522-4024050, 4024062', N'09AAACU4990N1ZM', N'LUC', N'Hotel Gomti-Lucknow', 3, N'1000299488', N'2d0e389340', 13, N'HGOMTI', NULL, NULL, NULL, NULL, NULL, 2, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (19, N'HTL87951', N'Rahi Tourist Bungalow', 1, 5, NULL, N'Near Poddar Inter College, Chitrakoot, Uttar Pradesh-210204', N'9415233445', N'<p>Tourist Bungalow is running with the aim of providing utmost comfort and homely atmosphere to its guests and is highly desperate &nbsp;to give them a satisfactory and stress free stay in a spiritual and peaceful environment.</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2019-07-13T15:18:10.577' AS DateTime), 1, N'chitrakoot@upstdc.co.in', N'HotelImages/03002019_HTL87951IMG_2064.JPG', N'05198-298183', N'09AAACU4990N1ZM', N'CHK', N'Rahi Tourist Bungalow-Chitrakoot', 6, N'1000301262', N'8751e4eb95', 7, N'RTBCK', NULL, NULL, NULL, NULL, NULL, 12, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (27, N'HTL87980', N'Rahi Ilawart Tourist Bungalow', 1, 15, NULL, N'35, M.G. Marg Civil Line, Prayagraj (Allahabad), Uttar Pradesh-211001', N'9415311133', N'<p>Rahi Ilawart Tourist Bungalow Hotel is conveniently located near the bus station and is well connected to the railway station. It has tastefully decorated rooms to suit various budget levels. The hotel is well located to access the major tourist as well as business destinations of the city. The hotel has a well stocked bar and a restaurant to enjoy variety of liquors and&nbsp;sumotuous food served therein.</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2019-07-13T17:21:54.563' AS DateTime), 1, N'ilawart@upstdc.co.in', N'HotelImages/03002019_HTL87980IMG_1_0901.JPG', N'0532-2408377, 2408333', N'09AAACU4990N1ZM', N'ILA', N'Rahi Ilawart Tourist Bungalow-Prayagraj (Allahabad)', 5, N'1000299670', N'98adf10d97', 17, N'RHI', N'12714005000316', NULL, NULL, NULL, NULL, 5, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (22, N'HTL91324', N'Rahi Veerangana Tourist Bungalow', 1, 8, NULL, N'Near Exhibition Ground (Atal Park), Civil Line, Jhansi, Uttar Pradesh-284003', N'9415233442', N'<p>From comfortable accomodation to culinary delights and business events Hotel Veerangana offers them all, stay at Veerangana promises a hospitality that will leave guests with an experience to remember.</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2019-07-13T15:46:48.817' AS DateTime), 1, N'veerangana@upstdc.co.in', N'HotelImages/03002019_HTL91324IMG_1995.JPG', N'0510-2449473', N'09AAACU4990N1ZM', N'JHN', N'Rahi Veerangana Tourist Bungalow-Jhansi', 10, N'1000299699', N'badf60211d', 10, N'VEERA', NULL, NULL, NULL, NULL, NULL, 13, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (31, N'HTL91840', N'Rahi Tourist Bungalow', 1, 19, NULL, N'Katra Shrawasti Marg, Shravasti, Uttar Pradesh-271805', N'9415013781', N'<p>Tourist Bungalow&#39;s easy accessibility make it a popular choice among guests. The rooms hava a nice decor and are well-equipped with all amenities that offer a comfortable staying experience. The restaurant offers a delectable spread to savour your taste buds. Revel in comfort and convenience at one of the best hotels in Shrawasti</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2019-07-13T17:55:14.417' AS DateTime), 1, N'shravasti@upstdc.co.in', N'HotelImages/03002019_HTL91840IMG_1810.JPG', N'9415013781', N'09AAACU4990N1ZM', N'SRW', N'Rahi Tourist Bungalow-Shravasti', NULL, N'1000306306', N'e37065be83', 20, N'RTBSH', NULL, NULL, NULL, NULL, NULL, 17, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (14, N'HTL92418', N'Tourist Bunglow (Hotel Saras)', 1, 16, NULL, N'Malikmau Crossing, Gol Chauraha, Raebareli, Uttar Pradesh-229001', N'5270662072', N'<p>Strategically located on the National Highway, right at Malikmau crossing, this proporty is an ideal place to stay in Raebareli. It offers variety of rooms to suit everyone&#39;s need. Whether you are visiting the town to watch birds in Samaspur Brid Sanctuary or for business engagements in the industries and institutions located here, the Hotel Saras is the ideal choice to stay.</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2019-07-12T19:37:57.893' AS DateTime), 1, N'raibareli@upstdc.co.in', N'HotelImages/03002019_HTL92418IMG_0809.JPG', N'0535-2702072', N'09AAACU4990N1ZM', N'RBL', N'Hotel Saras-Raebareli', 11, N'1000299724', N'c43274a6d4', 19, N'SARAS', N'12715071000008', NULL, NULL, NULL, NULL, 11, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (2, N'HTL97314', N'Hotel Tajkhema', 1, 1, NULL, N'Near Eastern Gate of Taj Mahal, Tajganj, Agra, Uttar Pradesh-282001', N'9415902742', N'<p>The closest view of the Taj in town from within the property. Enjoy the most romantic tea, with the Taj in background, an experience, no one else can give. Spend some quiet time in front of the moonlit wonder in marble. To protect environment around&nbsp;the Taj, only battery operated transport is permitted in the vicinity and is available&nbsp;from Shilpgram parking to reach the property.</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2019-07-06T11:27:05.117' AS DateTime), 1, N'tajkhema@upstdc.co.in', N'HotelImages/03002019_HTL97314IMG_1775-Edit.JPG', N'9415902742', N'09AAACU4990N1ZM', N'TAJ', N'Hotel Tajkhema-Agra', 6, N'1000299650', N'937c904b9f', 2, N'HTJK', NULL, NULL, NULL, NULL, NULL, 9, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (18, N'HTL99957', N'Rahi Hotel Rohila', 1, 4, NULL, N'2, Civil Lines, Near Gandhi Udyan, Bareilly, Uttar Pradesh-243001', N'9149099890', N'<p>Located at a prime location in Civil lines, this hotel has all the major landmarks of the city nearby. It has convenient connection to the Railway Station as well as to the Bus Station. The hotel has a tastefully done up Bar and Restaurant serving variety of liquors and sumptuous food. Enjoy a relaxed cosy evening in the lush green lawn of the property and a morning stroll in the Gandhi Udyan adjoining. The property also has a banquet hall to organise business seminars and other events.</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2019-07-13T15:02:51.560' AS DateTime), 1, N'rohila@upstdc.co.in', N'HotelImages/03002019_HTL99957IMG_1403.JPG', N'0581-2510447, 2422862', N'09AAACU4990N1ZM', N'BLY', N'Rahi Hotel Rohila-Bareilly', 6, N'1000299676', N'ae64e53eab', 6, N'RHRBY', NULL, NULL, N'Rahi-Hotel-Rohila,Bareilly', N'http://upstdc.co.in//#Rahi-Hotel-Rohila,Bareilly', NULL, 16, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (52, N'LKO52', N'Def Expo', 1, 11, 1, N'Sector 9 avadh vihar yojna,Lucknow', N'9999999999', N'<p>Def Expo</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2020-01-27T10:18:25.880' AS DateTime), 0, N'defexpo@upstdc.co.in', NULL, N'0522 2308017', N'09AAACU4990N1ZM', NULL, N'Def Expo-Lucknow', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (97, N'LTC00001', N'Lcuknow Tent City(Available only 13,14,15 FEB)', 1, 11, 1, N'Uttar Pradesh-211001', N'9415013039', N'<p>LUCKNOW TENT CITY</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2019-07-13T17:21:54.563' AS DateTime), 1, N'uptbithoor@gmail.com', N'HotelImages/LTC6.jpeg', N'0532-2408377, 2408333', N'09AAACU4990N1ZM', N'LTC', N'LUCKNOW TENT CITY(LUCKNOW)', NULL, NULL, NULL, 17, N'LTC', NULL, NULL, NULL, NULL, NULL, 5, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (63, N'MAU64', N'Rahi Tourist Bungalow', 1, 32, NULL, N'NH-29, Gontha Bazar, DohriGhat, Mau, Uttar Pradesh-275303', N'9415013039', N'<p>Rahi Tourist Bungalow</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2021-01-21T13:47:36.390' AS DateTime), 1, N'uptdohrighat@gmail.com', N'HotelImages/20210127_123707.jpg', N'9415013039', N'09AAACU4990N1ZM', N'DHR', N'Rahi Tourist Bungalow-Mau', NULL, NULL, NULL, 26, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (59, N'MHJ60', N'Rahi Tourist Bungalow  ', 1, 37, NULL, N'Nautanwa, Nepal Border, Sonauli, Maharajganj, Uttar Pradesh-273308', N'9415233440', N'<p>Rahi Tourist Bungalow ,Sunauli</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2021-01-21T12:56:55.863' AS DateTime), 1, N'rahiniranjana@gmail.com', N'HotelImages/IMG-20210125-WA0026.jpg', N'05522-238944', N'09AAACU4990N1ZM', N'SNL', N'Rahi Tourist Bungalow-Maharajganj', NULL, NULL, NULL, 29, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (62, N'MIR63', N'Yatri Niwas, Vindhyachal ', 1, 40, NULL, N'Partar Tiraha, Near Hanuman Mandir, Vindhyachal, Mirzapur, Uttar Pradesh-231307', N'8004494476', N'<p>Rahi Tourist Bungalow</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2021-01-21T13:46:00.020' AS DateTime), 1, N'uptvindhyachal@gmail.com', N'HotelImages/DSC_0496.jpg', N'8004494476', N'09AAACU4990N1ZM', N'RMZ', N'Rahi Tourist Bungalow-Mirzapur', NULL, NULL, NULL, 32, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (61, N'SIT62', N'Rahi Tourist Bungalow ', 1, 41, NULL, N'Near Old Bus Stand, Neemsar, Uttar Pradesh-261402', N'9453059636', N'<p>Rahi Tourist Bungalow</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2021-01-21T13:44:04.050' AS DateTime), 1, N'uptneemsar@gmail.com', N'HotelImages/neemsar.jpg', N'9453059636', N'09AAACU4990N1ZM', N'NMS', N'Rahi Tourist Bungalow-Sitapur', NULL, NULL, NULL, 31, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL)
GO
INSERT [dbo].[tbl_HotelMaster] ([ID], [HotelId], [HotelName], [StateId], [CityId], [isOffline], [Address], [ContactNo], [Description], [Longitude], [Latitude], [EntryDate], [IsActive], [EmailId], [ImageURL], [Landline], [GSTNo], [HotalCodenew], [HotelName_City], [Counter_BillNo], [MMT_HotelCode], [MMT_AccessToken], [PatternID], [IRCTC_HotelCode], [FSSAINo], [ValidDate], [HOtel_UrlNew], [RedirectURL], [AccessToken], [Category], [NoOfRooms]) VALUES (95, N'TTC00001', N'Triveni Tent City', 1, 15, 1, N'Uttar Pradesh-211001', N'9415311133', N'<p>Triveni Tent City, Prayagraj.</p>
', CAST(0.000000 AS Numeric(18, 6)), CAST(0.000000 AS Numeric(18, 6)), CAST(N'2019-07-13T17:21:54.563' AS DateTime), 1, N'ilawart@upstdc.co.in', N'HotelImages/fghjkfdhgkjfdhjkgh.jpeg', N'0532-2408377, 2408333', N'09AAACU4990N1ZM', N'TTC', N'Rahi Ilawart Tourist Bungalow-Prayagraj (Allahabad)', NULL, NULL, NULL, 17, N'TTC', NULL, NULL, NULL, NULL, NULL, 5, NULL)
GO
SET IDENTITY_INSERT [dbo].[tbl_HotelMaster] OFF
GO
SET IDENTITY_INSERT [dbo].[tbl_RoomDetail] ON 
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (2275, N'1', N'HTL91840', 84, 0, CAST(N'2019-08-01T18:11:03.097' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (2276, N'2', N'HTL91840', 84, 0, CAST(N'2019-08-01T18:11:03.097' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (2277, N'3', N'HTL91840', 85, 1, CAST(N'2019-08-01T18:11:22.690' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (2278, N'4', N'HTL91840', 85, 1, CAST(N'2019-08-01T18:11:22.690' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (2279, N'5', N'HTL91840', 86, 0, CAST(N'2019-08-01T18:11:33.520' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (2280, N'6', N'HTL91840', 86, 0, CAST(N'2019-08-01T18:11:33.520' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (2281, N'7', N'HTL91840', 86, 1, CAST(N'2019-08-01T18:11:33.520' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (2282, N'8', N'HTL91840', 86, 1, CAST(N'2019-08-01T18:11:33.520' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (2283, N'9', N'HTL91840', 86, 1, CAST(N'2019-08-01T18:11:33.520' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (2284, N'10', N'HTL91840', 86, 1, CAST(N'2019-08-01T18:11:33.520' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4155, N'001', N'HTL18824', 66, 1, CAST(N'2019-12-13T17:19:03.033' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4156, N'002', N'HTL18824', 66, 1, CAST(N'2019-12-13T17:19:03.097' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4157, N'003', N'HTL18824', 66, 1, CAST(N'2019-12-13T17:19:03.173' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4158, N'004', N'HTL18824', 66, 1, CAST(N'2019-12-13T17:19:03.220' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4159, N'005', N'HTL18824', 66, 1, CAST(N'2019-12-13T17:19:03.267' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4160, N'006', N'HTL18824', 66, 1, CAST(N'2019-12-13T17:19:03.330' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4161, N'007', N'HTL18824', 66, 1, CAST(N'2019-12-13T17:19:03.393' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4162, N'101', N'HTL18824', 66, 1, CAST(N'2019-12-13T17:19:03.457' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4163, N'102', N'HTL18824', 66, 1, CAST(N'2019-12-13T17:19:03.503' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4164, N'105', N'HTL18824', 66, 1, CAST(N'2019-12-13T17:19:03.580' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4165, N'106', N'HTL18824', 66, 1, CAST(N'2019-12-13T17:19:03.660' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4166, N'107', N'HTL18824', 66, 1, CAST(N'2019-12-13T17:19:03.720' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4167, N'109', N'HTL18824', 66, 1, CAST(N'2019-12-13T17:19:03.767' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4174, N'108', N'HTL10191', 2, 1, CAST(N'2019-12-13T17:25:30.607' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4175, N'109', N'HTL10191', 2, 1, CAST(N'2019-12-13T17:25:30.653' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4176, N'201', N'HTL10191', 2, 1, CAST(N'2019-12-13T17:25:30.717' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4177, N'210', N'HTL10191', 2, 1, CAST(N'2019-12-13T17:25:30.763' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4178, N'214', N'HTL10191', 2, 1, CAST(N'2019-12-13T17:25:30.810' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4179, N'215', N'HTL10191', 2, 1, CAST(N'2019-12-13T17:25:30.890' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4180, N'216', N'HTL10191', 2, 0, CAST(N'2019-12-13T17:25:30.920' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4181, N'217', N'HTL10191', 2, 0, CAST(N'2019-12-13T17:25:30.967' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4182, N'301', N'HTL10191', 2, 1, CAST(N'2019-12-13T17:25:31.013' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4183, N'302', N'HTL10191', 2, 0, CAST(N'2019-12-13T17:25:31.060' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4184, N'303', N'HTL10191', 2, 1, CAST(N'2019-12-13T17:25:31.093' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4185, N'104', N'HTL10191', 3, 1, CAST(N'2019-12-13T17:34:22.640' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4186, N'105', N'HTL10191', 3, 1, CAST(N'2019-12-13T17:34:22.737' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4187, N'106', N'HTL10191', 3, 1, CAST(N'2019-12-13T17:34:22.793' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4188, N'107', N'HTL10191', 3, 1, CAST(N'2019-12-13T17:34:22.857' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4189, N'110', N'HTL10191', 3, 1, CAST(N'2019-12-13T17:34:22.890' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4190, N'111', N'HTL10191', 3, 1, CAST(N'2019-12-13T17:34:22.937' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4191, N'204', N'HTL10191', 3, 0, CAST(N'2019-12-13T17:34:23.093' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4192, N'205', N'HTL10191', 3, 0, CAST(N'2019-12-13T17:34:23.153' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4193, N'206', N'HTL10191', 3, 0, CAST(N'2019-12-13T17:34:23.217' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4194, N'207', N'HTL10191', 3, 1, CAST(N'2019-12-13T17:34:23.263' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4195, N'208', N'HTL10191', 3, 0, CAST(N'2019-12-13T17:34:23.327' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4196, N'209', N'HTL10191', 3, 0, CAST(N'2019-12-13T17:34:23.390' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4197, N'211', N'HTL10191', 3, 1, CAST(N'2019-12-13T17:34:23.437' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4198, N'212', N'HTL10191', 3, 1, CAST(N'2019-12-13T17:34:23.483' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4199, N'304', N'HTL10191', 4, 1, CAST(N'2019-12-13T17:34:55.970' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4200, N'305', N'HTL10191', 4, 0, CAST(N'2019-12-13T17:34:56.047' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4201, N'306', N'HTL10191', 4, 1, CAST(N'2019-12-13T17:34:56.110' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4202, N'307', N'HTL10191', 4, 0, CAST(N'2019-12-13T17:34:56.173' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4203, N'308', N'HTL10191', 4, 1, CAST(N'2019-12-13T17:34:56.250' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4204, N'309', N'HTL10191', 4, 1, CAST(N'2019-12-13T17:34:56.313' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4235, N'107', N'HTL82734', 24, 1, CAST(N'2019-12-13T17:59:06.507' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4236, N'109', N'HTL82734', 24, 1, CAST(N'2019-12-13T17:59:06.553' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4237, N'110', N'HTL82734', 24, 1, CAST(N'2019-12-13T17:59:06.600' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4238, N'111', N'HTL82734', 24, 1, CAST(N'2019-12-13T17:59:06.647' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4239, N'112', N'HTL82734', 24, 1, CAST(N'2019-12-13T17:59:06.677' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4240, N'113', N'HTL82734', 24, 1, CAST(N'2019-12-13T17:59:06.723' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4241, N'114', N'HTL82734', 24, 1, CAST(N'2019-12-13T17:59:06.770' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4242, N'115', N'HTL82734', 24, 1, CAST(N'2019-12-13T17:59:06.820' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4243, N'116', N'HTL82734', 24, 1, CAST(N'2019-12-13T17:59:06.850' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4244, N'117', N'HTL82734', 24, 1, CAST(N'2019-12-13T17:59:06.897' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4245, N'118', N'HTL82734', 24, 1, CAST(N'2019-12-13T17:59:06.943' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4246, N'119', N'HTL82734', 24, 1, CAST(N'2019-12-13T17:59:06.973' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4247, N'120', N'HTL82734', 24, 1, CAST(N'2019-12-13T17:59:07.053' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4248, N'207', N'HTL82734', 24, 1, CAST(N'2019-12-13T17:59:07.117' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4249, N'307', N'HTL82734', 24, 1, CAST(N'2019-12-13T17:59:07.163' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4250, N'407', N'HTL82734', 24, 1, CAST(N'2019-12-13T17:59:07.210' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4251, N'507', N'HTL82734', 24, 1, CAST(N'2019-12-13T17:59:07.273' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4258, N'005', N'HTL82734', 25, 0, CAST(N'2019-12-13T18:04:02.480' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4259, N'006', N'HTL82734', 25, 0, CAST(N'2019-12-13T18:04:02.527' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4260, N'007', N'HTL82734', 25, 0, CAST(N'2019-12-13T18:04:02.560' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4261, N'008', N'HTL82734', 25, 0, CAST(N'2019-12-13T18:04:02.623' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4262, N'010', N'HTL82734', 25, 0, CAST(N'2019-12-13T18:04:02.687' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4263, N'011', N'HTL82734', 25, 0, CAST(N'2019-12-13T18:04:02.733' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4296, N'101', N'HTL33373', 56, 0, CAST(N'2019-12-13T18:12:44.547' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4297, N'102', N'HTL33373', 55, 0, CAST(N'2019-12-13T18:13:08.220' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4298, N'103', N'HTL33373', 55, 1, CAST(N'2019-12-13T18:13:08.283' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4299, N'104', N'HTL33373', 55, 1, CAST(N'2019-12-13T18:13:08.330' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4300, N'107', N'HTL91324', 91, 1, CAST(N'2019-12-13T18:14:17.710' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4301, N'101', N'HTL91324', 106, 1, CAST(N'2019-12-13T18:15:05.760' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4302, N'102', N'HTL91324', 106, 1, CAST(N'2019-12-13T18:15:05.807' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4303, N'103', N'HTL91324', 106, 1, CAST(N'2019-12-13T18:15:05.867' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4304, N'206', N'HTL91324', 106, 1, CAST(N'2019-12-13T18:15:05.913' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4305, N'001', N'HTL92418', 74, 1, CAST(N'2019-12-13T23:24:01.787' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4306, N'002', N'HTL92418', 74, 1, CAST(N'2019-12-13T23:24:01.897' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4307, N'003', N'HTL92418', 74, 1, CAST(N'2019-12-13T23:24:02.007' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4308, N'004', N'HTL92418', 74, 1, CAST(N'2019-12-13T23:24:02.100' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4309, N'005', N'HTL92418', 75, 1, CAST(N'2019-12-13T23:25:07.547' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4310, N'006', N'HTL92418', 75, 1, CAST(N'2019-12-13T23:25:07.577' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4311, N'007', N'HTL92418', 75, 1, CAST(N'2019-12-13T23:25:07.627' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4312, N'008', N'HTL92418', 75, 1, CAST(N'2019-12-13T23:25:07.673' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4313, N'009', N'HTL92418', 75, 1, CAST(N'2019-12-13T23:25:07.720' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4314, N'010', N'HTL92418', 75, 1, CAST(N'2019-12-13T23:25:07.767' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4315, N'101', N'HTL92418', 75, 1, CAST(N'2019-12-13T23:25:07.797' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4316, N'102', N'HTL92418', 75, 1, CAST(N'2019-12-13T23:25:07.843' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4317, N'103', N'HTL92418', 75, 1, CAST(N'2019-12-13T23:25:07.890' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4318, N'104', N'HTL92418', 75, 1, CAST(N'2019-12-13T23:25:07.937' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4319, N'105', N'HTL92418', 75, 1, CAST(N'2019-12-13T23:25:07.970' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4320, N'106', N'HTL92418', 75, 1, CAST(N'2019-12-13T23:25:08.017' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4321, N'01', N'HTL16720', 81, 1, CAST(N'2019-12-13T23:26:02.240' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4322, N'02', N'HTL16720', 81, 1, CAST(N'2019-12-13T23:26:02.287' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4323, N'108', N'HTL16720', 99, 1, CAST(N'2019-12-13T23:27:56.117' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4324, N'109', N'HTL16720', 99, 1, CAST(N'2019-12-13T23:27:56.147' AS DateTime), 1, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4325, N'110', N'HTL16720', 99, 1, CAST(N'2019-12-13T23:27:56.193' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4326, N'111', N'HTL16720', 99, 0, CAST(N'2019-12-13T23:27:56.240' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4327, N'127', N'HTL16720', 99, 0, CAST(N'2019-12-13T23:27:56.287' AS DateTime), 1, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4328, N'128', N'HTL16720', 99, 0, CAST(N'2019-12-13T23:27:56.350' AS DateTime), 1, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4329, N'129', N'HTL16720', 99, 1, CAST(N'2019-12-13T23:27:56.397' AS DateTime), 1, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4330, N'130', N'HTL16720', 99, 1, CAST(N'2019-12-13T23:27:56.443' AS DateTime), 1, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4331, N'131', N'HTL16720', 99, 1, CAST(N'2019-12-13T23:27:56.477' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4332, N'132', N'HTL16720', 99, 1, CAST(N'2019-12-13T23:27:56.523' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4333, N'139', N'HTL16720', 99, 1, CAST(N'2019-12-13T23:27:56.570' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4334, N'140', N'HTL16720', 99, 1, CAST(N'2019-12-13T23:27:56.617' AS DateTime), 1, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4335, N'141', N'HTL16720', 99, 1, CAST(N'2019-12-13T23:27:56.647' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4336, N'142', N'HTL16720', 99, 1, CAST(N'2019-12-13T23:27:56.693' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4337, N'118', N'HTL16720', 100, 1, CAST(N'2019-12-13T23:29:08.447' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4338, N'119', N'HTL16720', 100, 1, CAST(N'2019-12-13T23:29:08.573' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4339, N'133', N'HTL16720', 100, 1, CAST(N'2019-12-13T23:29:08.697' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4340, N'120', N'HTL16720', 101, 0, CAST(N'2019-12-13T23:34:41.537' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4341, N'121', N'HTL16720', 101, 0, CAST(N'2019-12-13T23:34:41.583' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4342, N'122', N'HTL16720', 101, 0, CAST(N'2019-12-13T23:34:41.630' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4343, N'123', N'HTL16720', 101, 1, CAST(N'2019-12-13T23:34:41.677' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4344, N'124', N'HTL16720', 101, 1, CAST(N'2019-12-13T23:34:41.723' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4345, N'125', N'HTL16720', 101, 1, CAST(N'2019-12-13T23:34:41.770' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4346, N'126', N'HTL16720', 101, 1, CAST(N'2019-12-13T23:34:41.833' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4347, N'112', N'HTL16720', 102, 1, CAST(N'2019-12-13T23:35:30.823' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4348, N'113', N'HTL16720', 102, 1, CAST(N'2019-12-13T23:35:30.870' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4349, N'114', N'HTL16720', 102, 1, CAST(N'2019-12-13T23:35:30.917' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4350, N'115', N'HTL16720', 102, 1, CAST(N'2019-12-13T23:35:30.980' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4351, N'116', N'HTL16720', 102, 1, CAST(N'2019-12-13T23:35:31.027' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4352, N'117', N'HTL16720', 102, 1, CAST(N'2019-12-13T23:35:31.057' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4353, N'102', N'HTL16720', 80, 1, CAST(N'2019-12-13T23:36:15.293' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4354, N'103', N'HTL16720', 80, 1, CAST(N'2019-12-13T23:36:15.327' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4355, N'104', N'HTL16720', 80, 1, CAST(N'2019-12-13T23:36:15.373' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4356, N'105', N'HTL16720', 80, 0, CAST(N'2019-12-13T23:36:15.420' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4357, N'106', N'HTL16720', 80, 1, CAST(N'2019-12-13T23:36:15.450' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4358, N'107', N'HTL16720', 80, 0, CAST(N'2019-12-13T23:36:15.497' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4360, N'101', N'HTL66042', 82, 1, CAST(N'2019-12-13T23:37:32.990' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4361, N'102', N'HTL66042', 82, 1, CAST(N'2019-12-13T23:37:33.037' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4362, N'103', N'HTL66042', 82, 1, CAST(N'2019-12-13T23:37:33.070' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4363, N'104', N'HTL66042', 82, 1, CAST(N'2019-12-13T23:37:33.117' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4364, N'105', N'HTL66042', 82, 1, CAST(N'2019-12-13T23:37:33.163' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4365, N'106', N'HTL66042', 82, 1, CAST(N'2019-12-13T23:37:33.193' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4366, N'107', N'HTL66042', 82, 1, CAST(N'2019-12-13T23:37:33.240' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4367, N'108', N'HTL66042', 82, 1, CAST(N'2019-12-13T23:37:33.273' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4368, N'109', N'HTL66042', 82, 1, CAST(N'2019-12-13T23:37:33.320' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4539, N'106', N'HTL87951', 93, 1, CAST(N'2019-12-15T15:33:11.317' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4540, N'112', N'HTL87951', 93, 1, CAST(N'2019-12-15T15:33:11.457' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4541, N'208', N'HTL87951', 93, 0, CAST(N'2019-12-15T15:33:11.503' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4542, N'217', N'HTL87951', 93, 0, CAST(N'2019-12-15T15:33:11.550' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4545, N'105', N'HTL87951', 45, 1, CAST(N'2019-12-15T15:35:06.823' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4546, N'107', N'HTL87951', 45, 1, CAST(N'2019-12-15T15:35:06.853' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4547, N'108', N'HTL87951', 45, 1, CAST(N'2019-12-15T15:35:06.900' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4548, N'109', N'HTL87951', 45, 1, CAST(N'2019-12-15T15:35:06.950' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4549, N'110', N'HTL87951', 45, 1, CAST(N'2019-12-15T15:35:06.993' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4550, N'111', N'HTL87951', 45, 1, CAST(N'2019-12-15T15:35:07.027' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4551, N'212', N'HTL87951', 45, 0, CAST(N'2019-12-15T15:35:07.073' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4552, N'213', N'HTL87951', 45, 0, CAST(N'2019-12-15T15:35:07.120' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4553, N'214', N'HTL87951', 45, 0, CAST(N'2019-12-15T15:35:07.167' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4554, N'215', N'HTL87951', 45, 0, CAST(N'2019-12-15T15:35:07.230' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4555, N'216', N'HTL87951', 45, 0, CAST(N'2019-12-15T15:35:07.277' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4556, N'207', N'HTL87951', 45, 0, CAST(N'2019-12-15T15:35:07.340' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4557, N'101', N'HTL87951', 46, 1, CAST(N'2019-12-15T15:35:38.217' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4558, N'102', N'HTL87951', 46, 1, CAST(N'2019-12-15T15:35:38.263' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4559, N'103', N'HTL87951', 46, 0, CAST(N'2019-12-15T15:35:38.310' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4560, N'104', N'HTL87951', 46, 1, CAST(N'2019-12-15T15:35:38.357' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4561, N'201', N'HTL87951', 46, 0, CAST(N'2019-12-15T15:35:38.403' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4562, N'202', N'HTL87951', 46, 0, CAST(N'2019-12-15T15:35:38.590' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4563, N'203', N'HTL87951', 46, 0, CAST(N'2019-12-15T15:35:38.637' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4564, N'204', N'HTL87951', 46, 0, CAST(N'2019-12-15T15:35:38.700' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4565, N'205', N'HTL87951', 46, 0, CAST(N'2019-12-15T15:35:38.810' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4566, N'206', N'HTL87951', 46, 0, CAST(N'2019-12-15T15:35:38.887' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4567, N'101', N'HTL87980', 68, 1, CAST(N'2019-12-17T16:47:23.297' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4568, N'102', N'HTL87980', 68, 1, CAST(N'2019-12-17T16:47:23.420' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4569, N'103', N'HTL87980', 68, 1, CAST(N'2019-12-17T16:47:23.497' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4570, N'104', N'HTL87980', 68, 1, CAST(N'2019-12-17T16:47:23.560' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4571, N'105', N'HTL87980', 68, 1, CAST(N'2019-12-17T16:47:23.640' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4572, N'106', N'HTL87980', 68, 1, CAST(N'2019-12-17T16:47:23.700' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4573, N'107', N'HTL87980', 68, 1, CAST(N'2019-12-17T16:47:23.780' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4574, N'108', N'HTL87980', 68, 1, CAST(N'2019-12-17T16:47:23.843' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4575, N'109', N'HTL87980', 68, 1, CAST(N'2019-12-17T16:47:23.903' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4576, N'110', N'HTL87980', 68, 1, CAST(N'2019-12-17T16:47:24.107' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4577, N'201', N'HTL87980', 68, 1, CAST(N'2019-12-17T16:47:24.187' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4578, N'202', N'HTL87980', 68, 1, CAST(N'2019-12-17T16:47:24.263' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4579, N'203', N'HTL87980', 68, 1, CAST(N'2019-12-17T16:47:24.327' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4580, N'204', N'HTL87980', 68, 1, CAST(N'2019-12-17T16:47:24.410' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4581, N'205', N'HTL87980', 68, 1, CAST(N'2019-12-17T16:47:24.483' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4582, N'206', N'HTL87980', 68, 1, CAST(N'2019-12-17T16:47:24.560' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4583, N'207', N'HTL87980', 68, 1, CAST(N'2019-12-17T16:47:24.623' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4584, N'208', N'HTL87980', 68, 1, CAST(N'2019-12-17T16:47:24.687' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4585, N'209', N'HTL87980', 68, 1, CAST(N'2019-12-17T16:47:24.763' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4586, N'210', N'HTL87980', 68, 1, CAST(N'2019-12-17T16:47:24.827' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4587, N'211', N'HTL87980', 68, 1, CAST(N'2019-12-17T16:47:24.903' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4588, N'212', N'HTL87980', 68, 1, CAST(N'2019-12-17T16:47:24.983' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4589, N'GANGA_SUIT', N'HTL87980', 107, 1, CAST(N'2019-12-17T16:48:46.393' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4590, N'SARASWATI_SUIT', N'HTL87980', 107, 1, CAST(N'2019-12-17T16:48:46.753' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4591, N'YAMUNA_SUIT', N'HTL87980', 107, 1, CAST(N'2019-12-17T16:48:46.830' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4592, N'MANDAKINI_SUIT', N'HTL87980', 107, 1, CAST(N'2019-12-17T16:48:46.910' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4594, N'01', N'HTL87980', 69, 1, CAST(N'2019-12-17T16:50:04.633' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4595, N'02', N'HTL87980', 69, 1, CAST(N'2019-12-17T16:50:04.710' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4596, N'03', N'HTL87980', 69, 1, CAST(N'2019-12-17T16:50:04.790' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4597, N'04', N'HTL87980', 69, 1, CAST(N'2019-12-17T16:50:04.883' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4598, N'05', N'HTL87980', 69, 1, CAST(N'2019-12-17T16:50:04.947' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4599, N'06', N'HTL87980', 69, 1, CAST(N'2019-12-17T16:50:05.023' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4600, N'07', N'HTL87980', 69, 1, CAST(N'2019-12-17T16:50:05.133' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4601, N'08', N'HTL87980', 69, 1, CAST(N'2019-12-17T16:50:05.210' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4602, N'09', N'HTL87980', 69, 1, CAST(N'2019-12-17T16:50:05.273' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4603, N'10', N'HTL87980', 69, 1, CAST(N'2019-12-17T16:50:05.353' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4604, N'11', N'HTL87980', 69, 1, CAST(N'2019-12-17T16:50:05.477' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4605, N'12', N'HTL87980', 69, 1, CAST(N'2019-12-17T16:50:05.553' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4606, N'220', N'HTL87980', 69, 1, CAST(N'2019-12-17T16:50:05.617' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4607, N'221', N'HTL87980', 69, 1, CAST(N'2019-12-17T16:50:05.680' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4608, N'222', N'HTL87980', 69, 1, CAST(N'2019-12-17T16:50:05.757' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4609, N'223', N'HTL87980', 69, 1, CAST(N'2019-12-17T16:50:05.837' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4610, N'224', N'HTL87980', 69, 1, CAST(N'2019-12-17T16:50:05.897' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4611, N'225', N'HTL87980', 69, 1, CAST(N'2019-12-17T16:50:05.960' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4622, N'201', N'HTL91324', 53, 1, CAST(N'2019-12-19T12:37:02.600' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4623, N'202', N'HTL91324', 53, 1, CAST(N'2019-12-19T12:37:02.973' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4624, N'203', N'HTL91324', 53, 0, CAST(N'2019-12-19T12:37:03.053' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4625, N'204', N'HTL91324', 53, 1, CAST(N'2019-12-19T12:37:03.193' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4626, N'205', N'HTL91324', 53, 0, CAST(N'2019-12-19T12:37:03.303' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4627, N'104', N'HTL91324', 90, 1, CAST(N'2019-12-19T12:37:31.677' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4628, N'105', N'HTL91324', 90, 1, CAST(N'2019-12-19T12:37:31.763' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4629, N'106', N'HTL91324', 90, 1, CAST(N'2019-12-19T12:37:31.827' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4630, N'207', N'HTL91324', 90, 0, CAST(N'2019-12-19T12:37:31.883' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4631, N'208', N'HTL91324', 90, 1, CAST(N'2019-12-19T12:37:31.943' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4632, N'209', N'HTL91324', 90, 1, CAST(N'2019-12-19T12:37:32.007' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4633, N'210', N'HTL91324', 90, 1, CAST(N'2019-12-19T12:37:32.083' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4634, N'211', N'HTL91324', 90, 1, CAST(N'2019-12-19T12:37:32.193' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4635, N'212', N'HTL91324', 90, 1, CAST(N'2019-12-19T12:37:32.240' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4675, N'103', N'HTL18824', 65, 1, CAST(N'2019-12-26T19:30:17.513' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4676, N'104', N'HTL18824', 65, 1, CAST(N'2019-12-26T19:30:17.623' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4677, N'108', N'HTL18824', 65, 1, CAST(N'2019-12-26T19:30:17.750' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4678, N'210', N'HTL87951', 47, 0, CAST(N'2020-01-18T10:10:13.663' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4679, N'211', N'HTL87951', 47, 0, CAST(N'2020-01-18T10:10:13.773' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4697, N'110', N'HTL66042', 83, 1, CAST(N'2020-01-18T10:17:52.827' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4698, N'15', N'HTL87980', 108, 1, CAST(N'2020-01-18T10:19:40.053' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4699, N'GODAVARI_SUIT', N'HTL87980', 70, 1, CAST(N'2020-01-18T10:19:54.050' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4704, N'D-1', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4705, N'D-2', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4706, N'D-3', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4707, N'D-4', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4708, N'D-5', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4709, N'D-6', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4710, N'D-7', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4711, N'D-8', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4712, N'D-9', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4713, N'D-10', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4714, N'D-11', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4715, N'D-12', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4716, N'D-13', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4717, N'D-14', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4718, N'D-15', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4719, N'D-16', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4720, N'D-17', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4721, N'D-18', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4722, N'D-19', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4723, N'D-20', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4724, N'D-21', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4725, N'D-22', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4726, N'D-23', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4727, N'D-24', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4728, N'D-25', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4729, N'D-26', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4730, N'D-27', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4731, N'D-28', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4732, N'D-29', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4733, N'D-30', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4734, N'D-31', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4735, N'D-32', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4736, N'D-33', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4737, N'D-34', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4738, N'D-35', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4739, N'D-36', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4740, N'D-37', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4741, N'D-38', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4742, N'D-39', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4743, N'D-40', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4744, N'D-41', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4745, N'D-42', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4746, N'D-43', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4747, N'D-44', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4748, N'D-45', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4749, N'D-46', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4750, N'D-47', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4751, N'D-48', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4752, N'D-49', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4753, N'D-50', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4754, N'D-51', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4755, N'D-52', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4756, N'D-53', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4757, N'D-54', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4758, N'D-55', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4759, N'D-56', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4760, N'D-57', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4761, N'D-58', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4762, N'D-59', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4763, N'D-60', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4764, N'D-61', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4765, N'D-62', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4766, N'D-63', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4767, N'D-64', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4768, N'D-65', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4769, N'D-66', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4770, N'D-67', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4771, N'D-68', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4772, N'D-69', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4773, N'D-70', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4774, N'D-71', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4775, N'D-72', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4776, N'D-73', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4777, N'D-74', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4778, N'D-75', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4779, N'D-76', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4780, N'D-77', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4781, N'D-78', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4782, N'D-79', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4783, N'D-80', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4784, N'D-81', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4785, N'D-82', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4786, N'D-83', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4787, N'D-84', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4788, N'D-85', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4789, N'D-86', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4790, N'D-87', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4791, N'D-88', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4792, N'D-89', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4793, N'D-90', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4794, N'D-91', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4795, N'D-92', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4796, N'D-93', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4797, N'D-94', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4798, N'D-95', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4799, N'D-96', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4800, N'D-97', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4801, N'D-98', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4802, N'D-99', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4803, N'D-100', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4804, N'D-101', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4805, N'D-102', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4806, N'D-103', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4807, N'D-104', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4808, N'D-105', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4809, N'D-106', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4810, N'D-107', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4811, N'D-108', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4812, N'D-109', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4813, N'D-110', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4814, N'D-111', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4815, N'D-112', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4816, N'D-113', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4817, N'D-114', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4818, N'D-115', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4819, N'D-116', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4820, N'D-117', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4821, N'D-118', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4822, N'D-119', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4823, N'D-120', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4824, N'D-121', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4825, N'D-122', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4826, N'D-123', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4827, N'D-124', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4828, N'D-125', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4829, N'D-126', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4830, N'D-127', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4831, N'D-128', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4832, N'D-129', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4833, N'D-130', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4834, N'D-131', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4835, N'D-132', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4836, N'D-133', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4837, N'D-134', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4838, N'D-135', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4839, N'D-136', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4840, N'D-137', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4841, N'D-138', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4842, N'D-139', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4843, N'D-140', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4844, N'D-141', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4845, N'D-142', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4846, N'D-143', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4847, N'D-144', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4848, N'D-145', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4849, N'D-146', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4850, N'D-147', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4851, N'D-148', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4852, N'D-149', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4853, N'D-150', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4854, N'D-151', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4855, N'D-152', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4856, N'D-153', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4857, N'D-154', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4858, N'D-155', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4859, N'D-156', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4860, N'D-157', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4861, N'D-158', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4862, N'D-159', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4863, N'D-160', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4864, N'D-161', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4865, N'D-162', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4866, N'D-163', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4867, N'D-164', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4868, N'D-165', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4869, N'D-166', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4870, N'D-167', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4871, N'D-168', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4872, N'D-169', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4873, N'D-170', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4874, N'D-171', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4875, N'D-172', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4876, N'D-173', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4877, N'D-174', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4878, N'D-175', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4879, N'D-176', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4880, N'D-177', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4881, N'D-178', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4882, N'D-179', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4883, N'D-180', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4884, N'D-181', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4885, N'D-182', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4886, N'D-183', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4887, N'D-184', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4888, N'D-185', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4889, N'D-186', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4890, N'D-187', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4891, N'D-188', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4892, N'D-189', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4893, N'D-190', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4894, N'D-191', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4895, N'D-192', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4896, N'D-193', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4897, N'D-194', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4898, N'D-195', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4899, N'D-196', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4900, N'D-197', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4901, N'D-198', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4902, N'D-199', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4903, N'D-200', N'LKO52', 117, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4904, N'SD-1', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4905, N'SD-2', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4906, N'SD-3', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4907, N'SD-4', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4908, N'SD-5', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4909, N'SD-6', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4910, N'SD-7', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4911, N'SD-8', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4912, N'SD-9', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4913, N'SD-10', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4914, N'SD-11', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4915, N'SD-12', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4916, N'SD-13', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4917, N'SD-14', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4918, N'SD-15', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4919, N'SD-16', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4920, N'SD-17', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4921, N'SD-18', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4922, N'SD-19', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4923, N'SD-20', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4924, N'SD-21', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4925, N'SD-22', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4926, N'SD-23', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4927, N'SD-24', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4928, N'SD-25', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4929, N'SD-26', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4930, N'SD-27', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4931, N'SD-28', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4932, N'SD-29', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4933, N'SD-30', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4934, N'SD-31', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4935, N'SD-32', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4936, N'SD-33', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4937, N'SD-34', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4938, N'SD-35', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4939, N'SD-36', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4940, N'SD-37', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4941, N'SD-38', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4942, N'SD-39', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4943, N'SD-40', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4944, N'SD-41', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4945, N'SD-42', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4946, N'SD-43', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4947, N'SD-44', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4948, N'SD-45', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4949, N'SD-46', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4950, N'SD-47', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4951, N'SD-48', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4952, N'SD-49', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4953, N'SD-50', N'LKO52', 118, 1, CAST(N'2020-01-27T10:21:20.510' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4991, N'05', N'HTL78404', 97, 0, CAST(N'2020-02-24T15:59:55.733' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4992, N'010', N'HTL78404', 97, 0, CAST(N'2020-02-24T15:59:55.797' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4993, N'01', N'HTL10389', 52, 1, CAST(N'2020-06-25T13:17:39.723' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4994, N'02', N'HTL10389', 52, 1, CAST(N'2020-06-25T13:17:39.843' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4995, N'03', N'HTL10389', 52, 1, CAST(N'2020-06-25T13:17:39.923' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4996, N'04', N'HTL10389', 52, 1, CAST(N'2020-06-25T13:17:40.013' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4997, N'05', N'HTL10389', 52, 1, CAST(N'2020-06-25T13:17:40.207' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4998, N'06', N'HTL10389', 52, 1, CAST(N'2020-06-25T13:17:40.280' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (4999, N'07', N'HTL10389', 52, 1, CAST(N'2020-06-25T13:17:40.350' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5000, N'08', N'HTL10389', 52, 1, CAST(N'2020-06-25T13:17:40.397' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5001, N'09', N'HTL10389', 98, 1, CAST(N'2020-06-25T13:22:59.470' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5002, N'10', N'HTL10389', 98, 1, CAST(N'2020-06-25T13:22:59.517' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5003, N'11', N'HTL10389', 98, 1, CAST(N'2020-06-25T13:22:59.557' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5004, N'12', N'HTL10389', 98, 1, CAST(N'2020-06-25T13:22:59.620' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5005, N'13', N'HTL10389', 51, 0, CAST(N'2020-06-25T13:24:19.180' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5006, N'14', N'HTL10389', 51, 0, CAST(N'2020-06-25T13:24:19.260' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5007, N'15', N'HTL10389', 51, 1, CAST(N'2020-06-25T13:24:19.313' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5008, N'16', N'HTL10389', 51, 1, CAST(N'2020-06-25T13:24:19.360' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5009, N'17', N'HTL10389', 51, 0, CAST(N'2020-06-25T13:24:19.393' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5010, N'18', N'HTL10389', 51, 1, CAST(N'2020-06-25T13:24:19.440' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5011, N'19', N'HTL10389', 51, 1, CAST(N'2020-06-25T13:24:19.493' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5012, N'20', N'HTL10389', 51, 1, CAST(N'2020-06-25T13:24:19.523' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5013, N'21', N'HTL10389', 51, 1, CAST(N'2020-06-25T13:24:19.570' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5014, N'22', N'HTL10389', 51, 1, CAST(N'2020-06-25T13:24:19.623' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5015, N'23', N'HTL10389', 51, 1, CAST(N'2020-06-25T13:24:19.670' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5016, N'24', N'HTL10389', 51, 0, CAST(N'2020-06-25T13:24:19.710' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5043, N'101', N'ALL33', 113, 0, CAST(N'2020-08-13T13:11:30.647' AS DateTime), 1, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5044, N'104', N'ALL33', 113, 0, CAST(N'2020-08-13T13:11:30.727' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5047, N'1', N'HTL38049', 119, 1, CAST(N'2020-11-22T16:16:08.363' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5048, N'2', N'HTL38049', 119, 1, CAST(N'2020-11-22T16:16:08.380' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5049, N'3', N'HTL38049', 119, 1, CAST(N'2020-11-22T16:16:08.380' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5050, N'4', N'HTL38049', 119, 1, CAST(N'2020-11-22T16:16:08.397' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5051, N'5', N'HTL38049', 119, 1, CAST(N'2020-11-22T16:16:08.397' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5052, N'6', N'HTL38049', 119, 1, CAST(N'2020-11-22T16:16:08.397' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5053, N'7', N'HTL38049', 119, 1, CAST(N'2020-11-22T16:16:08.397' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5054, N'8', N'HTL38049', 119, 1, CAST(N'2020-11-22T16:16:08.413' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5055, N'9', N'HTL38049', 119, 1, CAST(N'2020-11-22T16:16:08.413' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5056, N'10', N'HTL38049', 119, 1, CAST(N'2020-11-22T16:16:08.413' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5057, N'11', N'HTL38049', 119, 1, CAST(N'2020-11-22T16:16:08.413' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5058, N'12', N'HTL38049', 119, 1, CAST(N'2020-11-22T16:16:08.413' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5059, N'13', N'HTL38049', 119, 1, CAST(N'2020-11-22T16:16:08.427' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5060, N'14', N'HTL38049', 119, 1, CAST(N'2020-11-22T16:16:08.427' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5061, N'15', N'HTL38049', 119, 1, CAST(N'2020-11-22T16:16:08.427' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5062, N'16', N'HTL38049', 119, 1, CAST(N'2020-11-22T16:16:08.427' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5063, N'17', N'HTL38049', 119, 1, CAST(N'2020-11-22T16:16:08.427' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5064, N'18', N'HTL38049', 119, 1, CAST(N'2020-11-22T16:16:08.443' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5065, N'19', N'HTL38049', 119, 1, CAST(N'2020-11-22T16:16:08.443' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5066, N'20', N'HTL38049', 119, 1, CAST(N'2020-11-22T16:16:08.460' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5067, N'21', N'HTL38049', 119, 1, CAST(N'2020-11-22T16:16:08.460' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5068, N'22', N'HTL38049', 119, 1, CAST(N'2020-11-22T16:16:08.460' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5069, N'23', N'HTL38049', 119, 1, CAST(N'2020-11-22T16:16:08.460' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5070, N'24', N'HTL38049', 119, 1, CAST(N'2020-11-22T16:16:08.473' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5071, N'25', N'HTL38049', 119, 1, CAST(N'2020-11-22T16:16:08.473' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5072, N'26', N'HTL38049', 119, 1, CAST(N'2020-11-22T16:16:08.473' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5073, N'27', N'HTL38049', 119, 1, CAST(N'2020-11-22T16:16:08.473' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5074, N'28', N'HTL38049', 119, 1, CAST(N'2020-11-22T16:16:08.473' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5075, N'29', N'HTL38049', 119, 1, CAST(N'2020-11-22T16:16:08.490' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5076, N'30', N'HTL38049', 119, 1, CAST(N'2020-11-22T16:16:08.490' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5083, N'001', N'HTL68300', 19, 1, CAST(N'2020-12-26T15:39:46.837' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5084, N'002', N'HTL68300', 19, 1, CAST(N'2020-12-26T15:39:46.837' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5085, N'003', N'HTL68300', 19, 1, CAST(N'2020-12-26T15:39:46.853' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5086, N'004', N'HTL68300', 19, 1, CAST(N'2020-12-26T15:39:46.853' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5087, N'106', N'HTL68300', 19, 1, CAST(N'2020-12-26T15:39:46.853' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5088, N'107', N'HTL68300', 19, 1, CAST(N'2020-12-26T15:39:46.870' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5089, N'006', N'HTL68300', 20, 1, CAST(N'2020-12-26T15:40:31.427' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5090, N'007', N'HTL68300', 20, 1, CAST(N'2020-12-26T15:40:31.443' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5091, N'008', N'HTL68300', 20, 1, CAST(N'2020-12-26T15:40:31.443' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5092, N'009', N'HTL68300', 20, 1, CAST(N'2020-12-26T15:40:31.460' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5093, N'102', N'HTL68300', 20, 1, CAST(N'2020-12-26T15:40:31.460' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5094, N'103', N'HTL68300', 20, 1, CAST(N'2020-12-26T15:40:31.460' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5095, N'104', N'HTL68300', 20, 1, CAST(N'2020-12-26T15:40:31.460' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5096, N'105', N'HTL68300', 20, 1, CAST(N'2020-12-26T15:40:31.477' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5097, N'108', N'HTL68300', 20, 1, CAST(N'2020-12-26T15:40:31.477' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5098, N'110', N'HTL68300', 20, 1, CAST(N'2020-12-26T15:40:31.477' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5103, N'005', N'HTL68300', 21, 1, CAST(N'2020-12-26T15:41:55.583' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5104, N'101', N'HTL68300', 21, 1, CAST(N'2020-12-26T15:41:55.600' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5105, N'109', N'HTL68300', 21, 1, CAST(N'2020-12-26T15:41:55.617' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5106, N'111', N'HTL68300', 21, 1, CAST(N'2020-12-26T15:41:55.617' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5147, N'205', N'HTL24279', 59, 0, CAST(N'2020-12-31T17:51:24.467' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5148, N'206', N'HTL24279', 59, 0, CAST(N'2020-12-31T17:51:24.467' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5149, N'207', N'HTL24279', 59, 0, CAST(N'2020-12-31T17:51:24.483' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5150, N'208', N'HTL24279', 59, 0, CAST(N'2020-12-31T17:51:24.483' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5151, N'209', N'HTL24279', 59, 0, CAST(N'2020-12-31T17:51:24.500' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5152, N'210', N'HTL24279', 59, 0, CAST(N'2020-12-31T17:51:24.500' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5153, N'211', N'HTL24279', 59, 0, CAST(N'2020-12-31T17:51:24.500' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5154, N'212', N'HTL24279', 59, 0, CAST(N'2020-12-31T17:51:24.513' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5155, N'213', N'HTL24279', 59, 0, CAST(N'2020-12-31T17:51:24.513' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5156, N'214', N'HTL24279', 59, 0, CAST(N'2020-12-31T17:51:24.530' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5157, N'215', N'HTL24279', 59, 0, CAST(N'2020-12-31T17:51:24.530' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5158, N'216', N'HTL24279', 59, 0, CAST(N'2020-12-31T17:51:24.530' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5159, N'217', N'HTL24279', 59, 0, CAST(N'2020-12-31T17:51:24.530' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5160, N'218', N'HTL24279', 59, 0, CAST(N'2020-12-31T17:51:24.547' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5161, N'219', N'HTL24279', 59, 0, CAST(N'2020-12-31T17:51:24.547' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5162, N'220', N'HTL24279', 59, 0, CAST(N'2020-12-31T17:51:24.547' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5183, N'101', N'HTL24279', 57, 0, CAST(N'2021-01-01T11:29:12.497' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5184, N'102', N'HTL24279', 57, 0, CAST(N'2021-01-01T11:29:12.497' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5185, N'103', N'HTL24279', 57, 0, CAST(N'2021-01-01T11:29:12.497' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5186, N'104', N'HTL24279', 57, 0, CAST(N'2021-01-01T11:29:12.513' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5187, N'105', N'HTL24279', 57, 0, CAST(N'2021-01-01T11:29:12.513' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5188, N'106', N'HTL24279', 57, 0, CAST(N'2021-01-01T11:29:12.513' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5189, N'107', N'HTL24279', 57, 0, CAST(N'2021-01-01T11:29:12.527' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5190, N'108', N'HTL24279', 57, 0, CAST(N'2021-01-01T11:29:12.527' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5191, N'109', N'HTL24279', 57, 0, CAST(N'2021-01-01T11:29:12.543' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5192, N'110', N'HTL24279', 57, 0, CAST(N'2021-01-01T11:29:12.543' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5193, N'111', N'HTL24279', 57, 0, CAST(N'2021-01-01T11:29:12.543' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5194, N'112', N'HTL24279', 57, 0, CAST(N'2021-01-01T11:29:12.543' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5195, N'113', N'HTL24279', 57, 0, CAST(N'2021-01-01T11:29:12.560' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5196, N'114', N'HTL24279', 57, 0, CAST(N'2021-01-01T11:29:12.560' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5197, N'115', N'HTL24279', 57, 0, CAST(N'2021-01-01T11:29:12.560' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5198, N'116', N'HTL24279', 57, 0, CAST(N'2021-01-01T11:29:12.560' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5199, N'001', N'HTL24279', 120, 0, CAST(N'2021-01-01T11:37:22.110' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5200, N'002', N'HTL24279', 120, 0, CAST(N'2021-01-01T11:37:22.127' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5201, N'003', N'HTL24279', 120, 0, CAST(N'2021-01-01T11:37:22.157' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5202, N'004', N'HTL24279', 120, 0, CAST(N'2021-01-01T11:37:22.173' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5203, N'005', N'HTL24279', 120, 0, CAST(N'2021-01-01T11:37:22.203' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5204, N'006', N'HTL24279', 120, 0, CAST(N'2021-01-01T11:37:22.250' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5205, N'007', N'HTL24279', 120, 0, CAST(N'2021-01-01T11:37:22.283' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5206, N'008', N'HTL24279', 120, 0, CAST(N'2021-01-01T11:37:22.330' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5377, N'1', N'MHJ60', 122, 1, CAST(N'2021-01-22T13:39:20.257' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5378, N'2', N'MHJ60', 122, 1, CAST(N'2021-01-22T13:39:22.163' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5379, N'3', N'MHJ60', 122, 1, CAST(N'2021-01-22T13:39:24.083' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5380, N'4', N'MHJ60', 122, 1, CAST(N'2021-01-22T13:39:25.940' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5381, N'5', N'MHJ60', 122, 1, CAST(N'2021-01-22T13:39:27.977' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5390, N'1', N'MHJ60', 123, 1, CAST(N'2021-01-22T13:44:09.580' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5391, N'2', N'MHJ60', 123, 1, CAST(N'2021-01-22T13:44:09.763' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5392, N'3', N'MHJ60', 123, 1, CAST(N'2021-01-22T13:44:09.903' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5393, N'4', N'MHJ60', 123, 1, CAST(N'2021-01-22T13:44:10.037' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5394, N'5', N'MHJ60', 123, 1, CAST(N'2021-01-22T13:44:10.193' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5395, N'6', N'MHJ60', 123, 1, CAST(N'2021-01-22T13:44:10.353' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5396, N'7', N'MHJ60', 123, 1, CAST(N'2021-01-22T13:44:10.500' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5397, N'8', N'MHJ60', 123, 1, CAST(N'2021-01-22T13:44:10.673' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5398, N'9', N'MHJ60', 123, 1, CAST(N'2021-01-22T13:44:10.853' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5399, N'10', N'MHJ60', 123, 1, CAST(N'2021-01-22T13:44:11.057' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5400, N'11', N'MHJ60', 123, 1, CAST(N'2021-01-22T13:44:11.220' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5401, N'12', N'MHJ60', 123, 1, CAST(N'2021-01-22T13:44:11.370' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5402, N'13', N'MHJ60', 123, 1, CAST(N'2021-01-22T13:44:11.530' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5403, N'14', N'MHJ60', 123, 1, CAST(N'2021-01-22T13:44:11.977' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5404, N'15', N'MHJ60', 123, 1, CAST(N'2021-01-22T13:44:12.127' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5449, N'1', N'MIR63', 130, 1, CAST(N'2021-01-22T13:51:51.137' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5450, N'2', N'MIR63', 130, 1, CAST(N'2021-01-22T13:51:51.273' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5451, N'3', N'MIR63', 130, 1, CAST(N'2021-01-22T13:51:51.437' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5452, N'4', N'MIR63', 130, 1, CAST(N'2021-01-22T13:51:51.813' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5453, N'1', N'MIR63', 131, 1, CAST(N'2021-01-22T13:52:44.637' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5454, N'2', N'MIR63', 131, 1, CAST(N'2021-01-22T13:52:44.803' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5455, N'3', N'MIR63', 131, 1, CAST(N'2021-01-22T13:52:44.987' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5456, N'1', N'MIR63', 132, 1, CAST(N'2021-01-22T13:53:22.770' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5457, N'2', N'MIR63', 132, 1, CAST(N'2021-01-22T13:53:22.900' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5458, N'3', N'MIR63', 132, 1, CAST(N'2021-01-22T13:53:23.050' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5482, N'1', N'MAU64', 135, 1, CAST(N'2021-01-22T13:55:52.450' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5483, N'2', N'MAU64', 135, 1, CAST(N'2021-01-22T13:55:52.587' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5484, N'3', N'MAU64', 135, 1, CAST(N'2021-01-22T13:55:52.737' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5485, N'1', N'GHZ65', 136, 1, CAST(N'2021-01-22T13:58:07.603' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5486, N'2', N'GHZ65', 136, 1, CAST(N'2021-01-22T13:58:07.767' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5487, N'1', N'GHZ65', 137, 0, CAST(N'2021-01-22T13:58:48.397' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5488, N'2', N'GHZ65', 137, 0, CAST(N'2021-01-22T13:58:48.550' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5489, N'3', N'GHZ65', 137, 0, CAST(N'2021-01-22T13:58:48.710' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5490, N'4', N'GHZ65', 137, 0, CAST(N'2021-01-22T13:58:48.850' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5491, N'1', N'GHZ65', 138, 1, CAST(N'2021-01-22T13:59:29.927' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5492, N'2', N'GHZ65', 138, 1, CAST(N'2021-01-22T13:59:30.120' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5506, N'1', N'BAD67', 141, 1, CAST(N'2021-01-22T14:01:27.947' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5507, N'2', N'BAD67', 141, 1, CAST(N'2021-01-22T14:01:28.100' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5508, N'1', N'BAD67', 142, 1, CAST(N'2021-01-22T14:02:46.983' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5509, N'1', N'BAD67', 143, 1, CAST(N'2021-01-22T14:03:25.673' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5510, N'2', N'BAD67', 143, 1, CAST(N'2021-01-22T14:03:25.817' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5511, N'3', N'BAD67', 143, 1, CAST(N'2021-01-22T14:03:26.007' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5512, N'4', N'BAD67', 143, 1, CAST(N'2021-01-22T14:03:26.157' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5513, N'5', N'BAD67', 143, 1, CAST(N'2021-01-22T14:03:26.310' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5514, N'1', N'BAD67', 144, 1, CAST(N'2021-01-22T14:04:10.447' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5515, N'2', N'BAD67', 144, 1, CAST(N'2021-01-22T14:04:10.600' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5516, N'1', N'GZH45', 145, 1, CAST(N'2021-01-22T14:06:00.143' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5517, N'2', N'GZH45', 145, 1, CAST(N'2021-01-22T14:06:00.270' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5521, N'3', N'GZH45', 146, 1, CAST(N'2021-01-22T14:08:00.467' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5535, N'1', N'ETW71', 150, 1, CAST(N'2021-01-22T14:10:42.210' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5536, N'2', N'ETW71', 150, 1, CAST(N'2021-01-22T14:10:42.350' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5537, N'1', N'ETW71', 151, 1, CAST(N'2021-01-22T14:11:35.810' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5538, N'2', N'ETW71', 151, 1, CAST(N'2021-01-22T14:11:36.190' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5556, N'205', N'HTL63683', 16, 0, CAST(N'2021-07-29T15:48:19.770' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5557, N'206', N'HTL63683', 16, 0, CAST(N'2021-07-29T15:48:19.800' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5558, N'207', N'HTL63683', 16, 0, CAST(N'2021-07-29T15:48:19.817' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5612, N'211', N'HTL78404', 94, 0, CAST(N'2021-08-17T16:02:48.720' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5613, N'212', N'HTL78404', 94, 0, CAST(N'2021-08-17T16:02:48.750' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5614, N'311', N'HTL78404', 94, 0, CAST(N'2021-08-17T16:02:48.780' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5615, N'312', N'HTL78404', 94, 0, CAST(N'2021-08-17T16:02:48.827' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5889, N'01', N'HTL38049', 72, 1, CAST(N'2021-10-06T15:55:47.097' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5890, N'02', N'HTL38049', 72, 0, CAST(N'2021-10-06T15:55:47.450' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5891, N'101', N'HTL38049', 72, 0, CAST(N'2021-10-06T15:55:47.507' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5902, N'101', N'HTL39354', 27, 0, CAST(N'2021-10-20T18:49:43.560' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5903, N'102', N'HTL39354', 27, 0, CAST(N'2021-10-20T18:49:43.617' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5904, N'103', N'HTL39354', 27, 0, CAST(N'2021-10-20T18:49:43.673' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5905, N'104', N'HTL39354', 27, 0, CAST(N'2021-10-20T18:49:43.733' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5906, N'201', N'HTL39354', 26, 0, CAST(N'2021-10-20T18:50:34.417' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5907, N'202', N'HTL39354', 26, 1, CAST(N'2021-10-20T18:50:34.473' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5908, N'203', N'HTL39354', 26, 1, CAST(N'2021-10-20T18:50:34.530' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5909, N'204', N'HTL39354', 26, 0, CAST(N'2021-10-20T18:50:34.587' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5910, N'205', N'HTL39354', 26, 1, CAST(N'2021-10-20T18:50:34.647' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5911, N'206', N'HTL39354', 26, 1, CAST(N'2021-10-20T18:50:34.703' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5930, N'1', N'SIT62', 127, 0, CAST(N'2021-12-24T16:35:12.330' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5931, N'2', N'SIT62', 127, 0, CAST(N'2021-12-24T16:35:12.387' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5936, N'1', N'SIT62', 128, 0, CAST(N'2021-12-24T16:37:42.280' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5937, N'2', N'SIT62', 128, 0, CAST(N'2021-12-24T16:37:42.297' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5938, N'3', N'SIT62', 128, 0, CAST(N'2021-12-24T16:37:42.310' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5939, N'4', N'SIT62', 128, 0, CAST(N'2021-12-24T16:37:42.330' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5940, N'1', N'SIT62', 149, 0, CAST(N'2021-12-24T16:38:19.547' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5941, N'2', N'SIT62', 149, 0, CAST(N'2021-12-24T16:38:19.557' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5942, N'3', N'SIT62', 149, 0, CAST(N'2021-12-24T16:38:19.570' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5943, N'4', N'SIT62', 149, 0, CAST(N'2021-12-24T16:38:19.587' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5944, N'5', N'SIT62', 149, 0, CAST(N'2021-12-24T16:38:19.597' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5945, N'6', N'SIT62', 149, 0, CAST(N'2021-12-24T16:38:19.607' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5946, N'9', N'HTL97314', 10, 1, CAST(N'2022-02-08T19:15:59.460' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5947, N'10', N'HTL97314', 10, 1, CAST(N'2022-02-08T19:15:59.570' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5952, N'11', N'HTL97314', 11, 1, CAST(N'2022-03-26T12:33:48.087' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5953, N'12', N'HTL97314', 11, 1, CAST(N'2022-03-26T12:33:48.140' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5954, N'14', N'HTL97314', 11, 1, CAST(N'2022-03-26T12:33:48.143' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5955, N'15', N'HTL97314', 11, 1, CAST(N'2022-03-26T12:33:48.143' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5963, N'112', N'HTL10191', 5, 0, CAST(N'2022-03-30T11:43:37.403' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5964, N'203', N'HTL10191', 5, 1, CAST(N'2022-03-30T11:43:37.453' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (5965, N'202', N'HTL10191', 5, 1, CAST(N'2022-03-30T11:43:37.457' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6365, N'214', N'HTL78404', 105, 1, CAST(N'2022-04-22T00:09:37.743' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6366, N'215', N'HTL78404', 105, 0, CAST(N'2022-04-22T00:09:37.790' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6367, N'314', N'HTL78404', 105, 0, CAST(N'2022-04-22T00:09:37.823' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6368, N'315', N'HTL78404', 105, 0, CAST(N'2022-04-22T00:09:37.823' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6369, N'102', N'HTL78404', 104, 0, CAST(N'2022-04-22T00:14:37.330' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6370, N'103', N'HTL78404', 104, 0, CAST(N'2022-04-22T00:14:37.343' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6371, N'104', N'HTL78404', 104, 0, CAST(N'2022-04-22T00:14:37.343' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6372, N'105', N'HTL78404', 104, 0, CAST(N'2022-04-22T00:14:37.343' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6373, N'106', N'HTL78404', 104, 0, CAST(N'2022-04-22T00:14:37.343' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6374, N'107', N'HTL78404', 104, 0, CAST(N'2022-04-22T00:14:37.343' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6375, N'201', N'HTL78404', 95, 0, CAST(N'2022-04-22T00:18:54.563' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6376, N'202', N'HTL78404', 95, 0, CAST(N'2022-04-22T00:18:54.563' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6377, N'203', N'HTL78404', 95, 0, CAST(N'2022-04-22T00:18:54.563' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6378, N'204', N'HTL78404', 95, 0, CAST(N'2022-04-22T00:18:54.563' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6379, N'205', N'HTL78404', 95, 0, CAST(N'2022-04-22T00:18:54.580' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6380, N'206', N'HTL78404', 95, 0, CAST(N'2022-04-22T00:18:54.580' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6381, N'207', N'HTL78404', 95, 0, CAST(N'2022-04-22T00:18:54.580' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6382, N'208', N'HTL78404', 95, 0, CAST(N'2022-04-22T00:18:54.580' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6383, N'301', N'HTL78404', 95, 0, CAST(N'2022-04-22T00:18:54.580' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6384, N'302', N'HTL78404', 95, 0, CAST(N'2022-04-22T00:18:54.580' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6385, N'303', N'HTL78404', 95, 0, CAST(N'2022-04-22T00:18:54.597' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6386, N'304', N'HTL78404', 95, 0, CAST(N'2022-04-22T00:18:54.597' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6387, N'305', N'HTL78404', 95, 0, CAST(N'2022-04-22T00:18:54.597' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6388, N'306', N'HTL78404', 95, 0, CAST(N'2022-04-22T00:18:54.597' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6389, N'307', N'HTL78404', 95, 0, CAST(N'2022-04-22T00:18:54.597' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6390, N'308', N'HTL78404', 95, 0, CAST(N'2022-04-22T00:18:54.597' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6391, N'02', N'HTL78404', 96, 0, CAST(N'2022-04-22T00:20:54.240' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6392, N'03', N'HTL78404', 96, 0, CAST(N'2022-04-22T00:20:54.257' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6393, N'04', N'HTL78404', 96, 0, CAST(N'2022-04-22T00:20:54.257' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6394, N'06', N'HTL78404', 96, 0, CAST(N'2022-04-22T00:20:54.257' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6395, N'07', N'HTL78404', 96, 0, CAST(N'2022-04-22T00:20:54.270' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6396, N'08', N'HTL78404', 96, 0, CAST(N'2022-04-22T00:20:54.270' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6397, N'09', N'HTL78404', 96, 0, CAST(N'2022-04-22T00:20:54.270' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6486, N'101', N'HTL82734', 23, 1, CAST(N'2022-04-22T09:02:34.860' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6487, N'102', N'HTL82734', 23, 1, CAST(N'2022-04-22T09:02:34.860' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6488, N'103', N'HTL82734', 23, 1, CAST(N'2022-04-22T09:02:34.877' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6489, N'104', N'HTL82734', 23, 1, CAST(N'2022-04-22T09:02:34.877' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6490, N'105', N'HTL82734', 23, 1, CAST(N'2022-04-22T09:02:34.877' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6491, N'106', N'HTL82734', 23, 1, CAST(N'2022-04-22T09:02:34.877' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6492, N'201', N'HTL82734', 23, 1, CAST(N'2022-04-22T09:02:34.890' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6493, N'202', N'HTL82734', 23, 1, CAST(N'2022-04-22T09:02:34.890' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6494, N'203', N'HTL82734', 23, 1, CAST(N'2022-04-22T09:02:34.890' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6495, N'204', N'HTL82734', 23, 1, CAST(N'2022-04-22T09:02:34.890' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6496, N'205', N'HTL82734', 23, 1, CAST(N'2022-04-22T09:02:34.890' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6497, N'206', N'HTL82734', 23, 1, CAST(N'2022-04-22T09:02:34.907' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6498, N'301', N'HTL82734', 23, 1, CAST(N'2022-04-22T09:02:34.907' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6499, N'302', N'HTL82734', 23, 1, CAST(N'2022-04-22T09:02:34.907' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6500, N'303', N'HTL82734', 23, 0, CAST(N'2022-04-22T09:02:34.907' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6501, N'304', N'HTL82734', 23, 1, CAST(N'2022-04-22T09:02:34.923' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6502, N'305', N'HTL82734', 23, 1, CAST(N'2022-04-22T09:02:34.923' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6503, N'306', N'HTL82734', 23, 1, CAST(N'2022-04-22T09:02:34.923' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6504, N'401', N'HTL82734', 23, 1, CAST(N'2022-04-22T09:02:34.923' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6505, N'402', N'HTL82734', 23, 1, CAST(N'2022-04-22T09:02:34.923' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6506, N'403', N'HTL82734', 23, 1, CAST(N'2022-04-22T09:02:34.937' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6507, N'404', N'HTL82734', 23, 1, CAST(N'2022-04-22T09:02:34.937' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6508, N'405', N'HTL82734', 23, 1, CAST(N'2022-04-22T09:02:34.937' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6509, N'406', N'HTL82734', 23, 1, CAST(N'2022-04-22T09:02:34.937' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6510, N'501', N'HTL82734', 23, 1, CAST(N'2022-04-22T09:02:34.953' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6511, N'502', N'HTL82734', 23, 1, CAST(N'2022-04-22T09:02:34.953' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6512, N'503', N'HTL82734', 23, 1, CAST(N'2022-04-22T09:02:34.953' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6513, N'504', N'HTL82734', 23, 1, CAST(N'2022-04-22T09:02:34.953' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6514, N'505', N'HTL82734', 23, 1, CAST(N'2022-04-22T09:02:34.970' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6515, N'506', N'HTL82734', 23, 1, CAST(N'2022-04-22T09:02:34.970' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6516, N'03', N'HTL38049', 73, 1, CAST(N'2022-05-03T12:33:43.000' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6517, N'04', N'HTL38049', 73, 1, CAST(N'2022-05-03T12:33:43.123' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6518, N'05', N'HTL38049', 73, 1, CAST(N'2022-05-03T12:33:43.123' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6519, N'06', N'HTL38049', 73, 1, CAST(N'2022-05-03T12:33:43.123' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6520, N'102', N'HTL38049', 73, 1, CAST(N'2022-05-03T12:33:43.140' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6521, N'103', N'HTL38049', 73, 1, CAST(N'2022-05-03T12:33:43.140' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6522, N'104', N'HTL38049', 73, 1, CAST(N'2022-05-03T12:33:43.157' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6523, N'105', N'HTL38049', 73, 1, CAST(N'2022-05-03T12:33:43.170' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6524, N'106', N'HTL38049', 73, 1, CAST(N'2022-05-03T12:33:43.170' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (6525, N'107', N'HTL38049', 73, 1, CAST(N'2022-05-03T12:33:43.170' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7074, N'501', N'HTL78999', 153, 0, CAST(N'2022-05-11T13:04:22.240' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7075, N'504', N'HTL78999', 153, 0, CAST(N'2022-05-11T13:04:22.367' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7076, N'505', N'HTL78999', 153, 0, CAST(N'2022-05-11T13:04:22.380' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7077, N'506', N'HTL78999', 153, 0, CAST(N'2022-05-11T13:04:22.380' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7078, N'507', N'HTL78999', 153, 0, CAST(N'2022-05-11T13:04:22.380' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7079, N'508', N'HTL78999', 153, 0, CAST(N'2022-05-11T13:04:22.380' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7080, N'509', N'HTL78999', 153, 0, CAST(N'2022-05-11T13:04:22.397' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7081, N'510', N'HTL78999', 153, 0, CAST(N'2022-05-11T13:04:22.397' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7082, N'511', N'HTL78999', 153, 0, CAST(N'2022-05-11T13:04:22.397' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7083, N'512', N'HTL78999', 153, 0, CAST(N'2022-05-11T13:04:22.397' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7172, N'101', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:18.907' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7173, N'102', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:18.923' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7174, N'103', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:18.923' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7175, N'104', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:18.923' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7176, N'105', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:18.940' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7177, N'106', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:18.940' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7178, N'107', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:18.940' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7179, N'108', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:18.940' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7180, N'109', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:18.940' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7181, N'110', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:18.953' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7182, N'111', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:18.953' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7183, N'112', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:18.953' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7184, N'114', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:18.953' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7185, N'115', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:18.970' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7186, N'116', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:18.970' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7187, N'117', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:18.970' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7188, N'118', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:18.970' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7189, N'119', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:18.970' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7190, N'120', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:18.987' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7191, N'121', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:18.987' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7192, N'122', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:18.987' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7193, N'123', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:18.987' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7194, N'201', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:18.987' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7195, N'202', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.000' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7196, N'203', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.000' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7197, N'204', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.000' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7198, N'205', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.000' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7199, N'206', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.000' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7200, N'207', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.017' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7201, N'208', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.017' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7202, N'209', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.017' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7203, N'210', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.017' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7204, N'211', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.033' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7205, N'212', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.033' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7206, N'213', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.033' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7207, N'214', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.033' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7208, N'215', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.047' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7209, N'216', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.047' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7210, N'217', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.047' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7211, N'218', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.047' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7212, N'219', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.047' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7213, N'220', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.063' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7214, N'221', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.063' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7215, N'222', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.063' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7216, N'301', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.063' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7217, N'302', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.063' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7218, N'303', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.080' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7219, N'304', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.080' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7220, N'305', N'HTL78999', 154, 1, CAST(N'2022-05-11T19:21:19.080' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7221, N'306', N'HTL78999', 154, 1, CAST(N'2022-05-11T19:21:19.080' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7222, N'307', N'HTL78999', 154, 1, CAST(N'2022-05-11T19:21:19.080' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7223, N'308', N'HTL78999', 154, 1, CAST(N'2022-05-11T19:21:19.097' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7224, N'309', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.097' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7225, N'310', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.097' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7226, N'311', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.097' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7227, N'312', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.097' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7228, N'313', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.110' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7229, N'314', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.110' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7230, N'315', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.110' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7231, N'316', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.110' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7232, N'317', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.127' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7233, N'318', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.127' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7234, N'319', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.127' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7235, N'320', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.127' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7236, N'321', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.127' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7237, N'322', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.143' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7238, N'401', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.143' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7239, N'402', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.143' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7240, N'403', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.143' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7241, N'404', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.143' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7242, N'405', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.157' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7243, N'406', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.157' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7244, N'407', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.157' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7245, N'408', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.157' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7246, N'409', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.157' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7247, N'410', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.173' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7248, N'411', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.173' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7249, N'412', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.173' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7250, N'413', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.173' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7251, N'414', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.173' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7252, N'415', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.190' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7253, N'416', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.190' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7254, N'417', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.190' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7255, N'418', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.190' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7256, N'419', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.203' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7257, N'421', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.203' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7258, N'422', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.203' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7259, N'423', N'HTL78999', 154, 0, CAST(N'2022-05-11T19:21:19.203' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7278, N'05', N'HTL63683', 92, 1, CAST(N'2022-05-15T13:19:16.377' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7279, N'06', N'HTL63683', 92, 0, CAST(N'2022-05-15T13:19:16.377' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7280, N'105', N'HTL63683', 92, 0, CAST(N'2022-05-15T13:19:16.377' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7281, N'106', N'HTL63683', 92, 0, CAST(N'2022-05-15T13:19:16.377' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7282, N'107', N'HTL63683', 92, 0, CAST(N'2022-05-15T13:19:16.377' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7283, N'203', N'HTL63683', 92, 0, CAST(N'2022-05-15T13:19:16.377' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7284, N'204', N'HTL63683', 92, 0, CAST(N'2022-05-15T13:19:16.377' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7285, N'01', N'AYO66', 139, 1, CAST(N'2022-05-15T13:23:04.097' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7286, N'02', N'AYO66', 139, 1, CAST(N'2022-05-15T13:23:04.113' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7287, N'03', N'AYO66', 139, 1, CAST(N'2022-05-15T13:23:04.113' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7288, N'101', N'AYO66', 139, 1, CAST(N'2022-05-15T13:23:04.113' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7289, N'103', N'AYO66', 139, 1, CAST(N'2022-05-15T13:23:04.127' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7290, N'104', N'AYO66', 139, 1, CAST(N'2022-05-15T13:23:04.127' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7291, N'201', N'AYO66', 139, 1, CAST(N'2022-05-15T13:23:04.127' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7292, N'203', N'AYO66', 139, 1, CAST(N'2022-05-15T13:23:04.127' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7293, N'204', N'AYO66', 139, 1, CAST(N'2022-05-15T13:23:04.127' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7294, N'04', N'AYO66', 140, 1, CAST(N'2022-05-15T13:23:41.053' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7295, N'102', N'AYO66', 140, 1, CAST(N'2022-05-15T13:23:41.070' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7296, N'202', N'AYO66', 140, 1, CAST(N'2022-05-15T13:23:41.070' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7298, N'101', N'HTL63683', 42, 1, CAST(N'2022-05-15T19:34:01.110' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7299, N'102', N'HTL63683', 42, 1, CAST(N'2022-05-15T19:34:01.110' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7300, N'201', N'HTL63683', 42, 0, CAST(N'2022-05-15T19:34:01.127' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7301, N'202', N'HTL63683', 42, 0, CAST(N'2022-05-15T19:34:01.127' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7302, N'1', N'FRK61', 125, 1, CAST(N'2022-05-16T10:36:08.873' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7303, N'2', N'FRK61', 125, 1, CAST(N'2022-05-16T10:36:08.920' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7304, N'3', N'FRK61', 125, 1, CAST(N'2022-05-16T10:36:08.920' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7305, N'4', N'FRK61', 125, 1, CAST(N'2022-05-16T10:36:08.920' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7306, N'5', N'FRK61', 125, 1, CAST(N'2022-05-16T10:36:08.920' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7307, N'6', N'FRK61', 125, 1, CAST(N'2022-05-16T10:36:08.920' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7308, N'7', N'FRK61', 125, 1, CAST(N'2022-05-16T10:36:08.920' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7309, N'8', N'FRK61', 125, 1, CAST(N'2022-05-16T10:36:08.920' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7310, N'9', N'FRK61', 125, 1, CAST(N'2022-05-16T10:36:08.920' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7311, N'10', N'FRK61', 125, 1, CAST(N'2022-05-16T10:36:08.920' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7312, N'11', N'FRK61', 125, 1, CAST(N'2022-05-16T10:36:08.937' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7313, N'12', N'FRK61', 125, 1, CAST(N'2022-05-16T10:36:08.937' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7314, N'13', N'FRK61', 125, 1, CAST(N'2022-05-16T10:36:08.937' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7315, N'14', N'FRK61', 125, 1, CAST(N'2022-05-16T10:36:08.937' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7316, N'15', N'FRK61', 125, 1, CAST(N'2022-05-16T10:36:08.937' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7317, N'16', N'FRK61', 125, 1, CAST(N'2022-05-16T10:36:08.937' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7318, N'1', N'FRK61', 126, 1, CAST(N'2022-05-16T10:37:33.033' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7319, N'2', N'FRK61', 126, 1, CAST(N'2022-05-16T10:37:33.050' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7320, N'3', N'FRK61', 126, 1, CAST(N'2022-05-16T10:37:33.050' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7321, N'4', N'FRK61', 126, 1, CAST(N'2022-05-16T10:37:33.050' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7322, N'5', N'FRK61', 126, 1, CAST(N'2022-05-16T10:37:33.050' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7323, N'6', N'FRK61', 126, 1, CAST(N'2022-05-16T10:37:33.050' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7324, N'7', N'FRK61', 126, 1, CAST(N'2022-05-16T10:37:33.050' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7325, N'8', N'FRK61', 126, 1, CAST(N'2022-05-16T10:37:33.050' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7326, N'9', N'FRK61', 126, 1, CAST(N'2022-05-16T10:37:33.050' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7327, N'10', N'FRK61', 126, 1, CAST(N'2022-05-16T10:37:33.050' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7328, N'11', N'FRK61', 126, 1, CAST(N'2022-05-16T10:37:33.063' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7329, N'12', N'FRK61', 126, 1, CAST(N'2022-05-16T10:37:33.063' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7330, N'13', N'FRK61', 126, 1, CAST(N'2022-05-16T10:37:33.063' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7331, N'14', N'FRK61', 126, 1, CAST(N'2022-05-16T10:37:33.063' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7332, N'15', N'FRK61', 126, 1, CAST(N'2022-05-16T10:37:33.063' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7333, N'16', N'FRK61', 126, 1, CAST(N'2022-05-16T10:37:33.063' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7334, N'1', N'HTL51674', 63, 1, CAST(N'2022-05-16T10:41:40.003' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7335, N'2', N'HTL51674', 63, 1, CAST(N'2022-05-16T10:41:40.003' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7336, N'3', N'HTL51674', 63, 1, CAST(N'2022-05-16T10:41:40.003' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7337, N'4', N'HTL51674', 63, 1, CAST(N'2022-05-16T10:41:40.003' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7338, N'5', N'HTL51674', 63, 1, CAST(N'2022-05-16T10:41:40.003' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7339, N'6', N'HTL51674', 63, 1, CAST(N'2022-05-16T10:41:40.003' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7340, N'7', N'HTL51674', 63, 1, CAST(N'2022-05-16T10:41:40.003' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7341, N'8', N'HTL51674', 63, 1, CAST(N'2022-05-16T10:41:40.003' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7342, N'9', N'HTL51674', 63, 1, CAST(N'2022-05-16T10:41:40.003' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7343, N'10', N'HTL51674', 63, 1, CAST(N'2022-05-16T10:41:40.003' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7344, N'11', N'HTL51674', 63, 1, CAST(N'2022-05-16T10:41:40.017' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7345, N'12', N'HTL51674', 63, 1, CAST(N'2022-05-16T10:41:40.017' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7346, N'13', N'HTL51674', 64, 1, CAST(N'2022-05-16T10:42:30.570' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7347, N'14', N'HTL51674', 64, 1, CAST(N'2022-05-16T10:42:30.583' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7348, N'15', N'HTL51674', 64, 1, CAST(N'2022-05-16T10:42:30.583' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7349, N'16', N'HTL51674', 64, 1, CAST(N'2022-05-16T10:42:30.583' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7350, N'234', N'HTL33373', 160, 1, CAST(N'2022-05-16T10:49:26.177' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7351, N'102', N'HTL33373', 159, 1, CAST(N'2022-05-16T10:50:54.927' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7352, N'103', N'HTL33373', 159, 1, CAST(N'2022-05-16T10:50:54.927' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7353, N'104', N'HTL33373', 159, 1, CAST(N'2022-05-16T10:50:54.927' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7354, N'1', N'MIR63', 133, 1, CAST(N'2022-05-16T11:06:07.840' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7355, N'2', N'MIR63', 133, 1, CAST(N'2022-05-16T11:06:07.840' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7356, N'3', N'MIR63', 133, 1, CAST(N'2022-05-16T11:06:07.840' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7357, N'4', N'MIR63', 133, 1, CAST(N'2022-05-16T11:06:07.840' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7358, N'5', N'MIR63', 133, 1, CAST(N'2022-05-16T11:06:07.840' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7359, N'6', N'MIR63', 133, 1, CAST(N'2022-05-16T11:06:07.840' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7360, N'7', N'MIR63', 133, 1, CAST(N'2022-05-16T11:06:07.840' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7361, N'8', N'MIR63', 133, 1, CAST(N'2022-05-16T11:06:07.840' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7362, N'9', N'MIR63', 133, 1, CAST(N'2022-05-16T11:06:07.857' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7363, N'10', N'MIR63', 133, 1, CAST(N'2022-05-16T11:06:07.857' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7364, N'11', N'MIR63', 133, 1, CAST(N'2022-05-16T11:06:07.857' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7365, N'12', N'MIR63', 133, 1, CAST(N'2022-05-16T11:06:07.857' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7366, N'13', N'MIR63', 133, 1, CAST(N'2022-05-16T11:06:07.857' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7367, N'14', N'MIR63', 133, 1, CAST(N'2022-05-16T11:06:07.857' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7368, N'15', N'MIR63', 133, 1, CAST(N'2022-05-16T11:06:07.857' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7369, N'16', N'MIR63', 133, 1, CAST(N'2022-05-16T11:06:07.857' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7370, N'17', N'MIR63', 133, 1, CAST(N'2022-05-16T11:06:07.857' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7371, N'18', N'MIR63', 133, 1, CAST(N'2022-05-16T11:06:07.857' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7372, N'1', N'BTH70', 148, 1, CAST(N'2022-05-16T11:24:15.837' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7373, N'2', N'BTH70', 148, 1, CAST(N'2022-05-16T11:24:15.837' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7374, N'3', N'BTH70', 148, 1, CAST(N'2022-05-16T11:24:15.853' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7375, N'4', N'BTH70', 148, 1, CAST(N'2022-05-16T11:24:15.853' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7376, N'5', N'BTH70', 148, 1, CAST(N'2022-05-16T11:24:15.853' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7377, N'6', N'BTH70', 148, 1, CAST(N'2022-05-16T11:24:15.853' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7378, N'7', N'BTH70', 148, 1, CAST(N'2022-05-16T11:24:15.853' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7379, N'8', N'BTH70', 148, 1, CAST(N'2022-05-16T11:24:15.853' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7380, N'102', N'ALL33', 112, 0, CAST(N'2022-05-16T11:27:01.107' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7381, N'103', N'ALL33', 112, 1, CAST(N'2022-05-16T11:27:01.107' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7382, N'008', N'HTL18824', 67, 1, CAST(N'2022-05-16T11:36:45.593' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7383, N'009', N'HTL18824', 67, 1, CAST(N'2022-05-16T11:36:45.607' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7384, N'002', N'HTL99957', 43, 1, CAST(N'2022-05-16T11:52:08.417' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7385, N'003', N'HTL99957', 43, 1, CAST(N'2022-05-16T11:52:08.417' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7386, N'101', N'HTL99957', 43, 1, CAST(N'2022-05-16T11:52:08.417' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7387, N'102', N'HTL99957', 43, 1, CAST(N'2022-05-16T11:52:08.417' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7388, N'103', N'HTL99957', 43, 1, CAST(N'2022-05-16T11:52:08.430' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7389, N'004', N'HTL99957', 44, 1, CAST(N'2022-05-21T14:48:17.627' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7390, N'104', N'HTL99957', 44, 1, CAST(N'2022-05-21T14:48:17.750' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7391, N'105', N'HTL99957', 44, 1, CAST(N'2022-05-21T14:48:17.767' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7401, N'D1', N'GZH45', 147, 1, CAST(N'2022-06-14T16:38:04.447' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7402, N'D2', N'GZH45', 147, 1, CAST(N'2022-06-14T16:38:04.847' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7403, N'D3', N'GZH45', 147, 1, CAST(N'2022-06-14T16:38:04.853' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7404, N'D4', N'GZH45', 147, 1, CAST(N'2022-06-14T16:38:04.857' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7405, N'D5', N'GZH45', 147, 1, CAST(N'2022-06-14T16:38:04.860' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7406, N'D6', N'GZH45', 147, 1, CAST(N'2022-06-14T16:38:04.863' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7407, N'D7', N'GZH45', 147, 1, CAST(N'2022-06-14T16:38:04.867' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7408, N'D8', N'GZH45', 147, 1, CAST(N'2022-06-14T16:38:04.870' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7429, N'201', N'HTL24279', 58, 0, CAST(N'2022-11-24T10:58:44.763' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7430, N'202', N'HTL24279', 58, 0, CAST(N'2022-11-24T10:58:44.860' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7431, N'203', N'HTL24279', 58, 0, CAST(N'2022-11-24T10:58:44.873' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7432, N'204', N'HTL24279', 58, 0, CAST(N'2022-11-24T10:58:44.873' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7433, N'205', N'HTL24279', 58, 0, CAST(N'2022-11-24T10:58:44.873' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7434, N'206', N'HTL24279', 58, 0, CAST(N'2022-11-24T10:58:44.873' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7435, N'207', N'HTL24279', 58, 0, CAST(N'2022-11-24T10:58:44.873' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7436, N'208', N'HTL24279', 58, 0, CAST(N'2022-11-24T10:58:44.873' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7437, N'209', N'HTL24279', 58, 0, CAST(N'2022-11-24T10:58:44.873' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7438, N'210', N'HTL24279', 58, 1, CAST(N'2022-11-24T10:58:44.873' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7439, N'211', N'HTL24279', 58, 0, CAST(N'2022-11-24T10:58:44.873' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7440, N'212', N'HTL24279', 58, 0, CAST(N'2022-11-24T10:58:44.873' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7441, N'213', N'HTL24279', 58, 0, CAST(N'2022-11-24T10:58:44.873' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7442, N'214', N'HTL24279', 58, 0, CAST(N'2022-11-24T10:58:44.890' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7443, N'215', N'HTL24279', 58, 0, CAST(N'2022-11-24T10:58:44.893' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7444, N'216', N'HTL24279', 58, 0, CAST(N'2022-11-24T10:58:44.897' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7445, N'217', N'HTL24279', 58, 0, CAST(N'2022-11-24T10:58:44.897' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7446, N'218', N'HTL24279', 58, 0, CAST(N'2022-11-24T10:58:44.897' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7447, N'219', N'HTL24279', 58, 0, CAST(N'2022-11-24T10:58:44.897' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7448, N'220', N'HTL24279', 58, 0, CAST(N'2022-11-24T10:58:44.897' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7449, N'101', N'AYO66', 163, 1, CAST(N'2022-12-15T11:18:04.243' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7450, N'103', N'AYO66', 163, 1, CAST(N'2022-12-15T11:18:04.480' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7451, N'104', N'AYO66', 163, 1, CAST(N'2022-12-15T11:18:04.500' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7452, N'201', N'AYO66', 163, 1, CAST(N'2022-12-15T11:18:04.500' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7453, N'203', N'AYO66', 163, 1, CAST(N'2022-12-15T11:18:04.500' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7454, N'204', N'AYO66', 163, 1, CAST(N'2022-12-15T11:18:04.500' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7455, N'03', N'HTL63683', 152, 0, CAST(N'2022-12-15T16:56:27.437' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7456, N'04', N'HTL63683', 152, 0, CAST(N'2022-12-15T16:56:27.437' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7457, N'103', N'HTL63683', 152, 0, CAST(N'2022-12-15T16:56:27.437' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7458, N'104', N'HTL63683', 152, 0, CAST(N'2022-12-15T16:56:27.450' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7459, N'205', N'HTL63683', 152, 0, CAST(N'2022-12-15T16:56:27.450' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7460, N'206', N'HTL63683', 152, 0, CAST(N'2022-12-15T16:56:27.450' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7461, N'207', N'HTL63683', 152, 0, CAST(N'2022-12-15T16:56:27.467' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7462, N'02', N'HTL63683', 14, 0, CAST(N'2022-12-15T16:57:20.103' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7463, N'01', N'HTL63683', 14, 0, CAST(N'2022-12-15T16:57:20.103' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7464, N'1', N'TTC00001', 164, 1, CAST(N'2023-01-14T19:07:54.840' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7465, N'2', N'TTC00001', 164, 1, CAST(N'2023-01-14T19:07:54.907' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7466, N'3', N'TTC00001', 164, 1, CAST(N'2023-01-14T19:07:54.957' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7467, N'4', N'TTC00001', 164, 1, CAST(N'2023-01-14T19:07:55.017' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7468, N'5', N'TTC00001', 164, 1, CAST(N'2023-01-14T19:07:55.097' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7469, N'6', N'TTC00001', 164, 1, CAST(N'2023-01-14T19:07:55.143' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7470, N'7', N'TTC00001', 164, 1, CAST(N'2023-01-14T19:07:55.207' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7471, N'8', N'TTC00001', 164, 1, CAST(N'2023-01-14T19:07:55.283' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7472, N'9', N'TTC00001', 164, 1, CAST(N'2023-01-14T19:07:55.330' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7473, N'10', N'TTC00001', 164, 1, CAST(N'2023-01-14T19:07:55.393' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7474, N'11', N'TTC00001', 164, 1, CAST(N'2023-01-14T19:07:55.457' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7475, N'12', N'TTC00001', 164, 1, CAST(N'2023-01-14T19:07:55.517' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7476, N'13', N'TTC00001', 164, 1, CAST(N'2023-01-14T19:07:55.563' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7477, N'14', N'TTC00001', 164, 1, CAST(N'2023-01-14T19:07:55.627' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7478, N'15', N'TTC00001', 164, 1, CAST(N'2023-01-14T19:07:55.690' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7709, N'1', N'LTC00001', 166, 1, CAST(N'2023-02-13T18:29:13.980' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7710, N'2', N'LTC00001', 166, 1, CAST(N'2023-02-13T18:29:13.993' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7711, N'3', N'LTC00001', 166, 1, CAST(N'2023-02-13T18:29:13.993' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7712, N'4', N'LTC00001', 166, 1, CAST(N'2023-02-13T18:29:13.993' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7713, N'5', N'LTC00001', 166, 1, CAST(N'2023-02-13T18:29:13.993' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7714, N'6', N'LTC00001', 166, 1, CAST(N'2023-02-13T18:29:13.993' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7715, N'7', N'LTC00001', 166, 1, CAST(N'2023-02-13T18:29:14.010' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7716, N'8', N'LTC00001', 166, 1, CAST(N'2023-02-13T18:29:14.010' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7717, N'9', N'LTC00001', 166, 1, CAST(N'2023-02-13T18:29:14.010' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7718, N'10', N'LTC00001', 166, 1, CAST(N'2023-02-13T18:29:14.010' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7735, N'1', N'MAU64', 134, 1, CAST(N'2023-06-08T17:07:13.043' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7736, N'2', N'MAU64', 134, 1, CAST(N'2023-06-08T17:07:13.090' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7737, N'3', N'MAU64', 134, 1, CAST(N'2023-06-08T17:07:13.090' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7738, N'4', N'MAU64', 134, 1, CAST(N'2023-06-08T17:07:13.090' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7739, N'Bed-01', N'HTL16720', 167, 1, CAST(N'2023-06-08T17:13:07.340' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7740, N'Bed-02', N'HTL16720', 167, 1, CAST(N'2023-06-08T17:13:07.340' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7741, N'Bed-03', N'HTL16720', 167, 1, CAST(N'2023-06-08T17:13:07.340' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7742, N'Bed-04', N'HTL16720', 167, 1, CAST(N'2023-06-08T17:13:07.340' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7743, N'Bed-05', N'HTL16720', 167, 1, CAST(N'2023-06-08T17:13:07.357' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7744, N'Bed-06', N'HTL16720', 167, 1, CAST(N'2023-06-08T17:13:07.357' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7745, N'Bed-07', N'HTL16720', 167, 1, CAST(N'2023-06-08T17:13:07.357' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7746, N'Bed-08', N'HTL16720', 167, 1, CAST(N'2023-06-08T17:13:07.357' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7747, N'Bed-09', N'HTL16720', 167, 1, CAST(N'2023-06-08T17:13:07.357' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7748, N'Bed-10', N'HTL16720', 167, 1, CAST(N'2023-06-08T17:13:07.357' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7755, N'Bed-01', N'HTL16720', 168, 1, CAST(N'2023-06-09T15:51:15.233' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7756, N'Bed-02', N'HTL16720', 168, 1, CAST(N'2023-06-09T15:51:15.267' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7757, N'Bed-03', N'HTL16720', 168, 1, CAST(N'2023-06-09T15:51:15.280' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7758, N'Bed-04', N'HTL16720', 168, 1, CAST(N'2023-06-09T15:51:15.297' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7759, N'Bed-05', N'HTL16720', 168, 1, CAST(N'2023-06-09T15:51:15.327' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7760, N'Bed-06', N'HTL16720', 168, 1, CAST(N'2023-06-09T15:51:15.327' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7761, N'201', N'HTL63683', 174, 0, CAST(N'2023-06-09T15:51:15.000' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7762, N'202', N'HTL63683', 174, 0, CAST(N'2023-06-09T15:51:15.000' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7763, N'203', N'HTL63683', 175, 1, CAST(N'2023-06-09T15:51:15.000' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7764, N'204', N'HTL63683', 175, 1, CAST(N'2023-06-09T15:51:15.000' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7765, N'205', N'HTL63683', 175, 1, CAST(N'2023-06-09T15:51:15.000' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7766, N'206', N'HTL63683', 175, 0, CAST(N'2023-06-09T15:51:15.000' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7767, N'207', N'HTL63683', 175, 0, CAST(N'2023-06-09T15:51:15.000' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7778, N'2', N'ALL33', 112, 1, CAST(N'2024-03-15T15:44:41.353' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7779, N'3', N'ALL33', 112, 1, CAST(N'2024-03-15T16:19:57.220' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7783, N'11', N'HTL78404', 94, 1, CAST(N'2024-03-15T18:51:36.033' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7784, N'111', N'HTL78404', 94, 1, CAST(N'2024-03-15T18:51:50.580' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7785, N'12', N'HTL99957', 43, 1, CAST(N'2024-03-15T19:06:29.023' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7786, N'11', N'HTL99957', 43, 1, CAST(N'2024-03-15T19:06:32.460' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7787, N'12', N'HTL99957', 43, 1, CAST(N'2024-03-15T19:07:23.653' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7788, N'111', N'HTL10191', 2, 1, CAST(N'2024-03-15T19:12:54.960' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7789, N'22', N'HTL10389', 51, 1, CAST(N'2024-03-15T19:17:14.663' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7790, N'101', N'HTL10389', 52, 1, CAST(N'2024-03-18T12:46:03.650' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7791, N'102', N'HTL10389', 52, 1, CAST(N'2024-03-18T12:46:05.170' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7792, N'00001', N'HTL91324', 53, 0, CAST(N'2024-03-18T12:54:58.190' AS DateTime), 1, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7793, N'00002', N'HTL91324', 53, 1, CAST(N'2024-03-18T12:54:59.810' AS DateTime), 0, NULL, NULL, NULL)
GO
INSERT [dbo].[tbl_RoomDetail] ([RoomId], [RoomNo], [HotelId], [CategoryId], [IsActive], [EntryDate], [IsOffLine], [OffLineDate], [OLDatefrom], [OLDateTo]) VALUES (7794, N'00003', N'HTL91324', 53, 1, CAST(N'2024-03-18T12:55:01.807' AS DateTime), 0, NULL, NULL, NULL)
GO
SET IDENTITY_INSERT [dbo].[tbl_RoomDetail] OFF
GO
SET IDENTITY_INSERT [dbo].[tbl_RoomImages] ON 
GO
INSERT [dbo].[tbl_RoomImages] ([Id], [hotelId], [CategoryId], [ImagePath], [ImageExt], [EntryDate]) VALUES (1, N'ALL33', 112, N'/Upload/RoomImages/087ff4fc-e463-46e0-b517-bf718efeef45_.jpg', NULL, CAST(N'2024-03-14T11:45:39.107' AS DateTime))
GO
INSERT [dbo].[tbl_RoomImages] ([Id], [hotelId], [CategoryId], [ImagePath], [ImageExt], [EntryDate]) VALUES (2, N'ALL33', 112, N'/Upload/RoomImages/9f689aed-81db-4227-8fa9-5ea4d5605734_.jpg', NULL, CAST(N'2024-03-14T12:59:03.600' AS DateTime))
GO
INSERT [dbo].[tbl_RoomImages] ([Id], [hotelId], [CategoryId], [ImagePath], [ImageExt], [EntryDate]) VALUES (3, N'BAD67', 141, N'/Upload/RoomImages/a82cbdda-6cfa-49b1-b9f7-6be04692808d_.jpg', NULL, CAST(N'2024-03-14T12:59:50.647' AS DateTime))
GO
INSERT [dbo].[tbl_RoomImages] ([Id], [hotelId], [CategoryId], [ImagePath], [ImageExt], [EntryDate]) VALUES (4, N'BAD67', 143, N'/Upload/RoomImages/903f31fb-550f-4554-add9-e2a4c7662bed_.jpg', NULL, CAST(N'2024-03-14T13:01:14.983' AS DateTime))
GO
INSERT [dbo].[tbl_RoomImages] ([Id], [hotelId], [CategoryId], [ImagePath], [ImageExt], [EntryDate]) VALUES (5, N'BAD67', 144, N'/Upload/RoomImages/37b98bbf-e2f0-4617-8bfa-784d0e06199c_.jpg', NULL, CAST(N'2024-03-14T13:03:48.933' AS DateTime))
GO
INSERT [dbo].[tbl_RoomImages] ([Id], [hotelId], [CategoryId], [ImagePath], [ImageExt], [EntryDate]) VALUES (6, N'BAD67', 141, N'/Upload/RoomImages/133036dc-777d-4465-b1f1-00d24505b1e0_.jpg', NULL, CAST(N'2024-03-18T17:45:07.990' AS DateTime))
GO
INSERT [dbo].[tbl_RoomImages] ([Id], [hotelId], [CategoryId], [ImagePath], [ImageExt], [EntryDate]) VALUES (7, N'BAD67', 141, N'/Upload/RoomImages/e27bf952-37ce-4193-9929-fa1af24ba1f7_.jpg', NULL, CAST(N'2024-03-18T17:46:11.410' AS DateTime))
GO
INSERT [dbo].[tbl_RoomImages] ([Id], [hotelId], [CategoryId], [ImagePath], [ImageExt], [EntryDate]) VALUES (8, N'106', 177, N'/Upload/RoomImages/2543ec5e-dc1d-4996-84c4-d5b54e98c5fc_.jpg', NULL, CAST(N'2024-03-18T17:46:35.560' AS DateTime))
GO
INSERT [dbo].[tbl_RoomImages] ([Id], [hotelId], [CategoryId], [ImagePath], [ImageExt], [EntryDate]) VALUES (9, N'106', 177, N'/Upload/RoomImages/5d153bab-29da-41a6-8672-48f1deff7877_.jpg', NULL, CAST(N'2024-03-18T17:46:42.283' AS DateTime))
GO
INSERT [dbo].[tbl_RoomImages] ([Id], [hotelId], [CategoryId], [ImagePath], [ImageExt], [EntryDate]) VALUES (10, N'ALL33', 112, N'/Upload/RoomImages/d28a3e43-b419-4355-a3a9-bc3771ba384e_.jpg', NULL, CAST(N'2024-03-18T18:03:55.420' AS DateTime))
GO
INSERT [dbo].[tbl_RoomImages] ([Id], [hotelId], [CategoryId], [ImagePath], [ImageExt], [EntryDate]) VALUES (11, N'HTL24279', 58, N'/Upload/RoomImages/4f08a612-6986-4d4a-a0da-48dc6d724c0b_.jpg', NULL, CAST(N'2024-03-18T18:06:29.987' AS DateTime))
GO
INSERT [dbo].[tbl_RoomImages] ([Id], [hotelId], [CategoryId], [ImagePath], [ImageExt], [EntryDate]) VALUES (12, N'ALL33', 112, N'/Upload/RoomImages/', NULL, CAST(N'2024-03-18T18:13:23.883' AS DateTime))
GO
INSERT [dbo].[tbl_RoomImages] ([Id], [hotelId], [CategoryId], [ImagePath], [ImageExt], [EntryDate]) VALUES (13, N'ALL33', 113, N'/Upload/RoomImages/43cff1ef-ba48-4d7d-b57d-8b71cea4377a_.jpg', NULL, CAST(N'2024-03-18T18:14:25.680' AS DateTime))
GO
SET IDENTITY_INSERT [dbo].[tbl_RoomImages] OFF
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [B04_ChickInDetails_Check1]    Script Date: 04-Apr-2024 15:17:12 ******/
ALTER TABLE [dbo].[B04_ChickInDetails] ADD  CONSTRAINT [B04_ChickInDetails_Check1] UNIQUE NONCLUSTERED 
(
	[HotelId] ASC,
	[CategoryId] ASC,
	[CheckInDate] ASC,
	[CheckOutDate] ASC,
	[RoomNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_StateMaster]    Script Date: 04-Apr-2024 15:17:12 ******/
ALTER TABLE [dbo].[StateMaster] ADD  CONSTRAINT [IX_StateMaster] UNIQUE NONCLUSTERED 
(
	[StateName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Login] ADD  CONSTRAINT [DF_Tbl_Person_Login_Created_Date]  DEFAULT (getdate()) FOR [Created_Date]
GO
ALTER TABLE [dbo].[Login] ADD  CONSTRAINT [DF_Tbl_Person_Login_Is_Active]  DEFAULT ((1)) FOR [Is_Active]
GO
ALTER TABLE [dbo].[StateMaster] ADD  CONSTRAINT [DF_StateMaster_EntryDate]  DEFAULT (getdate()) FOR [EntryDate]
GO
ALTER TABLE [dbo].[tbl_CategoryMaster] ADD  CONSTRAINT [DF_tbl_CategoryMaster_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[tbl_CategoryMaster] ADD  CONSTRAINT [DF_tbl_CategoryMaster_EntryDate]  DEFAULT (getdate()) FOR [EntryDate]
GO
ALTER TABLE [dbo].[tbl_CategoryMaster] ADD  DEFAULT ((0)) FOR [IsOffline]
GO
ALTER TABLE [dbo].[tbl_HotelImageMaster] ADD  CONSTRAINT [DF_tbl_HotelImageMaster_EntryDate]  DEFAULT (getdate()) FOR [EntryDate]
GO
ALTER TABLE [dbo].[tbl_HotelImageMaster] ADD  CONSTRAINT [DF_tbl_HotelImageMaster_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[tbl_HotelMaster] ADD  CONSTRAINT [DF_tbl_HotelMaster_EntryDate]  DEFAULT (getdate()) FOR [EntryDate]
GO
ALTER TABLE [dbo].[tbl_HotelMaster] ADD  CONSTRAINT [DF_tbl_HotelMaster_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[tbl_RoomDetail] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[B01_BookingDetails]  WITH CHECK ADD FOREIGN KEY([HotelId])
REFERENCES [dbo].[tbl_HotelMaster] ([HotelId])
GO
ALTER TABLE [dbo].[B02_BookingRoomDetails]  WITH CHECK ADD  CONSTRAINT [FK__B02_Booki__Booki__619B8048] FOREIGN KEY([BookingId])
REFERENCES [dbo].[B01_BookingDetails] ([BookingId])
GO
ALTER TABLE [dbo].[B02_BookingRoomDetails] CHECK CONSTRAINT [FK__B02_Booki__Booki__619B8048]
GO
ALTER TABLE [dbo].[B02_BookingRoomDetails]  WITH CHECK ADD  CONSTRAINT [FK__B02_Booki__Categ__6383C8BA] FOREIGN KEY([CategoryId])
REFERENCES [dbo].[tbl_CategoryMaster] ([ID])
GO
ALTER TABLE [dbo].[B02_BookingRoomDetails] CHECK CONSTRAINT [FK__B02_Booki__Categ__6383C8BA]
GO
ALTER TABLE [dbo].[B02_BookingRoomDetails]  WITH CHECK ADD  CONSTRAINT [FK__B02_Booki__Hotel__628FA481] FOREIGN KEY([HotelId])
REFERENCES [dbo].[tbl_HotelMaster] ([HotelId])
GO
ALTER TABLE [dbo].[B02_BookingRoomDetails] CHECK CONSTRAINT [FK__B02_Booki__Hotel__628FA481]
GO
ALTER TABLE [dbo].[B03_TransactionDetails]  WITH CHECK ADD  CONSTRAINT [FK__B03_Trans__Booki__66603565] FOREIGN KEY([BookingId])
REFERENCES [dbo].[B01_BookingDetails] ([BookingId])
GO
ALTER TABLE [dbo].[B03_TransactionDetails] CHECK CONSTRAINT [FK__B03_Trans__Booki__66603565]
GO
ALTER TABLE [dbo].[B04_ChickInDetails]  WITH CHECK ADD  CONSTRAINT [FK__B04_Chick__Booki__693CA210] FOREIGN KEY([BookingId])
REFERENCES [dbo].[B01_BookingDetails] ([BookingId])
GO
ALTER TABLE [dbo].[B04_ChickInDetails] CHECK CONSTRAINT [FK__B04_Chick__Booki__693CA210]
GO
ALTER TABLE [dbo].[B04_ChickInDetails]  WITH CHECK ADD  CONSTRAINT [FK__B04_Chick__Categ__6B24EA82] FOREIGN KEY([CategoryId])
REFERENCES [dbo].[tbl_CategoryMaster] ([ID])
GO
ALTER TABLE [dbo].[B04_ChickInDetails] CHECK CONSTRAINT [FK__B04_Chick__Categ__6B24EA82]
GO
ALTER TABLE [dbo].[B04_ChickInDetails]  WITH CHECK ADD  CONSTRAINT [FK__B04_Chick__Hotel__6A30C649] FOREIGN KEY([HotelId])
REFERENCES [dbo].[tbl_HotelMaster] ([HotelId])
GO
ALTER TABLE [dbo].[B04_ChickInDetails] CHECK CONSTRAINT [FK__B04_Chick__Hotel__6A30C649]
GO
ALTER TABLE [dbo].[RateMaster]  WITH CHECK ADD FOREIGN KEY([CategoryId])
REFERENCES [dbo].[tbl_CategoryMaster] ([ID])
GO
ALTER TABLE [dbo].[RateMaster]  WITH CHECK ADD FOREIGN KEY([HotelId])
REFERENCES [dbo].[tbl_HotelMaster] ([HotelId])
GO
ALTER TABLE [dbo].[tbl_CategoryMaster]  WITH CHECK ADD FOREIGN KEY([bed_id])
REFERENCES [dbo].[tbl_BedMaster] ([bed_id])
GO
ALTER TABLE [dbo].[tbl_CategoryMaster]  WITH CHECK ADD FOREIGN KEY([hotelid])
REFERENCES [dbo].[tbl_HotelMaster] ([HotelId])
GO
ALTER TABLE [dbo].[tbl_RoomDetail]  WITH CHECK ADD FOREIGN KEY([CategoryId])
REFERENCES [dbo].[tbl_CategoryMaster] ([ID])
GO
ALTER TABLE [dbo].[tbl_RoomDetail]  WITH CHECK ADD FOREIGN KEY([HotelId])
REFERENCES [dbo].[tbl_HotelMaster] ([HotelId])
GO
/****** Object:  StoredProcedure [dbo].[USP_BookingDetails]    Script Date: 04-Apr-2024 15:17:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[USP_BookingDetails]
(
@Action VARCHAR(8),
@BookingId          BIGINT =NULL,
@HotelId            VARCHAR (32) =NULL,
@CategoryId         INT =NULL,
@CheckInDate        DATETIME =NULL,
@CheckOutDate       DATETIME =NULL,
@BookingStatus      VARCHAR (32)=NULL

)
AS
BEGIN

SELECT * FROM B02_BookingRoomDetails



END
GO
/****** Object:  StoredProcedure [dbo].[USP_BookingRoomDetails]    Script Date: 04-Apr-2024 15:17:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[USP_BookingRoomDetails]
@Action VARCHAR(10)=NULL,
@RoomId  int =null,   
@RoomNo VARCHAR (16)=null,
@HotelId  VARCHAR (32) =null,
@CategoryId   int =null, 
@IsActive  bit=0,
@IsOffLine  bit=0,
@OffLineDate DateTime=null,   
@OLDatefrom  DateTime=null,   
@OLDateTo   DateTime=null 

AS

BEGIN
	IF(@Action ='1')
	BEGIN
  		SELECT b.HotelId, b.HotelName, a.Id, a.Category, c.CityName, 
		NoOfRooms = (SELECT count(1) FROM tbl_RoomDetail x WHERE x.HotelId=a.hotelid AND x.CategoryId=a.ID AND x.IsActive=1)
 		FROM tbl_CategoryMaster a
		JOIN tbl_HotelMaster b  ON b.HotelId = a.hotelid
		JOIN CityMaster c  ON c.id = b.cityid
		
	END
	
	if(@Action='2')  
	begin   
		BEGIN TRY      
			BEGIN TRANSACTION trans   		
		  SET @IsActive=1;
		  SET @IsOffLine=0;
 	  
			 INSERT INTO tbl_RoomDetail(RoomNo, HotelId, CategoryId, IsActive, EntryDate, IsOffLine, OffLineDate,OLDatefrom,OLDateTo) 
			 VALUES (@RoomNo,@HotelId,@CategoryId, @IsActive, GetDate(), @IsOffLine, @OffLineDate, @OLDatefrom, @OLDateTo)
			 	  		
			COMMIT TRANSACTION trans 
				SELECT 1 Id ,'Record Successfully Saved !!!' msg    
		END TRY       
		BEGIN CATCH      
			--SELECT error_message()      
			SELECT 0 Id ,error_message() msg    
			ROLLBACK TRANSACTION trans      
		END CATCH 
	END
	
    IF(@Action ='3')
	BEGIN
	SELECT RD.RoomId, RD.RoomNo, RD.HotelId,HM.HotelName, RD.CategoryId, CM.Category, RD.IsActive, RD.EntryDate,
   	   RD.OffLineDate, RD.IsOffLine
		FROM tbl_RoomDetail RD WITH (nolock) 
		LEFT JOIN tbl_HotelMaster HM WITH (nolock) ON  RD.HotelId = HM.HotelId		
	 	LEFT JOIN tbl_CategoryMaster CM WITH (nolock) ON  CM.Id = RD.CategoryId		
		WHERE  RD.HotelId=@HotelId AND RD.CategoryId=@CategoryId 
		
	END	
    if(@Action='4')  
    	BEGIN  
    		BEGIN TRY      
			BEGIN TRANSACTION trans   
 	  	   			UPDATE tbl_RoomDetail SET IsActive=@IsActive WHERE RoomId=@RoomId  	
 	  	   			COMMIT TRANSACTION trans 
				SELECT 1 Id ,'Record Successfully Saved !!!' msg    
		END TRY       
		BEGIN CATCH      
			--SELECT error_message()      
			SELECT 0 Id ,error_message() msg    
			ROLLBACK TRANSACTION trans      
		END CATCH  
		END 
 	if(@Action='5')  
      	BEGIN  
    		BEGIN TRY      
			BEGIN TRANSACTION trans  
 	  		UPDATE tbl_RoomDetail SET IsOffLine=@IsOffLine WHERE RoomId=@RoomId  
 	  		COMMIT TRANSACTION trans 
				SELECT 1 Id ,'Record Successfully Saved !!!' msg    
		END TRY       
		BEGIN CATCH      
			--SELECT error_message()      
			SELECT 0 Id ,error_message() msg    
			ROLLBACK TRANSACTION trans      
		END CATCH  	 
		END 
	
	
END
GO
/****** Object:  StoredProcedure [dbo].[USP_CategoryMaster]    Script Date: 04-Apr-2024 15:17:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- *** SqlDbx Personal Edition ***
-- !!! Not licensed for commercial use beyound 90 days evaluation period !!!
-- For version limitations please check http://www.sqldbx.com/personal_edition.htm
-- Number of queries executed: 55, number of rows retrieved: 57462

CREATE PROC [dbo].[USP_CategoryMaster]  
(  
@Action VARCHAR(8)=NULL,  
@ID INT=0,  
@HotelId VARCHAR(32)=NULL,  
@Category NVARCHAR(500)=NULL,  
@CityId int=NULL,  
@bed_id INT=NULL,  
@IsActive BIT=0  
)  
AS  
BEGIN  
  if(@Action ='1')  
  begin     
  SELECT CAT.ID, CAT.Category,BM.BedName, HM.HotelId, HM.HotelName, HM.Address  
  FROM tbl_CategoryMaster CAT    
  LEFT JOIN tbl_HotelMaster HM ON CAT.hotelid = HM.hotelid  
  LEFT JOIN tbl_BedMaster BM ON CAT.bed_id = BM.bed_id  order by CAT.EntryDate DESC
  end  
    
  if(@Action ='2')  
  begin     
    BEGIN TRY      
    BEGIN TRANSACTION trans    
   	SET @IsActive=1;
    --SET @ID = (SELECT ISNULL(MAX(ID), 0) + 1 FROM tbl_CategoryMaster)  
  
    INSERT INTO tbl_CategoryMaster( Category, IsActive, EntryDate, HotelId, bed_id) VALUES (@Category,@IsActive,GETDATE(),@HotelId,@bed_id)    
      
    COMMIT TRANSACTION trans         
      
    SELECT 1 Id ,'Record Successfully Saved !!!' msg      
      
   END TRY       
   BEGIN CATCH      
   --SELECT error_message()      
    SELECT 0 Id ,Error_message() msg    
    ROLLBACK TRANSACTION trans      
   END CATCH      
  end  
  
  if(@Action ='3')  
  begin     
  SELECT CAT.ID, CAT.Category, hm.CityId,CM.CityName,CM.ID, HM.HotelId, HM.HotelName, HM.Address, CAT.bed_id,BM.BedName  
  FROM tbl_CategoryMaster CAT    
  LEFT JOIN tbl_HotelMaster HM ON CAT.hotelid = HM.hotelid  
  LEFT JOIN cityMaster CM ON hm.CityId = cm.ID  
  LEFT JOIN tbl_BedMaster BM ON BM.bed_id = CAT.bed_id
  where CAT.ID=@ID      
  end  

    
  if(@Action ='4')  
  begin     
    BEGIN TRY      
    BEGIN TRANSACTION trans       
      
    SET @IsActive=1;  
    
    --SET @ID = (SELECT ISNULL(MAX(ID), 0) + 1 FROM tbl_CategoryMaster)  
  
    UPDATE tbl_CategoryMaster SET Category=@Category, IsActive=@IsActive, EntryDate=GETDATE(), HotelId=@HotelId, 
	bed_id=@bed_id  WHERE ID=@ID
      
    COMMIT TRANSACTION trans  
      
    SELECT 1 Id ,'Record Updated Successfully !!!' msg      
      
   END TRY       
   BEGIN CATCH      
   --SELECT error_message()      
    SELECT 0 Id ,'Record Not Updated Successfully !!!' msg    
    ROLLBACK TRANSACTION trans      
   END CATCH      
  end  
  
END
GO
/****** Object:  StoredProcedure [dbo].[USP_CategoryWiseRoomDetails]    Script Date: 04-Apr-2024 15:17:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[USP_CategoryWiseRoomDetails] -- USP_CategoryWiseRoomDetails '1','HTL82734',null,'2024-02-15','2024-02-17'
(
@Action VARCHAR(8),
@HotelId            VARCHAR (32),
@CategoryId         INT =NULL,
@CheckInDate        DATETIME,
@CheckOutDate       DATETIME

)
AS
BEGIN
SET NOCOUNT ON;


IF @Action = '1'
BEGIN

IF @CategoryId ='' OR @CategoryId ='0'
SET @CategoryId = NULL;




CREATE TABLE #RoomDetails(
  HotelId VARCHAR (32)
, CategoryId INT
, Category NVARCHAR (500)
, TotalRoom INT
, BookedRoom INT
, AvailableRoom INT
, PricePerDay        DECIMAL (18, 0)
, PriceDifference    DECIMAL (18, 0)
, DoubleOccupancy DECIMAL (18, 0)
, ExtraBedPercentage DECIMAL (18, 4)
, ExtraBedAmt DECIMAL (18, 0)
, bed_id INT
, BedName VARCHAR (100)
, noofBed INT

)

INSERT INTO #RoomDetails(HotelId, CategoryId,bed_id, Category, TotalRoom,PricePerDay,PriceDifference,ExtraBedPercentage)
SELECT t1.HotelId,t1.CategoryId,t2.bed_id,t2.Category,t1.TotalRoom,PricePerDay,PriceDifference,ExtraBedPercentage FROM(
SELECT * FROM RoomDetail_CategoryWise_ForBooking a
WHERE a.HotelId= @HotelId AND a.CategoryId = isnull(@CategoryId, a.CategoryId )
)t1 JOIN  tbl_CategoryMaster t2 ON t1.CategoryId=t2.ID
JOIN
(
SELECT HotelId, CategoryId, PricePerDay, PriceDifference, ExtraBedPercentage FROM (
SELECT row_number()OVER(PARTITION BY CategoryId ORDER BY RateID DESC)Sno,* FROM(
SELECT RateID,HotelId, CategoryId, PricePerDay, PriceDifference, ExtraBedPercentage 
FROM RateMaster WHERE HotelId=@HotelId
AND convert(DATE,getdate()) BETWEEN RateStartDate AND RateEndDate
)t )tt WHERE tt.Sno=1
)t3 ON t1.CategoryId=t3.CategoryId

UPDATE a SET 
ExtraBedAmt=(PricePerDay+PriceDifference)*ExtraBedPercentage,
DoubleOccupancy=(PricePerDay+PriceDifference)
FROM #RoomDetails a

UPDATE a SET 
BedName=b.BedName,
noofBed=b.noofBed
FROM #RoomDetails a
JOIN tbl_BedMaster b ON a.bed_id=b.bed_id





UPDATE a SET BookedRoom=dbo.GetBookedRooms(HotelId, CategoryId,@CheckInDate,@CheckOutDate) FROM #RoomDetails a



UPDATE a SET AvailableRoom=isnull(TotalRoom,0)-isnull(BookedRoom,0) FROM #RoomDetails a

SELECT * FROM #RoomDetails
END 

END
GO
/****** Object:  StoredProcedure [dbo].[USP_CityMaster]    Script Date: 04-Apr-2024 15:17:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- *** SqlDbx Personal Edition ***
-- !!! Not licensed for commercial use beyound 90 days evaluation period !!!
-- For version limitations please check http://www.sqldbx.com/personal_edition.htm
-- Number of queries executed: 525, number of rows retrieved: 57120

CREATE PROC [dbo].[USP_CityMaster]
@Action VARCHAR(10)=NULL,
@id INT=0,
@StateId INT =0,
@CityName NVARCHAR(500)=NULL,
@IsDeleted bit=0,
@EntryDate DATETIME=NULL,
@UnitAbbr NVARCHAR(100)= NULL 
AS
BEGIN
	IF(@Action='1')
	BEGIN
		SELECT CM.Id, SM.StateName, CM.CityName, CM.UnitAbbr FROM CityMaster CM
		INNER JOIN StateMaster SM ON CM.StateId=SM.StateId
	END
	IF(@Action='2')
	BEGIN
		BEGIN TRY      
			BEGIN TRANSACTION trans  
			SET @IsDeleted=0;
			  
				--set @Id=(SELECT isnull(max(ID),0)+1 FROM CityMaster )   
				INSERT into CityMaster(CityName, UnitAbbr, StateId,entryDate,IsDeleted) values 
				(@CityName,@UnitAbbr,@StateId,getDate(),@IsDeleted)	 
			COMMIT TRANSACTION trans 
				SELECT 1 Id ,'Record Successfully Saved !!!' msg    
		END TRY       
		BEGIN CATCH      
			--SELECT error_message()      
			SELECT 0 Id ,'Record not Saved !!!' msg    
			ROLLBACK TRANSACTION trans      
		END CATCH
	END
	IF(@Action='3')
	BEGIN
		SELECT CM.Id,SM.StateId, SM.StateName, CM.CityName, CM.UnitAbbr FROM CityMaster CM
		INNER JOIN StateMaster SM ON CM.StateId=SM.StateId WHERE Id=@Id 
	END
	IF(@Action='4')
	BEGIN
		BEGIN TRY      
			BEGIN TRANSACTION trans    
				--set @HotelId=(SELECT isnull(max(ID),0)+1 FROM tbl_HotelMaster )   
				UPDATE CityMaster SET CityName=@CityName, StateId=@StateId, IsDeleted=@IsDeleted, UnitAbbr=@UnitAbbr,EntryDate=getdate()
				WHERE ID=@Id
			   
			COMMIT TRANSACTION trans 
				SELECT 1 Id ,'Record Updated Successfully !!!' msg    
		END TRY       
		BEGIN CATCH      
			--SELECT error_message()      
			SELECT 0 Id ,'Record not Updated !!!' msg    
			ROLLBACK TRANSACTION trans      
		END CATCH
	END
end
GO
/****** Object:  StoredProcedure [dbo].[USP_DynamicDropDownList]    Script Date: 04-Apr-2024 15:17:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROC [dbo].[USP_DynamicDropDownList]
(
@Action VARCHAR(10)=NULL,
@StateId int =null,
@HotelId NVARCHAR(500)=null,
@CityId int =null
)
AS
	BEGIN
		if(@Action='1')
			BEGIN
				SELECT StateId, StateName, StateCode FROM StateMaster
			END
		if(@Action='2')
			BEGIN
				SELECT Id, CityName, StateId, UnitAbbr FROM CityMaster where StateId =@StateId
				
			END
		if(@Action='3')
			BEGIN
				SELECT Id, CityName, StateId, UnitAbbr FROM CityMaster
				
			END
		if(@Action='4')
			BEGIN
				SELECT HotelId, HotelName,StateId,CityId FROM tbl_HotelMaster where CityId=@CityId
				
			END
		if(@Action='5')
			BEGIN
				SELECT Id, Category, hotelid FROM tbl_CategoryMaster where HotelId =@HotelId
				
			END
		if(@Action='6')
			BEGIN
				SELECT HotelId, HotelName FROM tbl_HotelMaster 
				
			END
		if(@Action='7')
			BEGIN
				SELECT bed_id, BedName FROM tbl_BedMaster 
				
			END
	END
GO
/****** Object:  StoredProcedure [dbo].[USP_GetManageBookingData]    Script Date: 04-Apr-2024 15:17:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[USP_GetManageBookingData]
(
@Action VARCHAR(8),
@BookingId          BIGINT =NULL,
@HotelId            VARCHAR (32) =NULL,
@CategoryId         INT =NULL,
@CheckInDate        DATETIME =NULL,
@CheckOutDate       DATETIME =NULL,
@BookingStatus      VARCHAR (32)=NULL

)
AS
BEGIN

IF @Action = ''
BEGIN

DECLARE	@TotalAmt DECIMAL(18, 2)=0;
DECLARE	@PaidAmt DECIMAL(18, 2)=0;
DECLARE	@DueAmount  DECIMAL(18, 2)=0;
   
SELECT @TotalAmt=sum(TotalPayable) FROM B04_ChickInDetails WHERE BookingId = @BookingId 


SELECT @PaidAmt=sum(PaidAmount) FROM  B03_TransactionDetails a WHERE BookingId=@BookingId


SET @DueAmount = isnull(@TotalAmt,0)-isnull(@PaidAmt,0);


END 


END
GO
/****** Object:  StoredProcedure [dbo].[USP_GstMaster]    Script Date: 04-Apr-2024 15:17:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- *** SqlDbx Personal Edition ***
-- !!! Not licensed for commercial use beyound 90 days evaluation period !!!
-- For version limitations please check http://www.sqldbx.com/personal_edition.htm
-- Number of queries executed: 509, number of rows retrieved: 57025

CREATE PROC [dbo].[USP_GstMaster]  
(  
@Action varchar(5),  
@GSTId int=NULL,  
@StartAmt decimal(18,2)=NULL,  
@EndAmt decimal(18,2)=NULL,  
@GSTPer decimal(18,2)=NULL  
)  
AS  
BEGIN  
 IF(@Action='1')  
  BEGIN  
   SELECT GSTID, StartAmt, EndAmt, GSTPer FROM GSTMaster ORDER BY StartAmt 
  END  
 IF(@Action='2')  
  BEGIN  
   BEGIN TRY  
    BEGIN TRAN TRANS  
     SET @GSTID =(SELECT ISNULL(MAX(GSTID),0)+1 FROM GSTMaster)  
  
     INSERT INTO GSTMaster(GSTID, StartAmt, EndAmt,GSTPer)   
     VALUES (@GSTId, @StartAmt, @EndAmt, @GSTPer)  
       
    COMMIT TRAN TRANS  
    SELECT 1 ID, 'RECORD SAVED SUCCESSFULLY !!!' msg  
  
   END TRY  
   BEGIN CATCH  
    --- SELECT ERROR_MESSAGE()  
    SELECT 0 ID, ERROR_MESSAGE() msg  
   END CATCH  
  END  

  IF(@Action='3')  
  BEGIN  
   SELECT GSTID, StartAmt, EndAmt, GSTPer FROM GSTMaster  WHERE GSTId=@GSTId
  END  

   IF(@Action='4')  
  BEGIN  
   BEGIN TRY  
    BEGIN TRAN TRANS  
    -- SET @GSTID =(SELECT ISNULL(MAX(@GSTId),0)+1 FROM GSTMaster)  
  
     UPDATE GSTMaster SET StartAmt= @StartAmt, EndAmt=@EndAmt, GSTPer=@GSTPer WHERE GSTID=@GSTId  
       
    COMMIT TRAN TRANS  
    SELECT 1 ID, 'RECORD UPDATED SUCCESSFULLY !!!' msg  
  
   END TRY  
   BEGIN CATCH  
    --- SELECT ERROR_MESSAGE()  
    SELECT 0 ID, 'RECORD NOT UPDATED SUCCESSFULLY !!!' msg  
   END CATCH  
  END  

END
GO
/****** Object:  StoredProcedure [dbo].[USP_HotelDetails]    Script Date: 04-Apr-2024 15:17:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[USP_HotelDetails]
@Action VARCHAR(10)
AS
BEGIN 
	IF(@Action='1')
	BEGIN
		SELECT isnull(lo.userName,'') AS userName, isnull(lo.password,'NA') AS password,isnull(HM.HotelName,'NA') AS HotelName,
		isnull(HM.EmailId,'NA') AS EmailId, isnull(HM.EntryDate,'') AS EntryDate  FROM Login lo 
		LEFT JOIN tbl_HotelMaster HM ON lo.HotelId=HM.HotelId
	END
END
GO
/****** Object:  StoredProcedure [dbo].[USP_HotelImagesMaster]    Script Date: 04-Apr-2024 15:17:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[USP_HotelImagesMaster]
@Action varchar(10),
@Id int=0,
@ImagePath nvarchar(max)=null,
@IsActive bit=0,
@HotelId varchar(50)=null,
@ImgExt nvarchar(50)=null

as
Begin
	if(@Action='1')
		BEGIN
			SELECT Id, HotelId, ImagePath, ImgExt FROM tbl_HotelImageMaster WHERE HotelId=@HotelId
		END

	if(@Action='2')
    BEGIN
    BEGIN TRY    
		BEGIN TRANSACTION trans  
		insert into tbl_HotelImageMaster(ImagePath, EntryDate, IsActive,HotelId, ImgExt)
		values(@ImagePath,GETDATE(), @IsActive, @HotelId,@ImgExt)
	COMMIT TRANSACTION trans    
        
     SELECT 1 Id ,'Record Successfully Saved !!!' msg  
	  
    END TRY     
    BEGIN CATCH    
     --SELECT error_message()    
	   SELECT 0 Id ,'Record not Saved !!!' msg  
     ROLLBACK TRANSACTION trans    
    END CATCH    
	 
  END
end
GO
/****** Object:  StoredProcedure [dbo].[USP_InsertBooking]    Script Date: 04-Apr-2024 15:17:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[USP_InsertBooking]
(
@Action VARCHAR(8),
@HotelId VARCHAR(32),
@BookingGuestName NVARCHAR(150),
@GuestName  NVARCHAR(150),
@GuestMobileNo  NVARCHAR(150),
@GuestEmailId  NVARCHAR(150)=NULL,
@gstNo  VARCHAR(150)=NULL,
@PaymentMode  VARCHAR(150),
@Referencenumber  VARCHAR(50)=NULL,
@GSTNature  VARCHAR(32),
@GSTPer DECIMAL(18,2),
@DiscountPer DECIMAL(18,2),
@DiscountReason NVARCHAR(400)=NULL,
@PayAmount DECIMAL(18,2),
@EntryBy VARCHAR(150)=NULL,
@RoomeDetailJson NVARCHAR(max)
)
AS 
BEGIN

BEGIN TRY
BEGIN TRANSACTION


IF @Action = '1'
BEGIN

DECLARE @Status VARCHAR(32)='Success';
DECLARE @BookingStatus VARCHAR(32)='Booked'
DECLARE @Billno VARCHAR(32)=NULL;


DECLARE @DocketeNo VARCHAR(16)=NULL;
DECLARE @UnitAbbr VARCHAR(16)=NULL;

SELECT @UnitAbbr=HotalCodenew FROM  tbl_HotelMaster WHERE HotelId = @HotelId

SET @DocketeNo=@UnitAbbr+Right(cast(year(GETDATE()) as varchar),2)+Right('00000'+cast(convert(VARCHAR(16),((SELECT (RBSno) from InvoiceNotbl)+1)) as varchar),5);
update InvoiceNotbl set RBSno=RBSno+1

-------------VoucherNo
DECLARE @VoucherNo VARCHAR(32)=isnull((select max(B03_Transaction_ID) FROM B03_TransactionDetails),0)+1;
   
CREATE TABLE #Roomdetails
	(
	HotelId VARCHAR(32),
	CategoryId INT,
	CheckInDate DATE,
	CheckOutDate DATE,
	Days INT,
	NoOfBed INT,
	NoofRooms INT,
	AvailableRooms INT,
	NoofAdults INT,
	RoomCharge INT,
	DoubleOccupancyCharge INT,
	ExtraBedCharge INT,
	NoofChilds         INT,
	ExtraBed           INT,
	DoubleOccupancy    INT,
	RoomAmt            DECIMAL (18, 2),
	DoubleOccupancyAmt DECIMAL (18, 2),
	ExtraBedamt        DECIMAL (18, 2),
	TotalRoomAmt       DECIMAL (18, 2),
	DiscountPer        DECIMAL (18, 2),
	DisountAmount      DECIMAL (18, 2),
	GrossAmount        DECIMAL (18, 2),
	GStPer             DECIMAL (18, 2),
	CGST               DECIMAL (18, 2),
	SGST               DECIMAL (18, 2),
	TotalGST           DECIMAL (18, 2),
	TotalPayable       DECIMAL (18, 2),
		GSTNature  VARCHAR(32)
	)


INSERT INTO #Roomdetails(HotelId,CategoryId, CheckInDate, CheckOutDate, NoofRooms, NoofAdults, RoomCharge, DoubleOccupancyCharge, ExtraBedCharge)
SELECT @HotelId,categoryId, CheckInDate, CheckOutDate, Noofrooms, NoofPerson, roomcharge, doublebedcharge, extrabedprice
FROM OPENJSON(@RoomeDetailJson)
WITH (
    categoryId INT '$.categoryId',
    CheckInDate DATE '$.CheckInDate',
    CheckOutDate DATE '$.CheckOutDate',
    Noofrooms INT '$.Noofrooms',
    NoofPerson INT '$.NoofPerson',
    roomcharge INT '$.roomcharge',
    doublebedcharge INT '$.doublebedcharge',
    extrabedprice INT '$.extrabedprice'
);

UPDATE #Roomdetails SET AvailableRooms = dbo.GetAvailableRooms(HotelId,CategoryId, CheckInDate, CheckOutDate)

IF EXISTS(SELECT 1 FROM #Roomdetails WHERE Noofrooms>AvailableRooms)
BEGIN
SELECT '0' AS flag,'Room Not Available' AS msg
ROLLBACK;
RETURN
END 

DECLARE @CheckInDate DATE;
DECLARE @CheckOutDate DATE;

SELECT @CheckInDate=min(CheckInDate),@CheckOutDate=max(CheckOutDate) FROM #Roomdetails


INSERT INTO dbo.B01_BookingDetails (BookingDate, CheckInDate, CheckOutDate, HotelId, Status, BookingStatus,GuestLoginId, GuestMobileNo, GuestName, BookingGuestname, GuestEmailID, GuestGSTNo,BookingSource,IsActive, EntryBy, EntryDate)
VALUES (getdate(), @CheckInDate, @CheckOutDate, @HotelId,@Status,@BookingStatus,@GuestMobileNo, @GuestMobileNo, @GuestName, @BookingGuestName, @GuestEmailId, @gstNo,'Hotel',1, @EntryBy, getdate())

DECLARE @BookingId BIGINT =@@IDENTITY

UPDATE a SET NoOfBed=c.noofBed FROM #Roomdetails a
JOIN tbl_CategoryMaster b ON a.CategoryId =b.ID
JOIN tbl_BedMaster c ON b.bed_id = c.bed_id


UPDATE #Roomdetails 
SET Days = dbo.GetBookingDays(CheckOutDate,CheckInDate),
ExtraBed = dbo.GetExtraBed(NoofRooms,NoofAdults,NoOfBed),
DoubleOccupancy = dbo.GetDoubleOccupancy(NoofRooms,NoofAdults,NoOfBed)


UPDATE #Roomdetails 
SET RoomAmt = isnull(RoomCharge,0)*isnull(NoofRooms,0)*isnull(Days,0),
DoubleOccupancyAmt = isnull(DoubleOccupancyCharge,0)*isnull(DoubleOccupancy,0)*isnull(Days,0),
ExtraBedAmt = isnull(ExtraBedCharge,0)*isnull(ExtraBed,0)*isnull(Days,0)

UPDATE #Roomdetails 
SET TotalRoomAmt = isnull(RoomAmt,0)+isnull(DoubleOccupancyAmt,0)+isnull(ExtraBedAmt,0),
DiscountPer = isnull(@DiscountPer,0),
DisountAmount = (isnull(RoomAmt,0)+isnull(DoubleOccupancyAmt,0))*isnull(@DiscountPer,0)/100


UPDATE #Roomdetails 
SET GrossAmount = isnull(TotalRoomAmt,0)-isnull(DisountAmount,0),
GStPer = isnull(@GSTPer,0),
GSTNature = @GSTNature

UPDATE #Roomdetails 
SET TotalGST = dbo.GetGSTAmt(GrossAmount,GStPer,GSTNature)


UPDATE #Roomdetails 
SET CGST = TotalGST/2,
SGST= TotalGST/2,
TotalPayable =convert(NUMERIC,iif(GSTNature='Include',GrossAmount,(GrossAmount+TotalGST)) )

   DECLARE	@NetPayable DECIMAL(18, 2)=0;
   DECLARE	@DueAmount  DECIMAL(18, 2)=0;
   
SELECT @NetPayable=sum(TotalPayable) FROM #Roomdetails

SET @DueAmount = isnull(@NetPayable,0)-isnull(@PayAmount,0);

INSERT INTO dbo.B02_BookingRoomDetails (BookingId, HotelId, CategoryId, CheckInDate, CheckOutDate, Days, NoOfBed, NoofRooms, NoofAdults, NoofChilds, ExtraBed, DoubleOccupancy, RoomCharge, DoubleOccupancyCharge, ExtraBedCharge, RoomAmt, DoubleOccupancyAmt, ExtraBedamt, TotalRoomAmt, DiscountPer, DisountAmount, GrossAmount, GStPer, CGST, SGST, TotalGST, TotalPayable, GSTNature, BookingStatus,IsActive, EntryBy, EntryDate)
SELECT @BookingId, HotelId, CategoryId, CheckInDate, CheckOutDate, Days, NoOfBed, NoofRooms, NoofAdults, NoofChilds, ExtraBed, DoubleOccupancy, RoomCharge, DoubleOccupancyCharge, ExtraBedCharge, RoomAmt, DoubleOccupancyAmt, ExtraBedamt, TotalRoomAmt, DiscountPer, DisountAmount, GrossAmount, GStPer, CGST, SGST, TotalGST, TotalPayable, GSTNature, @BookingStatus,1, @EntryBy, getdate() FROM #Roomdetails


INSERT INTO dbo.B03_TransactionDetails (BookingId, PaymentSourse, NetPayable,PaidAmount,DueAmount, BillNo, PaymentMode, ResponseURL, TransactionID, TransactionDate, TID, TMode, mihpayid, hashResponce, NameOnCard, CardNo, requestKey, IsActive, EntryBy, EntryDate)
VALUES (@BookingId, 'Room', @NetPayable,@PayAmount,@DueAmount, @Billno, @PaymentMode, NULL, @Referencenumber, getdate(), NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, @EntryBy, getdate())

UPDATE a SET DocketeNo=@DocketeNo,NetPayable=@NetPayable,PaidAmount=@PayAmount,DueAmount=@DueAmount from B01_BookingDetails a WHERE BookingId=@BookingId


IF NOT EXISTS(SELECT 1 FROM login WHERE UserName=@GuestMobileNo )
BEGIN

INSERT INTO dbo.Login (UserName, Password, M_Role_Id,Created_By, Created_Date, Is_Active)
VALUES(@GuestMobileNo,123456,3,'-1',getdate(),1)

END 



SELECT '1' AS flag,'Your booking Save Successfully. You Dockete No. '+@DocketeNo AS msg
END 


COMMIT
END TRY
BEGIN CATCH

SELECT '0' AS flag,Error_message() AS msg,Error_line() AS errorline
END CATCH


END
GO
/****** Object:  StoredProcedure [dbo].[USP_InsertCheckIn]    Script Date: 04-Apr-2024 15:17:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[USP_InsertCheckIn]
(
@Action VARCHAR(32),
@BookingId BIGINT,
@HotelId VARCHAR(32),
@GuestName NVARCHAR(150),
@IdProof VARCHAR(50)=NULL,
@AdharNo VARCHAR(32)=NULL,
@GuestregNo VARCHAR(32)=NULL,
@GuestAddress NVARCHAR(400)=NULL,
@RoomJson NVARCHAR(max),
@EntryBy VARCHAR(150)=NULL
)
AS
BEGIN

IF @Action = '1'
BEGIN



CREATE TABLE #CheckIn
	(
	BookingId          BIGINT,
	HotelId            VARCHAR (32),
	CategoryId         INT,
	CheckInDate        DATETIME,
	CheckOutDate       DATETIME,
	UpdateStatus       VARCHAR,
	UpdateDate         DATETIME,
	NoOfDays           INT,
	RoomNo             VARCHAR (32),
	BookingStatus      VARCHAR (32),
	NoofAdults         INT,
	NoofChilds         INT,
	ExtraBed           INT,
	RoomChargesPerDay  DECIMAL (18, 2),
	DoubleOccupancyPer DECIMAL (18, 2),
	ExtraBedPricePer   DECIMAL (18, 2),
	TotalRoomCharge    DECIMAL (18, 2),
	DiscountPer        DECIMAL (18, 2),
	DisountAmount_Per  DECIMAL (18, 2),
	DisountAmount      DECIMAL (18, 2),
	GrossAmount        DECIMAL (18, 2),
	GStPer             DECIMAL (18, 2),
	GStAmount          DECIMAL (18, 2),
	CGST               DECIMAL (18, 2),
	SGST               DECIMAL (18, 2),
	TotalGST           DECIMAL (18, 2),
	TotalPayable       DECIMAL (18, 2),
	GSTNature          VARCHAR(32),
	NoOfBed INT,
	IsDoubleOccupancy INT
	)
	
INSERT INTO #CheckIn(CategoryId,RoomNo,NoofAdults)	
SELECT CategoryId,RoomNo,NoOfPerson
FROM OPENJSON(@RoomJson)
WITH (
    CategoryId INT '$.CategoryId',
    RoomNo NVARCHAR(50) '$.RoomNo',
    NoOfPerson INT '$.NoOfPerson'
)


UPDATE a SET
BookingId=b.BookingId, 
HotelId=b.HotelId,
CheckInDate=b.CheckInDate, 
CheckOutDate=b.CheckOutDate,
NoOfDays=b.Days,
BookingStatus='CheckIn',
NoOfBed=b.NoOfBed,
DiscountPer=b.DiscountPer,
ExtraBed = dbo.GetExtraBed(1,a.NoofAdults,b.NoOfBed),
IsDoubleOccupancy = dbo.GetDoubleOccupancy(1,a.NoofAdults,b.NoOfBed),
GStPer=b.GStPer,
GSTNature=b.GSTNature
FROM #CheckIn a
JOIN B02_BookingRoomDetails b ON a.CategoryId = b.CategoryId
WHERE b.BookingId=@BookingId



UPDATE a SET
RoomChargesPerDay=b.RoomCharge, 
DoubleOccupancyPer=iif(IsDoubleOccupancy=1,b.DoubleOccupancyCharge,0),
ExtraBedPricePer=iif(a.ExtraBed=1,b.ExtraBedCharge,0)
FROM #CheckIn a
JOIN B02_BookingRoomDetails b ON a.CategoryId = b.CategoryId
WHERE b.BookingId=@BookingId


UPDATE #CheckIn 
SET TotalRoomCharge = (isnull(RoomChargesPerDay,0)+isnull(DoubleOccupancyPer,0)+isnull(ExtraBedPricePer,0))*NoOfDays,
DisountAmount_Per = (isnull(RoomChargesPerDay,0)+isnull(DoubleOccupancyPer,0))*isnull(DiscountPer,0)/100


UPDATE #CheckIn 
SET DisountAmount = isnull(DisountAmount_Per,0)*isnull(NoOfDays,0)

UPDATE #CheckIn 
SET GrossAmount = isnull(TotalRoomCharge,0)-isnull(DisountAmount,0)


UPDATE #CheckIn 
SET TotalGST = dbo.GetGSTAmt(GrossAmount,GStPer,GSTNature)


UPDATE #CheckIn 
SET GStAmount=TotalGST/isnull(NoOfDays,0) WHERE isnull(NoOfDays,0)>0

UPDATE #CheckIn 
SET CGST = TotalGST/2,
SGST= TotalGST/2,
TotalPayable =convert(NUMERIC,iif(GSTNature='Include',GrossAmount,(GrossAmount+TotalGST)) )


INSERT INTO dbo.B04_ChickInDetails (BookingId, HotelId, CategoryId, CheckInDate, CheckOutDate, UpdateStatus, UpdateDate, NoOfDays, RoomNo, BookingStatus, NoofAdults, NoofChilds, ExtraBed, RoomChargesPerDay, DoubleOccupancyPer, ExtraBedPricePer, TotalRoomCharge, DiscountPer, DisountAmount_Per, DisountAmount, GrossAmount, GStPer, GStAmount, CGST, SGST, TotalGST, TotalPayable, GSTNature, IsActive, EntryBy, EntryDate)
SELECT  BookingId, HotelId, CategoryId, CheckInDate, CheckOutDate, UpdateStatus, UpdateDate, NoOfDays, RoomNo, BookingStatus, NoofAdults, NoofChilds, ExtraBed, RoomChargesPerDay, DoubleOccupancyPer, ExtraBedPricePer, TotalRoomCharge, DiscountPer, DisountAmount_Per, DisountAmount, GrossAmount, GStPer, GStAmount, CGST, SGST, TotalGST, TotalPayable, GSTNature, 1, @EntryBy,getdate() FROM #CheckIn

DECLARE @CheckedInRooms INT=0;
DECLARE @BookedRooms INT=0;

DECLARE	@NetPayable DECIMAL(18, 2)=0;
DECLARE	@DueAmount  DECIMAL(18, 2)=0;
DECLARE	@PaidAmount  DECIMAL(18, 2)=0;

SELECT @CheckedInRooms=count(DISTINCT RoomNo),@NetPayable=sum(TotalPayable) FROM B04_ChickInDetails WHERE BookingId = @BookingId 
SELECT @BookedRooms=sum(NoofRooms) FROM B02_BookingRoomDetails WHERE BookingId = @BookingId 

IF(@CheckedInRooms>=@BookedRooms)
BEGIN

SELECT @PaidAmount=sum(PaidAmount) FROM B03_TransactionDetails a WHERE BookingId = @BookingId AND PaymentSourse='Room'

SET @DueAmount = isnull(@NetPayable,0)-isnull(@PaidAmount,0);

UPDATE a SET BookingStatus='CheckIn',NetPayable=@NetPayable, PaidAmount=@PaidAmount, DueAmount=@DueAmount,
GuestName=isnull(@GuestName,GuestName),
GuestAddress=isnull(@GuestAddress,GuestName),
IdProof=isnull(@IdProof,IdProof),
IdProofNo=isnull(@AdharNo,IdProofNo),
GuestregNo=isnull(@GuestregNo,GuestregNo)
 FROM B01_BookingDetails a WHERE BookingId = @BookingId 


UPDATE a SET BookingStatus='CheckIn' FROM B02_BookingRoomDetails a WHERE BookingId = @BookingId 


UPDATE a SET CheckInDate1=getdate()  FROM B01_BookingDetails a WHERE BookingId = @BookingId AND BookingStatus='Booked'

END 



SELECT '1' AS flag,'Your booking Checked-In Successfully.' AS msg


END 




END
GO
/****** Object:  StoredProcedure [dbo].[USP_InsertHotelDTO]    Script Date: 04-Apr-2024 15:17:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[USP_InsertHotelDTO]  
(  
@Action varchar(8)=null,  
@HotelId varchar(32)=null,  
@HotelName nvarchar(500)=null,  
@HotalCodenew varchar(100)=null,  
@StateId int=null,  
@CityId int=null,  
@isOffline bit=0,  
@Address varchar(250)=null,  
@ContactNo varchar(50)=null,  
@Description varchar(max)=null,  
@EmailId varchar(50)=null,  
@ImageURL nvarchar(250)=null,  
@Landline varchar(100)=null  
)  
  
as  
 begin  
 if(@Action='1')  
  begin  
     
	SELECT DISTINCT HM.HotelId, HM.HotelName,isnull(HM.HotalCodenew,'') AS HotalCodenew, HM.Address, HM.ContactNo, HM.Landline, HM.EmailId, HM.Description, HM.ImageURL, HM.StateId, SM.StateName, HM.CityId, CM.CityName  
	FROM tbl_HotelMaster HM  
	INNER JOIN StateMaster SM ON HM.StateId = SM.StateId  
	INNER JOIN CityMaster CM ON HM.CityId = CM.ID  
  end  
  
  if(@Action='2')  
	begin   
		BEGIN TRY      
			BEGIN TRANSACTION trans    
				set @HotelId=(SELECT isnull(max(ID),0)+1 FROM tbl_HotelMaster )   
				insert into tbl_HotelMaster (HotelId,HotelName,HotalCodenew,ContactNo,Address,StateId,CityId,EmailId,Landline,ImageURL,Description) values	(@HotelId,@HotelName,@HotalCodenew, @ContactNo,@Address,@StateId,@CityId,@EmailId,@Landline,@ImageURL,@Description)	 
			COMMIT TRANSACTION trans 
				SELECT 1 Id ,'Record Successfully Saved !!!' msg    
		END TRY       
		BEGIN CATCH      
			--SELECT error_message()      
			SELECT 0 Id ,'Record not Saved !!!' msg    
			ROLLBACK TRANSACTION trans      
		END CATCH 
	end
	if(@Action='3')
		begin
			Select HM.HotelId, HM.HotelName,isnull(HM.HotalCodenew,'') AS HotalCodenew, HM.Address, HM.ContactNo, HM.Landline, HM.EmailId, HM.Description, HM.ImageURL, HM.StateId, SM.StateName, HM.CityId, CM.CityName  
	        FROM tbl_HotelMaster HM  
	        INNER JOIN StateMaster SM ON HM.StateId = SM.StateId  
	        INNER JOIN CityMaster CM ON HM.CityId = CM.ID  
	        where HotelId=@HotelId
		end
  if(@Action='4')  
	begin   
		BEGIN TRY      
			BEGIN TRANSACTION trans    
				--set @HotelId=(SELECT isnull(max(ID),0)+1 FROM tbl_HotelMaster )   
				Update tbl_HotelMaster set  HotelName=@HotelName, HotalCodenew=@HotalCodenew, ContactNo=@ContactNo, Address=@Address, StateId=@StateId, CityId=@CityId, EmailId=@EmailId, Landline=@Landline, ImageURL=@ImageURL, Description=@Description 
				where HotelId=@HotelId
			COMMIT TRANSACTION trans 
				SELECT 1 Id ,'Record Updated Successfully !!!' msg    
		END TRY       
		BEGIN CATCH      
			--SELECT error_message()      
			SELECT 0 Id ,'Record not Updated !!!' msg    
			ROLLBACK TRANSACTION trans      
		END CATCH 
	end
  end
GO
/****** Object:  StoredProcedure [dbo].[USP_RateMaster]    Script Date: 04-Apr-2024 15:17:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[USP_RateMaster]
@Action VARCHAR(10)=NULL,
@RateID  int =null,   
@HotelId  VARCHAR (32) =null,
@CategoryId   int =null, 
@PricePerDay DECIMAL(18,2)=NULL,
@PriceDifference DECIMAL(18,2)=NULL,
@ExtraBadPriceMode VARCHAR(20)=NULL,
@ExtraBedPercentage DECIMAL(18,2)=NULL,
@RateStartDate DateTime=null ,
@RateEndDate DateTime=null ,
@IsActive  bit=0, 
@EntryBy  VARCHAR(50)=null,   
@EntryDate   DateTime=null 

AS

BEGIN
	IF(@Action ='1')
	BEGIN
  		SELECT a.RateID, a.HotelId, b.HotelName, a.CategoryId, c.Category, a.PricePerDay, a.PriceDifference, a.ExtraBedPercentage,
  	   format(a.RateStartDate,'dd-MMM-yyyy')RateStartDate, format(a.RateEndDate,'dd-MMM-yyyy')RateEndDate, 
  	   format(a.EntryDate,'dd-MMM-yyyy')EntryDate,a.ExtraBadPriceMode
  		FROM RateMaster a 	
		JOIN tbl_HotelMaster b  ON b.HotelId = a.hotelid
		JOIN tbl_CategoryMaster c  ON c.id = a.CategoryId		
	END
	
	if(@Action='2')  
	begin   
		BEGIN TRY      
			BEGIN TRANSACTION trans   		
			SET @IsActive=1;		   
		  		INSERT INTO RateMaster(HotelId,CategoryId,PricePerDay,PriceDifference,ExtraBedPercentage,RateStartDate
		  		,RateEndDate,IsActive,EntryBy,EntryDate,ExtraBadPriceMode) VALUES(@HotelId,@CategoryId,@PricePerDay,@PriceDifference,
		  		@ExtraBedPercentage,@RateStartDate,@RateEndDate,@IsActive,@EntryBy,GetDate(),@ExtraBadPriceMode)
			COMMIT TRANSACTION trans 
				SELECT 1 Id ,'Record Successfully Saved !!!' msg    
		END TRY       
		BEGIN CATCH      
			--SELECT error_message()      
			SELECT 0 Id ,error_message() msg    
			ROLLBACK TRANSACTION trans      
		END CATCH 
	END
	
    IF(@Action ='3')
	BEGIN
		SELECT a.RateID, a.HotelId, b.HotelName, a.CategoryId, c.Category, a.PricePerDay, a.PriceDifference, 
		a.ExtraBedPercentage,format( a.RateStartDate,'yyyy-MM-dd') as RateStartDate,a.ExtraBadPriceMode,
		format( a.RateEndDate,'yyyy-MM-dd') as RateEndDate , format(a.EntryDate,'yyyy-MM-dd')EntryDate,
  		a.EntryBy
  		FROM RateMaster a 	
		JOIN tbl_HotelMaster b  ON b.HotelId = a.hotelid
		JOIN tbl_CategoryMaster c  ON c.id = a.CategoryId
		
		WHERE a.RateID=@RateID
	  
	END	
   
	if(@Action='4')  
	begin   
		BEGIN TRY      
			BEGIN TRANSACTION trans   		
			SET @IsActive=1;
		   
		  		UPDATE RateMaster SET HotelId=@HotelId, CategoryId=@CategoryId, PricePerDay=@PricePerDay,
		  		PriceDifference=@PriceDifference,ExtraBedPercentage=@ExtraBedPercentage,RateStartDate=@RateStartDate,
		  		RateEndDate=@RateEndDate,IsActive=@IsActive,EntryBy=@EntryBy, EntryDate=Getdate(),ExtraBadPriceMode=@ExtraBadPriceMode
		  		
		  		
		  		WHERE RateID=@RateID
			COMMIT TRANSACTION trans 
				SELECT 1 Id ,'Record Update Successfully !!!' msg    
		END TRY       
		BEGIN CATCH      
			--SELECT error_message()      
			SELECT 0 Id ,error_message()  msg    
			ROLLBACK TRANSACTION trans      
		END CATCH 
	END
END
GO
/****** Object:  StoredProcedure [dbo].[USP_RoomImagesMaster]    Script Date: 04-Apr-2024 15:17:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[USP_RoomImagesMaster]
(
@Action varchar(10),
@Id int=0,
@ImagePath nvarchar(max) = null,
@CategoryId int=0,
@HotelId nvarchar(50)=null,
@ImageExt nvarchar(50)=null
)
as
Begin
	if(@Action='1')
		BEGIN
			SELECT RI.Id, RI.HotelId, RI.ImagePath, RI.CategoryId, CM.Category, RI.ImageExt 
			,CONVERT(VARCHAR(10), RI.EntryDate, 105) AS EntryDate
		     FROM tbl_RoomImages RI			
			LEFT JOIN tbl_CategoryMaster CM ON RI.CategoryId= CM.Id
			WHERE RI.hotelId=@HotelId
		END

	if(@Action='2')
    BEGIN
    BEGIN TRY    
		BEGIN TRANSACTION trans  
		insert into tbl_RoomImages(ImagePath, EntryDate, CategoryId,HotelId, ImageExt)
		values(@ImagePath,GETDATE(), @CategoryId, @HotelId,@ImageExt) 
	COMMIT TRANSACTION trans    
        
     SELECT 1 Id ,'Record Successfully Saved !!!' msg  
	  
    END TRY     
    BEGIN CATCH    
     --SELECT error_message()    
	   SELECT 0 Id ,'Record not Saved !!!' msg  
     ROLLBACK TRANSACTION trans    
    END CATCH    
	 
  END
end
GO
/****** Object:  StoredProcedure [dbo].[USP_UnitHome]    Script Date: 04-Apr-2024 15:17:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- *** SqlDbx Personal Edition ***
-- !!! Not licensed for commercial use beyound 90 days evaluation period !!!
-- For version limitations please check http://www.sqldbx.com/personal_edition.htm
-- Number of queries executed: 218, number of rows retrieved: 942059

CREATE PROCEDURE [dbo].[USP_UnitHome] -- USP_CategoryWiseRoomDetails '1','HTL82734',null,'2024-02-15','2024-02-17'
(
@Action VARCHAR(16),
@BookingId BIGINT=NULL,
@HotelId            VARCHAR (32)=NULL,
@CategoryId         INT =NULL,
@CheckInDate        date=NULL,
@CheckOutDate       date=NULL

)
AS
BEGIN
SET NOCOUNT ON;


IF @Action = 'checkIn'
BEGIN

SELECT BookingId,DocketeNo,GuestName,GuestMobileNo,
NoOfRoom =isnull((SELECT sum(NoofRooms) FROM B02_BookingRoomDetails z WHERE z.BookingId=a.BookingId),0),
format(CheckInDate,'dd-MMM-yyyy')CheckInDate,
format(CheckOutDate,'dd-MMM-yyyy')CheckOutDate
FROM B01_BookingDetails a
WHERE a.HotelId=@HotelId 
AND CheckInDate <=convert(DATE,getdate()) 
AND Status='Success' 
AND BookingStatus='Booked' 
AND IsActive=1
 

END 
ELSE IF @Action = 'checkedIn'
BEGIN

SELECT BookingId,DocketeNo,GuestName,GuestMobileNo,
format(CheckInDate,'dd-MMM-yyyy')CheckInDate,
format(CheckOutDate,'dd-MMM-yyyy')CheckOutDate,
NoOfRoom =isnull((SELECT count(1) FROM B04_ChickInDetails z WHERE z.BookingId=a.BookingId AND z.NoOfDays>=1),0),
Rooms =isnull((SELECT string_agg(RoomNo,',') FROM B04_ChickInDetails z WHERE z.BookingId=a.BookingId AND z.NoOfDays>=1),0)
FROM B01_BookingDetails a
WHERE a.HotelId=@HotelId 
AND Status='Success' 
AND BookingStatus='CheckIn' 
AND IsActive=1
 

END 
ELSE IF @Action = 'checkOut'
BEGIN

SELECT BookingId,DocketeNo,GuestName,GuestMobileNo,
format(CheckInDate,'dd-MMM-yyyy')CheckInDate,
format(CheckOutDate,'dd-MMM-yyyy')CheckOutDate,
NoOfRoom =isnull((SELECT count(1) FROM B04_ChickInDetails z WHERE z.BookingId=a.BookingId AND z.NoOfDays>=1),0),
Rooms =isnull((SELECT string_agg(RoomNo,',') FROM B04_ChickInDetails z WHERE z.BookingId=a.BookingId AND z.NoOfDays>=1),0),
DueAmt=DueAmount
FROM B01_BookingDetails a
WHERE a.HotelId=@HotelId 
AND a.CheckOutDate = convert(DATE,getdate())
AND Status='Success' 
AND BookingStatus='checkOut' 
AND IsActive=1
 

END 
ELSE IF @Action = 'CheckIn_1'
BEGIN

SELECT a.BookingId,a.HotelId,a.CategoryId,b.Category,NoofRooms,NoOfBed,NoofAdults,ExtraBed, DoubleOccupancy,
RoomCharge, DoubleOccupancyCharge, ExtraBedCharge, RoomAmt, DoubleOccupancyAmt, ExtraBedamt, TotalRoomAmt, DiscountPer, DisountAmount, GrossAmount, GStPer, CGST, SGST, TotalGST, TotalPayable, GSTNature,
a1.PaidAmount,a1.DueAmount,
format(a.CheckInDate,'dd-MMM-yyyy')CheckInDate,
format(a.CheckOutDate,'dd-MMM-yyyy')CheckOutDate
FROM B02_BookingRoomDetails a
JOIN B01_BookingDetails a1 ON a1.BookingId = a.BookingId
JOIN tbl_CategoryMaster b ON a.CategoryId = b.ID
WHERE a.BookingId=@BookingId 
AND a.BookingStatus='Booked'
AND a.IsActive=1
 

END 
ELSE IF @Action = 'CheckIn_2'
BEGIN

CREATE TABLE #CheckIn_1
	(
	HotelId VARCHAR(32),
	NoOfBed INT,
	CategoryId INT,
	Category NVARCHAR (500),
	NoofRooms INT,
	NoofAdults INT,
	ExtraBed INT,
	DoubleOccupancy INT,
	RoomNo VARCHAR (32),
	IsCheckIn INT
	)

INSERT INTO #CheckIn_1(HotelId,NoOfBed,CategoryId, Category, NoofRooms, NoofAdults, ExtraBed, DoubleOccupancy, RoomNo)

SELECT a.HotelId,a.NoOfBed,a.CategoryId,c.Category,a.NoofRooms,a.NoofAdults,a.ExtraBed,a.DoubleOccupancy,
b.RoomNo
 FROM B02_BookingRoomDetails a
JOIN tbl_RoomDetail b ON a.CategoryId=b.CategoryId AND a.HotelId=b.HotelId
JOIN tbl_CategoryMaster c ON a.CategoryId = c.ID
WHERE a.BookingId=@BookingId
AND a.IsActive=1 AND b.IsActive=1

UPDATE a SET IsCheckIn=iif(b.RoomNo IS NOT NULL,1,0) FROM #CheckIn_1 a
LEFT JOIN B04_ChickInDetails b ON a.HotelId=b.HotelId
AND a.CategoryId=b.CategoryId AND a.RoomNo=b.RoomNo



UPDATE a SET 
NoofRooms = isnull(a.NoofRooms,0)-isnull(b.CheckedInRooms,0),
NoofAdults= isnull(a.NoofAdults,0)-isnull(b.NoofAdults,0)
FROM #CheckIn_1 a
LEFT JOIN VW_ChickedInRooms_Booking_And_CategoryWise b ON 
a.CategoryId=b.CategoryId AND b.BookingId=@BookingId







DELETE FROM #CheckIn_1 WHERE NoofRooms=0

SELECT * FROM #CheckIn_1

END 
ELSE IF @Action = 'ManageBooking_1'
BEGIN

SELECT a.BookingId,a.HotelId,a.CategoryId,b.Category,NoofRooms,NoOfBed,NoofAdults,ExtraBed, DoubleOccupancy,
RoomCharge, DoubleOccupancyCharge, ExtraBedCharge, RoomAmt, DoubleOccupancyAmt, ExtraBedamt, TotalRoomAmt, DiscountPer, DisountAmount, GrossAmount, GStPer, CGST, SGST, TotalGST, TotalPayable, GSTNature,
a1.PaidAmount,a1.DueAmount,
format(a.CheckInDate,'dd-MMM-yyyy')CheckInDate,
format(a.CheckOutDate,'dd-MMM-yyyy')CheckOutDate
FROM B02_BookingRoomDetails a
JOIN B01_BookingDetails a1 ON a1.BookingId = a.BookingId
JOIN tbl_CategoryMaster b ON a.CategoryId = b.ID
WHERE a.BookingId=@BookingId 
--AND a.BookingStatus='CheckIn'
AND a.IsActive=1
 

END 


END
GO
