using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using System.Data.Entity;
using System.IO;
using Project_65133295.Models;
using Project_65133295.Areas.Admin.Data;
using System.Globalization;
using Project_65133295.Controllers;
using System.Web.Routing;
using System.Web.Security;

namespace Project_65133295.Areas.Admin.Controllers
{
    [CustomAuthorize(Role = "Admin,NhanVien")]
    public class Admin_65133295Controller : Controller
    {
        // GET: Admin/Admin_65133295

        private DbContext_65133295 db = new DbContext_65133295();

        protected override void OnActionExecuting(ActionExecutingContext filterContext)
        {
            if (Session["UserID"] != null)
            {
                int userId = Convert.ToInt32(Session["UserID"]);
                ViewBag.NotificationCount = db.Notifications.Count(n => n.RecipientID == userId && n.IsRead != true);
            }
            base.OnActionExecuting(filterContext);
        }

        [ChildActionOnly]
        public ActionResult RenderAdminNotificationBadge()
        {
            if (Session["UserID"] == null) return Content("");
            int userId = Convert.ToInt32(Session["UserID"]);
            int count = db.Notifications.Count(n => n.RecipientID == userId && n.IsRead != true);
            return PartialView("_AdminNotificationBadge", count);
        }

        // View admin notifications list
        public ActionResult Notifications()
        {
            if (Session["UserID"] == null) return RedirectToAction("Login", "Guest_65133295", new { area = "" });
            int userId = (int)Session["UserID"];

            var notifications = db.Notifications
                .Where(n => n.RecipientID == userId)
                .OrderByDescending(n => n.CreatedAt)
                .ToList();

            return View(notifications);
        }

        // POST: Mark notification as read
        [HttpPost]
        public JsonResult MarkAsRead(int id)
        {
            try
            {
                var notification = db.Notifications.Find(id);
                if (notification == null) return Json(new { success = false });

                notification.IsRead = true;
                notification.ReadAt = DateTime.Now;
                db.SaveChanges();

                return Json(new { success = true });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = ex.Message });
            }
        }

        // POST: Clear all notifications (mark all as read)
        [HttpPost]
        public JsonResult ClearAllNotifications()
        {
            try
            {
                if (Session["UserID"] == null) return Json(new { success = false, message = "Not logged in." });
                int userId = (int)Session["UserID"];

                var unreadNotifications = db.Notifications
                    .Where(n => n.RecipientID == userId && n.IsRead != true)
                    .ToList();

                foreach (var notif in unreadNotifications)
                {
                    notif.IsRead = true;
                    notif.ReadAt = DateTime.Now;
                }

                db.SaveChanges();

                return Json(new { success = true, count = unreadNotifications.Count });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = ex.Message });
            }
        }

        // POST: Delete a notification
        [HttpPost]
        public JsonResult DeleteNotification(int id)
        {
            try
            {
                var notification = db.Notifications.Find(id);
                if (notification == null) return Json(new { success = false });

                db.Notifications.Remove(notification);
                db.SaveChanges();

                return Json(new { success = true });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = ex.Message });
            }
        }

        // POST: Permanently delete all notifications
        [HttpPost]
        public JsonResult DeleteAllNotifications()
        {
            try
            {
                if (Session["UserID"] == null) return Json(new { success = false, message = "Not logged in." });
                int userId = (int)Session["UserID"];

                var notifications = db.Notifications.Where(n => n.RecipientID == userId).ToList();
                db.Notifications.RemoveRange(notifications);
                db.SaveChanges();

                return Json(new { success = true, count = notifications.Count });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = ex.Message });
            }
        }

        // View reports (revenue, occupancy rate)
        public ActionResult Index()
        {
            var model = new AdminDashboardViewModel_65133295();

            // 1. Basic Stats
            model.TotalRevenue = db.Payments.Where(p => p.PaymentStatus == "Paid")
                                          .Select(p => (decimal?)p.Amount).Sum() ?? 0;
            model.TotalRooms = db.Rooms.Count();
            model.OccupiedRooms = db.Rooms.Count(r => r.StatusID != 1); // Assuming 1 is Available
            model.PendingBookings = db.Bookings.Count(b => b.BookingStatus == "Pending");
            model.TotalUsers = db.Users.Count(u => u.Role != Project_65133295.Models.UserRole.Admin);

            // 2. Monthly Revenue (Last 6 months)
            var sixMonthsAgo = DateTime.Now.AddMonths(-6);
            var revenueData = db.Payments
                .Where(p => p.PaymentStatus == "Paid" && p.PaidDate >= sixMonthsAgo)
                .GroupBy(p => new { Month = p.PaidDate.Value.Month, Year = p.PaidDate.Value.Year })
                .Select(g => new { Month = g.Key.Month, Year = g.Key.Year, Total = g.Sum(p => p.Amount) })
                .ToList();

            model.MonthlyRevenue = new List<MonthlyRevenue_65133295>();
            for (int i = 5; i >= 0; i--)
            {
                var targetDate = DateTime.Now.AddMonths(-i);
                var match = revenueData.FirstOrDefault(d => d.Month == targetDate.Month && d.Year == targetDate.Year);
                model.MonthlyRevenue.Add(new MonthlyRevenue_65133295
                {
                    Month = targetDate.ToString("MM/yyyy"),
                    Revenue = match?.Total ?? 0
                });
            }

            // 3. Room Status Breakdown
            model.RoomStatusBreakdown = db.Rooms
                .GroupBy(r => r.RoomStatuses.StatusName)
                .Select(g => new RoomStatusCount_65133295
                {
                    StatusName = g.Key,
                    Count = g.Count()
                }).ToList();

            // 4. Recent Activities
            model.RecentActivities = db.ActivityLogs
                .OrderByDescending(a => a.CreatedAt)
                .Take(5)
                .Select(a => new RecentActivity_65133295
                {
                    Date = a.CreatedAt ?? DateTime.Now,
                    User = a.Users.LastName + " " + a.Users.FirstName,
                    Action = a.ActionType,
                    Description = a.Description
                }).ToList();

            ViewBag.PageTitle = "Dashboard";
            ViewBag.PageDescription = "Activity overview and revenue reports";

            return View(model);
        }

        // Manage rooms (add, edit, delete, change status, upload images, add utilities)
        public ActionResult ManageRooms()
        {
            var rooms = db.Rooms
                .Include(r => r.RoomStatuses)
                .Include(r => r.RoomImages)
                .OrderByDescending(r => r.CreatedAt)
                .ToList();

            ViewBag.PageTitle = "Manage Rooms";
            ViewBag.PageDescription = "List of all rental rooms in the system";

            return View(rooms);
        }

        // GET: Admin/Admin_65133295/CreateRoom
        public ActionResult CreateRoom()
        {
            var model = new RoomFormViewModel_65133295
            {
                Statuses = GetTranslatedStatuses(),
                Utilities = db.Utilities.Select(u => new UtilitySelection_65133295
                {
                    UtilityID = u.UtilityID,
                    UtilityName = u.UtilityName,
                    IsSelected = false
                }).ToList(),
                PriceUnit = "VND/month",
                ExistingImages = new List<RoomImageViewModel_65133295>()
            };

            ViewBag.PageTitle = "Add New Room";
            ViewBag.PageDescription = "Fill in detailed information to add a new rental room";

            return View(model);
        }

        // POST: Admin/Admin_65133295/CreateRoom
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult CreateRoom(RoomFormViewModel_65133295 model)
        {
            if (ModelState.IsValid)
            {
                using (var transaction = db.Database.BeginTransaction())
                {
                    try
                    {
                        // Get Admin ID securely
                        int? sessionUserId = GetCurrentAdminID();
                        if (sessionUserId == null)
                        {
                            ModelState.AddModelError("", "Session expired. Please log in again.");
                            throw new Exception("Session expired");
                        }

                        // 1. Create Room
                        var room = new Room
                        {
                            RoomNumber = model.RoomNumber,
                            Title = model.Title,
                            Description = model.Description,
                            Area = model.Area,
                            Price = model.Price,
                            PriceUnit = model.PriceUnit ?? "VND/month",
                            MaxOccupancy = model.MaxOccupancy,
                            StatusID = model.StatusID,
                            AdminID = sessionUserId.Value,
                            CreatedAt = DateTime.Now,
                            UpdatedAt = DateTime.Now
                        };
                        db.Rooms.Add(room);
                        db.SaveChanges();

                        // 2. Add Utilities
                        if (model.Utilities != null)
                        {
                            foreach (var util in model.Utilities.Where(u => u.IsSelected))
                            {
                                db.RoomUtilities.Add(new RoomUtilities
                                {
                                    RoomID = room.RoomID,
                                    UtilityID = util.UtilityID
                                });
                            }
                        }

                        // 3. Handle Image Uploads
                        if (model.NewImages != null && model.NewImages.Any())
                        {
                            string uploadDir = Server.MapPath("~/public/rooms/");
                            bool first = true;

                            // Robust index calculation: find max index in current files to avoid overwrites
                            int imgIndex = 1;
                            string safeRoomNo = room.RoomNumber.Trim().Replace("/", "-").Replace("\\", "-").Replace(" ", "-");

                            foreach (var file in model.NewImages)
                            {
                                if (file != null && file.ContentLength > 0)
                                {
                                    string ext = Path.GetExtension(file.FileName);
                                    string fileName = $"{safeRoomNo}_{imgIndex}{ext}";
                                    string path = Path.Combine(uploadDir, fileName);

                                    // Security: ensures we don't overwrite if index 1 already exists somehow (e.g. manual upload)
                                    while (System.IO.File.Exists(path))
                                    {
                                        imgIndex++;
                                        fileName = $"{safeRoomNo}_{imgIndex}{ext}";
                                        path = Path.Combine(uploadDir, fileName);
                                    }

                                    file.SaveAs(path);

                                    db.RoomImages.Add(new RoomImages
                                    {
                                        RoomID = room.RoomID,
                                        ImageUrl = "/public/rooms/" + fileName,
                                        IsMainImage = first,
                                        UploadedAt = DateTime.Now,
                                        DisplayOrder = imgIndex
                                    });
                                    imgIndex++;
                                    first = false;
                                }
                            }
                        }

                        db.SaveChanges();

                        // 4. Log Activity
                        LogActivity("Create", "Rooms", room.RoomID, null,
                            Newtonsoft.Json.JsonConvert.SerializeObject(new { room.RoomNumber, room.Title, room.Price }),
                            $"Thêm mới phòng {room.RoomNumber}");

                        transaction.Commit();
                        TempData["Message"] = "Room added successfully!";
                        return RedirectToAction("ManageRooms");
                    }
                    catch (System.Data.Entity.Validation.DbEntityValidationException ex)
                    {
                        transaction.Rollback();
                        var errorMessages = ex.EntityValidationErrors
                                .SelectMany(x => x.ValidationErrors)
                                .Select(x => x.ErrorMessage);
                        var fullErrorMessage = string.Join("; ", errorMessages);
                        ModelState.AddModelError("", "Lỗi dữ liệu: " + fullErrorMessage);
                    }
                    catch (System.Data.Entity.Infrastructure.DbUpdateException ex)
                    {
                        transaction.Rollback();
                        var innerMessage = ex.InnerException?.InnerException?.Message ?? ex.InnerException?.Message ?? ex.Message;
                        ModelState.AddModelError("", "Lỗi cập nhật CSDL: " + innerMessage);
                    }
                    catch (Exception ex)
                    {
                        transaction.Rollback();
                        ModelState.AddModelError("", "Có lỗi xảy ra: " + ex.Message);
                    }
                }
            }

            // If we got here, something failed, redisplay form
            ViewBag.PageTitle = "Thêm Phòng Mới";
            ViewBag.PageDescription = "Fill in detailed information to add a new rental room";

            model.Statuses = GetTranslatedStatuses();
            model.ExistingImages = new List<RoomImageViewModel_65133295>(); // Always safe

            // Sync Utilities to ensure Names are present for rendering
            var allUtils = db.Utilities.ToList();
            if (model.Utilities == null || !model.Utilities.Any())
            {
                model.Utilities = allUtils.Select(u => new UtilitySelection_65133295
                {
                    UtilityID = u.UtilityID,
                    UtilityName = u.UtilityName,
                    IsSelected = false
                }).ToList();
            }
            else
            {
                // Fill in the names for the utilities we have
                foreach (var util in model.Utilities)
                {
                    var dbUtil = allUtils.FirstOrDefault(u => u.UtilityID == util.UtilityID);
                    if (dbUtil != null) util.UtilityName = dbUtil.UtilityName;
                }
            }
            return View(model);
        }

        // GET: Admin/Admin_65133295/EditRoom/5
        public ActionResult EditRoom(int id)
        {
            var room = db.Rooms
                .Include(r => r.RoomUtilities)
                .Include(r => r.RoomImages)
                .FirstOrDefault(r => r.RoomID == id);

            if (room == null) return HttpNotFound();

            // Pull everything into memory first to avoid EF translation issues
            var selectedUtilityIds = room.RoomUtilities.Select(ru => (int)ru.UtilityID).ToList();
            var allUtilities = db.Utilities.ToList();
            var allStatuses = GetTranslatedStatuses();
            var existingImages = room.RoomImages.ToList();

            var model = new RoomFormViewModel_65133295
            {
                RoomID = room.RoomID,
                RoomNumber = room.RoomNumber,
                Title = room.Title,
                Description = room.Description,
                Area = room.Area,
                Price = room.Price,
                PriceUnit = room.PriceUnit,
                MaxOccupancy = room.MaxOccupancy,
                StatusID = room.StatusID,
                Statuses = allStatuses,
                Utilities = allUtilities.Select(u => new UtilitySelection_65133295
                {
                    UtilityID = u.UtilityID,
                    UtilityName = u.UtilityName,
                    IsSelected = selectedUtilityIds.Contains(u.UtilityID)
                }).ToList(),
                ExistingImages = existingImages.Select(i => new RoomImageViewModel_65133295
                {
                    ImageID = i.ImageID,
                    ImageURL = i.ImageUrl,
                    IsPrimary = i.IsMainImage ?? false
                }).ToList()
            };

            ViewBag.PageTitle = "Chỉnh Sửa Phòng";
            ViewBag.PageDescription = "Cập nhật thông tin phòng " + room.RoomNumber;

            return View(model);
        }

        // POST: Admin/Admin_65133295/EditRoom
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult EditRoom(RoomFormViewModel_65133295 model)
        {
            if (ModelState.IsValid)
            {
                using (var transaction = db.Database.BeginTransaction())
                {
                    try
                    {
                        // Robust way to get Admin ID
                        int? sessionUserId = GetCurrentAdminID();
                        if (sessionUserId == null)
                        {
                            ModelState.AddModelError("", "Your session has expired. Please login again.");
                            throw new Exception("Session expired");
                        }

                        var room = db.Rooms
                            .Include(r => r.RoomUtilities)
                            .Include(r => r.RoomImages)
                            .FirstOrDefault(r => r.RoomID == model.RoomID);

                        if (room == null)
                        {
                            ModelState.AddModelError("", "Room not found.");
                            throw new Exception("Room not found");
                        }

                        // Store old values for logging
                        var oldValues = Newtonsoft.Json.JsonConvert.SerializeObject(new { room.Price, room.StatusID, room.Title });

                        // 1. Update Room Basic Info
                        // PER USER: Cannot change room number during edit
                        room.Title = model.Title;
                        room.Description = model.Description;
                        room.Area = model.Area;
                        room.Price = model.Price;
                        room.PriceUnit = model.PriceUnit ?? "VND/month";
                        // AddressID removed from schema; no assignment here.
                        room.MaxOccupancy = model.MaxOccupancy;
                        room.StatusID = model.StatusID;
                        room.UpdatedAt = DateTime.Now;

                        // 2. Sync Utilities
                        var currentUtils = db.RoomUtilities.Where(ru => ru.RoomID == room.RoomID);
                        db.RoomUtilities.RemoveRange(currentUtils);
                        if (model.Utilities != null)
                        {
                            foreach (var util in model.Utilities.Where(u => u.IsSelected))
                            {
                                db.RoomUtilities.Add(new RoomUtilities { RoomID = room.RoomID, UtilityID = util.UtilityID });
                            }
                        }

                        // 3. Handle image removals
                        if (model.ExistingImages != null)
                        {
                            foreach (var img in model.ExistingImages.Where(i => i.IsDeleted))
                            {
                                var dbImg = db.RoomImages.Find(img.ImageID);
                                if (dbImg != null)
                                {
                                    // Optional: delete file from disk if you want
                                    db.RoomImages.Remove(dbImg);
                                }
                            }
                        }

                        // 4. Handle New Images
                        if (model.NewImages != null && model.NewImages.Any())
                        {
                            string uploadDir = Server.MapPath("~/public/rooms/");
                            string safeRoomNo = room.RoomNumber.Trim().Replace("/", "-").Replace("\\", "-").Replace(" ", "-");

                            // Robust indexing: find the highest index currently in use for this room
                            int maxIndex = 0;
                            var currentImages = db.RoomImages.Where(ri => ri.RoomID == room.RoomID).ToList();
                            foreach (var ci in currentImages)
                            {
                                string url = ci.ImageUrl;
                                // Try to extract index from "[RoomNo]_[Index].[ext]"
                                string fileNameWithoutExt = Path.GetFileNameWithoutExtension(url);
                                string[] parts = fileNameWithoutExt.Split('_');
                                if (parts.Length > 1 && int.TryParse(parts[parts.Length - 1], out int idx))
                                {
                                    if (idx > maxIndex) maxIndex = idx;
                                }
                            }

                            int imgIndex = maxIndex + 1;

                            foreach (var file in model.NewImages)
                            {
                                if (file != null && file.ContentLength > 0)
                                {
                                    string ext = Path.GetExtension(file.FileName);
                                    string fileName = $"{safeRoomNo}_{imgIndex}{ext}";
                                    string path = Path.Combine(uploadDir, fileName);

                                    // Extra safety check
                                    while (System.IO.File.Exists(path))
                                    {
                                        imgIndex++;
                                        fileName = $"{safeRoomNo}_{imgIndex}{ext}";
                                        path = Path.Combine(uploadDir, fileName);
                                    }

                                    file.SaveAs(path);

                                    db.RoomImages.Add(new RoomImages
                                    {
                                        RoomID = room.RoomID,
                                        ImageUrl = "/public/rooms/" + fileName,
                                        IsMainImage = false,
                                        UploadedAt = DateTime.Now,
                                        DisplayOrder = imgIndex
                                    });
                                    imgIndex++;
                                }
                            }
                        }

                        db.SaveChanges();

                        LogActivity("Update", "Rooms", room.RoomID, oldValues,
                            Newtonsoft.Json.JsonConvert.SerializeObject(new { room.Price, room.StatusID, room.Title }),
                            $"Updated room information {room.RoomNumber}");

                        transaction.Commit();
                        TempData["Message"] = "Update successful!";
                        return RedirectToAction("ManageRooms");
                    }
                    catch (System.Data.Entity.Validation.DbEntityValidationException ex)
                    {
                        transaction.Rollback();
                        var errorMessages = ex.EntityValidationErrors
                                .SelectMany(x => x.ValidationErrors)
                                .Select(x => x.ErrorMessage);
                        var fullErrorMessage = string.Join("; ", errorMessages);
                        ModelState.AddModelError("", "Lỗi dữ liệu: " + fullErrorMessage);
                    }
                    catch (System.Data.Entity.Infrastructure.DbUpdateException ex)
                    {
                        transaction.Rollback();
                        var innerMessage = ex.InnerException?.InnerException?.Message ?? ex.InnerException?.Message ?? ex.Message;
                        ModelState.AddModelError("", "Lỗi cập nhật CSDL: " + innerMessage);
                    }
                    catch (Exception ex)
                    {
                        transaction.Rollback();
                        ModelState.AddModelError("", "Có lỗi xảy ra: " + ex.Message);
                    }
                }
            }

            // If we got here, something failed (ModelState invalid or Exception)
            model.Statuses = GetTranslatedStatuses();

            // Sync Utilities to ensure Names are present for rendering
            var allUtilsForEdit = db.Utilities.ToList();
            if (model.Utilities == null || !model.Utilities.Any())
            {
                model.Utilities = allUtilsForEdit.Select(u => new UtilitySelection_65133295
                {
                    UtilityID = u.UtilityID,
                    UtilityName = u.UtilityName,
                    IsSelected = false
                }).ToList();
            }
            else
            {
                foreach (var util in model.Utilities)
                {
                    var dbUtil = allUtilsForEdit.FirstOrDefault(u => u.UtilityID == util.UtilityID);
                    if (dbUtil != null) util.UtilityName = dbUtil.UtilityName;
                }
            }

            // Repopulate existing images from DB
            var imagesFromDb = db.RoomImages.Where(ri => ri.RoomID == model.RoomID).ToList();
            model.ExistingImages = imagesFromDb.Select(i => new RoomImageViewModel_65133295
            {
                ImageID = i.ImageID,
                ImageURL = i.ImageUrl,
                IsPrimary = i.IsMainImage ?? false
            }).ToList();

            return View(model);
        }

        // POST: Admin/Admin_65133295/UpdateRoomStatus
        [HttpPost]
        [ValidateAntiForgeryToken]
        public JsonResult UpdateRoomStatus(int id, int statusId)
        {
            try
            {
                var room = db.Rooms.Find(id);
                if (room == null) return Json(new { success = false, message = "Không tìm thấy phòng" });

                var oldStatus = room.RoomStatuses?.StatusName;
                room.StatusID = statusId;
                room.UpdatedAt = DateTime.Now;
                db.SaveChanges();

                var newStatus = db.RoomStatuses.Find(statusId)?.StatusName;
                LogActivity("Update", "Rooms", id, oldStatus, newStatus, $"Changed room {room.RoomNumber} status to {newStatus}");

                return Json(new { success = true });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = ex.Message });
            }
        }

        // POST: Admin/Admin_65133295/DeleteRoom
        [HttpPost]
        [ValidateAntiForgeryToken]
        public JsonResult DeleteRoom(int id)
        {
            try
            {
                var room = db.Rooms.Find(id);
                if (room == null) return Json(new { success = false, message = "Không tìm thấy phòng" });

                // Check for active bookings
                if (db.Bookings.Any(b => b.RoomID == id && (b.BookingStatus == "Pending" || b.BookingStatus == "Confirmed")))
                {
                    return Json(new { success = false, message = "Room has active bookings, cannot delete." });
                }

                // Delete related data
                db.RoomUtilities.RemoveRange(db.RoomUtilities.Where(ru => ru.RoomID == id));
                db.RoomImages.RemoveRange(db.RoomImages.Where(ri => ri.RoomID == id));

                db.Rooms.Remove(room);
                db.SaveChanges();

                LogActivity("Delete", "Rooms", id, room.RoomNumber, null, $"Xóa phòng {room.RoomNumber} khỏi hệ thống");

                return Json(new { success = true });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = ex.Message });
            }
        }

        // View invoice details
        public ActionResult InvoiceDetails(int id)
        {
            var invoice = db.Payments
                .Include(p => p.Contracts.Bookings.Rooms)
                .Include(p => p.Users1)
                .Include(p => p.Fees)
                .FirstOrDefault(p => p.PaymentID == id);

            if (invoice == null) return HttpNotFound();

            ViewBag.PageTitle = "Invoice Details";
            ViewBag.PageDescription = "Detailed invoice information and fee breakdown for invoice #" + invoice.InvoiceNumber;

            return View(invoice);
        }

        // Approve reviews
        public ActionResult ApproveReviews()
        {
            var pendingReviews = db.Reviews
                .Include(r => r.Rooms)
                .Include(r => r.Users)
                .Where(r => r.Status == "Pending")
                .OrderByDescending(r => r.CreatedAt)
                .ToList();

            return View(pendingReviews);
        }

        // POST: Update review status
        [HttpPost]
        [ValidateAntiForgeryToken]
        public JsonResult UpdateReviewStatus(int id, string status)
        {
            try
            {
                var review = db.Reviews.Find(id);
                if (review == null) return Json(new { success = false, message = "Review not found." });

                review.Status = status;
                review.UpdatedAt = DateTime.Now;
                db.SaveChanges();

                // Notify User about review status update
                var userNotification = new Notifications
                {
                    RecipientID = review.UserID,
                    Title = status == "Approved" ? "Review Approved" : "Review Rejected",
                    Message = status == "Approved"
                        ? $"Your review for room P.{review.Rooms?.RoomNumber} has been approved and is now visible."
                        : $"Unfortunately, your review for room P.{review.Rooms?.RoomNumber} was not approved due to policy violation.",
                    Type = status == "Approved" ? "Approval" : "Rejection",
                    RelatedEntityType = "Review",
                    RelatedEntityID = review.ReviewID,
                    IsRead = false,
                    CreatedAt = DateTime.Now
                };
                db.Notifications.Add(userNotification);
                db.SaveChanges();

                string actionText = status == "Approved" ? "Approved" : "Rejected";
                LogActivity("Update", "Reviews", id, null, status, $"{actionText} review from {review.Users?.Email} for room {review.Rooms?.RoomNumber}");

                return Json(new { success = true });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = ex.Message });
            }
        }

        // View activity history
        public ActionResult ViewActivityLogs(string query = "", string fromDate = "", string toDate = "", string actionType = "", int page = 1)
        {


            var logsQuery = db.ActivityLogs.Include("Users").AsQueryable();

            // Filter by date range
            if (DateTime.TryParse(fromDate, out DateTime start))
            {
                logsQuery = logsQuery.Where(l => l.CreatedAt >= start);
            }
            if (DateTime.TryParse(toDate, out DateTime end))
            {
                // Include the end date fully (up to 23:59:59)
                end = end.Date.AddDays(1).AddTicks(-1);
                logsQuery = logsQuery.Where(l => l.CreatedAt <= end);
            }

            // Filter by ActionType
            if (!string.IsNullOrEmpty(actionType))
            {
                logsQuery = logsQuery.Where(l => l.ActionType == actionType);
            }

            // Search by Description or Entity
            if (!string.IsNullOrEmpty(query))
            {
                string lowerQuery = query.ToLower();
                logsQuery = logsQuery.Where(l =>
                    l.Description.ToLower().Contains(lowerQuery) ||
                    l.EntityType.ToLower().Contains(lowerQuery) ||
                    (l.Users != null && l.Users.Email.Contains(lowerQuery))
                );
            }

            // Get all logs sorted by date
            var logs = logsQuery
                .OrderByDescending(l => l.CreatedAt)
                .ToList();

            // Pass data to view
            ViewBag.Query = query;
            ViewBag.FromDate = fromDate;
            ViewBag.ToDate = toDate;
            ViewBag.ActionType = actionType;
            ViewBag.TotalLogs = logs.Count;

            // Get distinct ActionTypes for dropdown
            ViewBag.ActionTypes = db.ActivityLogs.Select(l => l.ActionType).Distinct().ToList();

            return View(logs);
        }
        // Helper to get translated statuses
        private List<RoomStatuses> GetTranslatedStatuses()
        {
            return db.RoomStatuses.AsEnumerable().Select(s =>
            {
                string name = (s.StatusName ?? "").Trim();
                string translatedName = s.StatusName;

                if (s.StatusID == 1 || name.Equals("Available", StringComparison.OrdinalIgnoreCase))
                    translatedName = "Available";
                else if (s.StatusID == 2 || name.Equals("Rented", StringComparison.OrdinalIgnoreCase))
                    translatedName = "Rented";
                else if (s.StatusID == 3 || name.Equals("Maintenance", StringComparison.OrdinalIgnoreCase))
                    translatedName = "Maintenance";
                else if (s.StatusID == 4 || name.Equals("Reserved", StringComparison.OrdinalIgnoreCase))
                    translatedName = "Reserved";

                return new RoomStatuses
                {
                    StatusID = s.StatusID,
                    StatusName = translatedName
                };
            }).ToList();
        }

        // Replace the existing ApproveBooking method with this defensive, diagnostic version.
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult ApproveBooking(int id)
        {
            using (var transaction = db.Database.BeginTransaction())
            {
                try
                {
                    // Check Session first
                    if (Session["UserID"] == null || !int.TryParse(Session["UserID"].ToString(), out int adminId))
                    {
                        TempData["ErrorMessage"] = "Session expired. Please log in again.";
                        return RedirectToAction("ManageBookings", "Admin_65133295", new { area = "Admin" });
                    }

                    var booking = db.Bookings
                        .Include("Rooms")
                        .Include("Users1")
                        .FirstOrDefault(b => b.BookingID == id);
                    if (booking == null)
                    {
                        TempData["ErrorMessage"] = "Booking not found.";
                        return RedirectToAction("ManageBookings", "Admin_65133295", new { area = "Admin" });
                    }

                    if (booking.BookingStatus != "Pending")
                    {
                        TempData["ErrorMessage"] = "This request is not in pending status.";
                        return RedirectToAction("ManageBookings", "Admin_65133295", new { area = "Admin" });
                    }

                    if (booking.Rooms == null)
                    {
                        TempData["ErrorMessage"] = "Booking has no associated room.";
                        return RedirectToAction("ManageBookings", "Admin_65133295", new { area = "Admin" });
                    }

                    // Get deposit amount (should always be > 0 now)
                    decimal depositAmount = booking.DepositAmount ?? 0;
                    if (depositAmount <= 0)
                    {
                        // Fallback: use room price if deposit missing
                        depositAmount = booking.Rooms?.Price ?? 0;
                    }

                    // 1. Update Booking
                    booking.BookingStatus = "Approved";
                    booking.ApprovedAt = DateTime.Now;
                    booking.ApprovedBy = adminId;
                    db.SaveChanges(); // Save booking first

                    // 2. Create Contract
                    string contractNumber = "HD-" + DateTime.Now.Ticks.ToString().Substring(10);
                    if (contractNumber.Length > 50) contractNumber = contractNumber.Substring(0, 50);

                    var contract = new Contracts
                    {
                        BookingID = booking.BookingID,
                        ContractNumber = contractNumber,
                        StartDate = booking.CheckInDate,
                        EndDate = booking.CheckInDate.AddMonths(booking.Duration ?? 12),
                        RentalPrice = booking.Rooms.Price,
                        DepositAmount = depositAmount,
                        Status = "Active",
                        CreatedAt = DateTime.Now
                    };
                    db.Contracts.Add(contract);
                    db.SaveChanges(); // Save contract FIRST to get ContractID

                    // 3. Update Room
                    var room = booking.Rooms;
                    room.StatusID = 2; // Rented
                    room.CurrentTenantID = booking.UserID;
                    db.SaveChanges(); // Save room

                    // 4. Activity Log
                    var log = new ActivityLogs
                    {
                        UserID = adminId,
                        ActionType = "Approve Booking",
                        EntityType = "Bookings",
                        EntityID = booking.BookingID,
                        NewValues = $"Status: Approved, Contract: {contract.ContractNumber}, Room: {room.RoomNumber}",
                        CreatedAt = DateTime.Now
                    };
                    db.ActivityLogs.Add(log);

                    // 5. Create Initial Deposit Invoice (Payment)
                    // Validate booking.Bookings.UserID exists
                    int tenantUserId = booking.UserID;
                    if (!db.Users.Any(u => u.UserID == tenantUserId))
                    {
                        transaction.Rollback();
                        TempData["ErrorMessage"] = "Tenant user not found.";
                        return RedirectToAction("ManageBookings", "Admin_65133295", new { area = "Admin" });
                    }

                    var depositInvoice = new Payments
                    {
                        ContractID = contract.ContractID,
                        UserID = tenantUserId,
                        AdminID = adminId,
                        InvoiceNumber = "INV-DEP-" + DateTime.Now.Ticks.ToString().Substring(10),
                        PaymentDate = DateTime.Now,
                        Amount = depositAmount,
                        PaymentStatus = "Pending",
                        DueDate = DateTime.Now.AddDays(3),
                        Notes = "Deposit invoice for room " + room.RoomNumber,
                        CreatedAt = DateTime.Now,
                        UpdatedAt = DateTime.Now
                    };
                    db.Payments.Add(depositInvoice);

                    try
                    {
                        db.SaveChanges(); // Save payment to get PaymentID
                    }
                    catch (System.Data.Entity.Infrastructure.DbUpdateException dbEx)
                    {
                        // Unwrap inner exceptions for actionable message
                        var inner = dbEx.InnerException;
                        string innerMsg = dbEx.Message;
                        while (inner != null)
                        {
                            innerMsg += " -> " + inner.Message;
                            inner = inner.InnerException;
                        }
                        transaction.Rollback();
                        TempData["ErrorMessage"] = "DB error creating payment: " + innerMsg;
                        // Log brief failure
                        LogActivity("Error", "Payments", null, null, null, $"Failed creating payment for booking {booking.BookingID}: {innerMsg}");
                        return RedirectToAction("ManageBookings", "Admin_65133295", new { area = "Admin" });
                    }

                    // 6. Notification for User
                    string tenantName = booking.Users1?.FirstName ?? "Tenant";
                    var notification = new Notifications
                    {
                        RecipientID = tenantUserId,
                        SenderID = adminId,
                        Title = "Booking request APPROVED",
                        Message = $"Hello {tenantName}, your booking request for room {room.RoomNumber} has been approved. Please pay the deposit invoice of {depositInvoice.Amount.ToString("N0")} VND in the 'My Invoices' section to complete the check-in!",
                        Type = "Success",
                        RelatedEntityType = "Payments",
                        RelatedEntityID = depositInvoice.PaymentID,
                        IsRead = false,
                        CreatedAt = DateTime.Now
                    };
                    db.Notifications.Add(notification);

                    try
                    {
                        db.SaveChanges(); // Final save for notification and activity log
                    }
                    catch (System.Data.Entity.Infrastructure.DbUpdateException dbEx)
                    {
                        var inner = dbEx.InnerException;
                        string innerMsg = dbEx.Message;
                        while (inner != null)
                        {
                            innerMsg += " -> " + inner.Message;
                            inner = inner.InnerException;
                        }
                        transaction.Rollback();
                        TempData["ErrorMessage"] = "DB error saving notification/log: " + innerMsg;
                        LogActivity("Error", "Notifications", null, null, null, $"Failed creating notification for booking {booking.BookingID}: {innerMsg}");
                        return RedirectToAction("ManageBookings", "Admin_65133295", new { area = "Admin" });
                    }

                    transaction.Commit();
                    TempData["SuccessMessage"] = $"Approved booking request from {(booking.Users1 != null ? booking.Users1.LastName : "Guest")} and created contract {contract.ContractNumber} successfully!";
                    return RedirectToAction("ManageBookings", "Admin_65133295", new { area = "Admin" });
                }
                catch (Exception ex)
                {
                    transaction.Rollback();
                    // Unwrap inner exceptions
                    string fullError = ex.Message;
                    Exception inner = ex.InnerException;
                    while (inner != null)
                    {
                        fullError += " -> " + inner.Message;
                        inner = inner.InnerException;
                    }
                    // Log and surface a concise message to admin
                    LogActivity("Error", "Bookings", id, null, null, $"ApproveBooking failed for booking {id}: {fullError}");
                    TempData["ErrorMessage"] = "Error approving booking: " + fullError;
                    return RedirectToAction("ManageBookings", "Admin_65133295", new { area = "Admin" });
                }
            }
        }

        private void LogActivity(string action, string entity, int? entityId, string oldValues, string newValues, string description)
        {
            try
            {
                var log = new ActivityLogs
                {
                    UserID = GetCurrentAdminID(),
                    ActionType = action ?? "",
                    EntityType = entity,
                    EntityID = entityId,
                    OldValues = oldValues,
                    NewValues = newValues,
                    Description = description,
                    IPAddress = Request?.UserHostAddress,
                    CreatedAt = DateTime.Now
                };
                db.ActivityLogs.Add(log);
                db.SaveChanges();
            }
            catch
            {
                // Swallow logging errors to avoid breaking main flows; consider logging to text file if needed.
            }
        }

        private int? GetCurrentAdminID()
        {
            // If session already has it, return it
            if (Session["UserID"] is int sid) return sid;

            // If user is authenticated, try to repopulate session from DB
            if (User?.Identity?.IsAuthenticated == true)
            {
                string email = User.Identity.Name;
                var user = db.Users.FirstOrDefault(u => u.Email == email);
                if (user != null)
                {
                    Session["UserID"] = user.UserID;
                    Session["UserEmail"] = user.Email;
                    Session["UserRole"] = user.Role.ToString();
                    Session["UserRoleValue"] = (int)user.Role;
                    Session["FullName"] = $"{user.FirstName} {user.LastName}".Trim();
                    Session["Avatar"] = user.Avatar;
                    return user.UserID;
                }
            }

            return null;
        }

        // Manage bookings (view, update status, delete)
        public ActionResult ManageBookings(string query = "", string status = "")
        {
            var bookingsQuery = db.Bookings
                .Include(b => b.Rooms)
                .Include(b => b.Users1)
                .AsQueryable();

            if (!string.IsNullOrEmpty(query))
            {
                string term = query.Trim().ToLower();
                bookingsQuery = bookingsQuery.Where(b =>
                    (b.Users1 != null && (
                        (b.Users1.FirstName ?? "").ToLower().Contains(term) ||
                        (b.Users1.LastName ?? "").ToLower().Contains(term) ||
                        (b.Users1.PhoneNumber ?? "").ToLower().Contains(term)
                    )) ||
                    (b.Rooms != null && (b.Rooms.RoomNumber ?? "").ToLower().Contains(term))
                );
            }

            if (!string.IsNullOrEmpty(status))
            {
                bookingsQuery = bookingsQuery.Where(b => b.BookingStatus == status);
            }

            var model = bookingsQuery
                .OrderByDescending(b => b.CreatedAt)
                .Select(b => new Project_65133295.Areas.Admin.Data.BookingListItem_65133295
                {
                    BookingID = b.BookingID,
                    TenantFullName = (b.Users1 != null ? (b.Users1.FirstName + " " + b.Users1.LastName).Trim() : "Guest"),
                    TenantPhone = b.Users1 != null ? b.Users1.PhoneNumber : "",
                    RoomNumber = b.Rooms != null ? b.Rooms.RoomNumber : "",
                    RoomTitle = b.Rooms != null ? b.Rooms.Title : "",
                    CheckInDate = b.CheckInDate,
                    Duration = b.Duration,
                    DepositAmount = b.DepositAmount,
                    BookingStatus = b.BookingStatus
                })
                .ToList();

            ViewBag.CurrentQuery = query;
            ViewBag.CurrentStatus = status;

            return View(model);
        }

        // GET: Admin/Admin_65133295/ManageContracts
        public ActionResult ManageContracts(string query = "", string status = "")
        {
            var contracts = db.Contracts
                .Include(c => c.Bookings.Users1)
                .Include(c => c.Bookings.Rooms)
                .AsQueryable();

            if (!string.IsNullOrEmpty(query))
            {
                string term = query.Trim().ToLower();
                contracts = contracts.Where(c =>
                    c.ContractNumber.ToLower().Contains(term) ||
                    (c.Bookings != null && c.Bookings.Users1 != null && (c.Bookings.Users1.FirstName.ToLower().Contains(term) || c.Bookings.Users1.LastName.ToLower().Contains(term)))
                );
            }

            if (!string.IsNullOrEmpty(status))
            {
                contracts = contracts.Where(c => c.Status == status);
            }

            ViewBag.CurrentQuery = query;
            ViewBag.CurrentStatus = status;

            return View(contracts.OrderByDescending(c => c.CreatedAt).ToList());
        }

        // GET: Admin/Admin_65133295/CreateInvoice?contractId=123
        public ActionResult CreateInvoice(int contractId)
        {
            var contract = db.Contracts
                .Include(c => c.Bookings.Users1)
                .Include(c => c.Bookings.Rooms)
                .FirstOrDefault(c => c.ContractID == contractId);

            if (contract == null) return HttpNotFound();

            return View(contract);
        }

        // POST: Admin/Admin_65133295/CreateInvoice
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult CreateInvoice(int ContractID, DateTime PaymentDate, DateTime DueDate, string Notes, string[] FeeName, decimal[] FeeAmount)
        {
            var contract = db.Contracts.Include(c => c.Bookings).FirstOrDefault(c => c.ContractID == ContractID);
            if (contract == null) return HttpNotFound();

            int? adminId = GetCurrentAdminID();
            if (adminId == null) return RedirectToAction("Login", "Guest_65133295", new { area = "" });

            try
            {
                decimal rental = contract.RentalPrice;
                decimal sumFees = 0;
                if (FeeAmount != null && FeeAmount.Length > 0)
                {
                    sumFees = FeeAmount.Sum();
                }

                var payment = new Payments
                {
                    ContractID = contract.ContractID,
                    UserID = contract.Bookings?.UserID ?? 0,
                    AdminID = adminId.Value,
                    InvoiceNumber = "INV-" + DateTime.Now.Ticks.ToString().Substring(10),
                    PaymentDate = PaymentDate,
                    DueDate = DueDate,
                    Amount = rental + sumFees,
                    PaymentStatus = "Pending",
                    Notes = Notes,
                    CreatedAt = DateTime.Now,
                    UpdatedAt = DateTime.Now
                };

                db.Payments.Add(payment);
                db.SaveChanges(); // get PaymentID

                // Add fees
                if (FeeName != null && FeeAmount != null)
                {
                    for (int i = 0; i < Math.Min(FeeName.Length, FeeAmount.Length); i++)
                    {
                        var name = FeeName[i];
                        var amt = FeeAmount[i];
                        if (string.IsNullOrWhiteSpace(name) || amt <= 0) continue;
                        db.Fees.Add(new Fees
                        {
                            PaymentID = payment.PaymentID,
                            FeeName = name,
                            FeeAmount = amt
                        });
                    }
                }

                db.SaveChanges();

                // Notify tenant
                if (payment.UserID != 0)
                {
                    db.Notifications.Add(new Notifications
                    {
                        RecipientID = payment.UserID,
                        SenderID = adminId.Value,
                        Title = "New Invoice",
                        Message = $"Bạn có một hóa đơn mới: {payment.InvoiceNumber}. Vui lòng thanh toán.",
                        Type = "Invoice",
                        RelatedEntityType = "Payments",
                        RelatedEntityID = payment.PaymentID,
                        IsRead = false,
                        CreatedAt = DateTime.Now
                    });
                    db.SaveChanges();
                }

                LogActivity("Create", "Payments", payment.PaymentID, null, payment.Amount.ToString(), $"Created invoice {payment.InvoiceNumber} for contract {contract.ContractNumber}");

                TempData["SuccessMessage"] = "Invoice created successfully.";
                return RedirectToAction("CreateMonthlyInvoices");
            }
            catch (Exception ex)
            {
                ModelState.AddModelError("", "Error creating invoice: " + ex.Message);
                return View(contract);
            }
        }

        // GET: Admin/Admin_65133295/CreateMonthlyInvoices
        public ActionResult CreateMonthlyInvoices(string query = "", string status = "")
        {
            var invoices = db.Payments
                .Include(p => p.Contracts.Bookings.Rooms)
                .Include(p => p.Users1)
                .AsQueryable();

            if (!string.IsNullOrEmpty(query))
            {
                string term = query.Trim().ToLower();
                invoices = invoices.Where(p => p.InvoiceNumber.ToLower().Contains(term) || (p.Users1 != null && (p.Users1.FirstName.ToLower().Contains(term) || p.Users1.LastName.ToLower().Contains(term))));
            }

            if (!string.IsNullOrEmpty(status)) invoices = invoices.Where(p => p.PaymentStatus == status);

            ViewBag.CurrentQuery = query;
            ViewBag.CurrentStatus = status;

            return View(invoices.OrderByDescending(p => p.CreatedAt).ToList());
        }

        // GET: Admin/Admin_65133295/ManageUsers
        public ActionResult ManageUsers()
        {
            var users = db.Users.OrderBy(u => u.UserID).ToList();
            return View(users);
        }

        // POST: Admin/Admin_65133295/CheckoutContract
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult CheckoutContract(int id)
        {
            try
            {
                var contract = db.Contracts.Include(c => c.Bookings.Rooms).FirstOrDefault(c => c.ContractID == id);
                if (contract == null)
                {
                    TempData["ErrorMessage"] = "Contract not found.";
                    return RedirectToAction("ManageContracts");
                }

                // Mark contract terminated
                contract.Status = "Terminated";
                db.SaveChanges();

                // Update room status to Available and clear tenant
                var room = contract.Bookings?.Rooms;
                if (room != null)
                {
                    room.StatusID = 1; // Available
                    room.CurrentTenantID = null;
                    db.SaveChanges();
                }

                LogActivity("Checkout", "Contracts", contract.ContractID, null, null, $"Checked out contract {contract.ContractNumber}");
                TempData["SuccessMessage"] = "Checkout processed successfully.";
                return RedirectToAction("ManageContracts");
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = "Error during checkout: " + ex.Message;
                return RedirectToAction("ManageContracts");
            }
        }
    }
}