﻿// <auto-generated> This file has been auto generated by EF Core Power Tools. </auto-generated>
#nullable disable
using System;
using System.Collections.Generic;

namespace Hotel.data;

public partial class StateMaster
{
    public int StateId { get; set; }

    public string StateName { get; set; }

    public string StateCode { get; set; }

    public DateTime? EntryDate { get; set; }

    public int? DeleteStatus { get; set; }
}