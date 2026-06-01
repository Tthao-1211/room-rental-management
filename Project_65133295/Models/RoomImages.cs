namespace Project_65133295.Models
{
    using System;
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;
    using System.Data.Entity.Spatial;

    public partial class RoomImages
    {
        [Key]
        public int ImageID { get; set; }

        public int RoomID { get; set; }

        [Required]
        [StringLength(500)]
        public string ImageUrl { get; set; }

        public int DisplayOrder { get; set; } = 1;

        public bool IsMainImage { get; set; } = false;

        public DateTime UploadedAt { get; set; } = DateTime.Now;

        public virtual Room Rooms { get; set; }
    }
}
