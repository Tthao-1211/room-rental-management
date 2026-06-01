namespace Project_65133295.Models
{
    using System;
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;
    using System.Data.Entity.Spatial;

    public partial class RoomUtilities
    {
        [Key]
        public int RoomUtilityID { get; set; }

        [Index("UQ_RoomUtility", 1, IsUnique = true)]
        public int RoomID { get; set; }

        [Index("UQ_RoomUtility", 2, IsUnique = true)]
        public int UtilityID { get; set; }

        public virtual Room Rooms { get; set; }

        public virtual Utilities Utilities { get; set; }
    }
}
