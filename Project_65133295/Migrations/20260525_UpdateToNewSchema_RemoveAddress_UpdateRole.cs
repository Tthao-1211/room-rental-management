namespace Project_65133295.Migrations
{
    using System;
    using System.Data.Entity.Migrations;

    public partial class UpdateToNewSchema_RemoveAddress_UpdateRole : DbMigration
    {
        public override void Up()
        {
            // Drop foreign keys and indexes referencing Addresses
            DropForeignKey("dbo.Rooms", "AddressID", "dbo.Addresses");
            DropIndex("dbo.Rooms", new[] { "AddressID" });

            DropForeignKey("dbo.Users", "AddressID", "dbo.Addresses");
            DropIndex("dbo.Users", new[] { "AddressID" });

            // Remove AddressID columns
            DropColumn("dbo.Rooms", "AddressID");
            DropColumn("dbo.Users", "AddressID");

            // Drop Addresses table
            DropTable("dbo.Addresses");

            // Change Users.Role from bit/bool to tinyint/byte
            AlterColumn("dbo.Users", "Role", c => c.Byte(nullable: false));
        }

        public override void Down()
        {
            // Recreate Addresses table
            CreateTable(
                "dbo.Addresses",
                c => new
                    {
                        AddressID = c.Int(nullable: false, identity: true),
                        Street = c.String(nullable: false, maxLength: 255),
                        Ward = c.String(nullable: false, maxLength: 100),
                        District = c.String(nullable: false, maxLength: 100),
                        City = c.String(nullable: false, maxLength: 100),
                        Province = c.String(maxLength: 100),
                        ZipCode = c.String(maxLength: 20),
                        Latitude = c.Decimal(precision: 9, scale: 6),
                        Longitude = c.Decimal(precision: 9, scale: 6),
                        CreatedAt = c.DateTime(),
                    })
                .PrimaryKey(t => t.AddressID);

            // Re-add AddressID columns
            AddColumn("dbo.Rooms", "AddressID", c => c.Int(nullable: false));
            AddColumn("dbo.Users", "AddressID", c => c.Int());

            // Recreate indexes and foreign keys
            CreateIndex("dbo.Users", "AddressID");
            CreateIndex("dbo.Rooms", "AddressID");
            AddForeignKey("dbo.Users", "AddressID", "dbo.Addresses", "AddressID");
            AddForeignKey("dbo.Rooms", "AddressID", "dbo.Addresses", "AddressID", cascadeDelete: true);

            // Revert Users.Role to boolean
            AlterColumn("dbo.Users", "Role", c => c.Boolean(nullable: false));
        }
    }
}
