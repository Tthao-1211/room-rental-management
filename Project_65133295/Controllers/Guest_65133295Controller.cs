using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Web.Security;
using System.Data.Entity;
using System.Web.Routing;
using Project_65133295.Models;
using Project_65133295.Models.Forms_65133295;

namespace Project_65133295.Controllers
{
    public class Guest_65133295Controller : Controller
    {
        // GET: Guest_65133295

        // View homepage & system information
        public ActionResult Index()
        {
            return View();
        }

        private Project_65133295.Models.DbContext_65133295 db = new Project_65133295.Models.DbContext_65133295();

        // Search for rental rooms
        public ActionResult SearchRoom(string query, decimal? minPrice, decimal? maxPrice, decimal? minArea, decimal? maxArea, int[] selectedUtilities, string sortOrder, int page = 1)
        {
            int pageSize = 9;

            // 1. Base Query
            var rooms = db.Rooms
                               .Include(r => r.RoomImages)
                               .Include(r => r.RoomStatuses)
                               .Include(r => r.RoomUtilities.Select(ru => ru.Utilities))
                               .Where(r => r.StatusID == 1); // Only get available rooms

            // 2. Filtering
            if (!string.IsNullOrEmpty(query))
            {
                string term = query.Trim().ToLower();
                rooms = rooms.Where(r => r.RoomNumber.ToLower().Contains(term) ||
                                         r.Title.ToLower().Contains(term) || 
                                         r.Description.ToLower().Contains(term));
            }

            if (minPrice.HasValue)
                rooms = rooms.Where(r => r.Price >= minPrice.Value);
            
            if (maxPrice.HasValue)
                rooms = rooms.Where(r => r.Price <= maxPrice.Value);

            if (minArea.HasValue)
                rooms = rooms.Where(r => r.Area >= minArea.Value);

            if (maxArea.HasValue)
                rooms = rooms.Where(r => r.Area <= maxArea.Value);

            if (selectedUtilities != null && selectedUtilities.Length > 0)
            {
                foreach (var utilId in selectedUtilities)
                {
                    rooms = rooms.Where(r => r.RoomUtilities.Any(u => u.UtilityID == utilId));
                }
            }

            // 3. Sorting
            ViewBag.CurrentSort = sortOrder;
            switch (sortOrder)
            {
                case "price_asc":
                    rooms = rooms.OrderBy(r => r.Price);
                    break;
                case "price_desc":
                    rooms = rooms.OrderByDescending(r => r.Price);
                    break;
                case "rating":
                    // Sort by average rating (if has reviews)
                    rooms = rooms.OrderByDescending(r => r.Reviews.Any() ? r.Reviews.Average(rv => rv.Rating) : 0);
                    break;
                default: // Newest
                    rooms = rooms.OrderByDescending(r => r.CreatedAt);
                    break;
            }

            // 4. Pagination
            int totalItems = rooms.Count();
            int totalPages = (int)Math.Ceiling((double)totalItems / pageSize);
            page = Math.Max(1, Math.Min(page, totalPages > 0 ? totalPages : 1));

            var pagedRooms = rooms.Skip((page - 1) * pageSize).Take(pageSize).ToList();

            // 5. ViewBag Data for View
            ViewBag.Utilities = db.Utilities.ToList();
            ViewBag.Query = query;
            ViewBag.MinPrice = minPrice;
            ViewBag.MaxPrice = maxPrice;
            ViewBag.MinArea = minArea;
            ViewBag.MaxArea = maxArea;
            ViewBag.SelectedUtilities = selectedUtilities;
            ViewBag.Page = page;
            ViewBag.TotalPages = totalPages;
            ViewBag.TotalItems = totalItems;
            ViewBag.SortOrder = sortOrder;

            return View(pagedRooms);
        }

        // View room details
        public ActionResult RoomDetails(int? id)
        {
            if (id == null)
            {
                return RedirectToAction("SearchRoom");
            }

            var room = db.Rooms
                               .Include(r => r.RoomImages)
                               .Include(r => r.RoomUtilities.Select(ru => ru.Utilities))
                               .Include(r => r.Users) // Host/Admin info
                               .Include(r => r.Reviews.Select(rv => rv.Users))
                               .Include(r => r.RoomStatuses)
                               .FirstOrDefault(r => r.RoomID == id);

            if (room == null)
            {
                return HttpNotFound();
            }

            // Filter only approved reviews
            // Note: We can't easily filter included collection directly in the query in EF6 without third party libs or specific projection.
            // For simplicity in this context, we'll filter in the view or create a ViewModel. 
            // Better yet, let's just make sure Review.Status is checked in the View.

            return View(room);
        }

        // View booking guide
        public ActionResult BookingGuide()
        {
            return View();
        }

        // Login
        [HttpGet]
        public ActionResult Login(string returnUrl)
        {
            ViewBag.ReturnUrl = returnUrl;
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Login(LoginViewModel_65133295 model, string returnUrl)
        {
            if (ModelState.IsValid)
            {
                // Check user - Compare with PasswordHash
                var user = db.Users.FirstOrDefault(u => u.Email == model.Email && u.PasswordHash == model.Password);
                if (user != null)
                {
                    if (user.IsActive == true)
                    {
                        if (user.IsEmailVerified != true)
                        {
                            ModelState.AddModelError("", "Your account has not been activated. Please check your email to verify.");
                            return View(model);
                        }

                        FormsAuthentication.SetAuthCookie(user.Email, model.RememberMe);
                        
                        // Set Session details (crucial for Admin actions)
                        Session["UserID"] = user.UserID;
                        Session["UserEmail"] = user.Email;
                        Session["UserRole"] = user.Role.ToString().Trim();
                        Session["UserRoleValue"] = Convert.ToInt32(user.Role);
                        Session["FullName"] = $"{user.FirstName} {user.LastName}".Trim();
                        Session["Avatar"] = user.Avatar;

                        // Redirect logic
                        if (!string.IsNullOrEmpty(returnUrl) && Url.IsLocalUrl(returnUrl))
                        {
                            return Redirect(returnUrl);
                        }
                        
                        // Default redirect based on Role
                            if (user.Role == Project_65133295.Models.UserRole.Admin || user.Role == Project_65133295.Models.UserRole.NhanVien)
                            {
                                return RedirectToAction("Index", "Admin_65133295", new { area = "Admin" });
                            }
                            return RedirectToAction("Index", "User_65133295", new { area = "User" });
                    }
                    else
                    {
                        ModelState.AddModelError("", "Your account has been locked.");
                    }
                }
                else
                {
                    ModelState.AddModelError("", "Email or password is incorrect.");
                }
            }
            return View(model);
        }

        // Register account
        [HttpGet]
        public ActionResult Register()
        {
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Register(RegisterViewModel_65133295 model)
        {
            if (ModelState.IsValid)
            {
                var existUser = db.Users.FirstOrDefault(u => u.Email == model.Email);
                if (existUser == null)
                {
                    using (var transaction = db.Database.BeginTransaction())
                    {
                        try
                        {
                            string username = BuildUniqueUsername(model.Email);

                            var newUser = new User
                            {
                                Username = username,
                                LastName = model.LastName,
                                FirstName = model.FirstName,
                                Email = model.Email,
                                PhoneNumber = model.PhoneNumber,
                                PasswordHash = model.Password,
                                Role = Project_65133295.Models.UserRole.Khach, // Tenant
                                IsActive = true,
                                IsEmailVerified = false,
                                CreatedAt = DateTime.Now,
                                UpdatedAt = DateTime.Now
                            };
                            db.Users.Add(newUser);
                            try
                            {
                                db.SaveChanges();
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
                                throw new Exception("DB error creating user: " + innerMsg, dbEx);
                            }

                            // Create verification token
                            string token = Guid.NewGuid().ToString();
                            var verificationToken = new EmailVerificationTokens
                            {
                                UserID = newUser.UserID,
                                Token = token,
                                ExpiresAt = DateTime.Now.AddHours(24),
                                IsUsed = false,
                                CreatedAt = DateTime.Now
                            };
                            db.EmailVerificationTokens.Add(verificationToken);
                            try
                            {
                                db.SaveChanges();
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
                                throw new Exception("DB error creating verification token: " + innerMsg, dbEx);
                            }

                            transaction.Commit();

                            if (EmailService_65133295.IsEmailSendingEnabled())
                            {
                                // Send email after DB commit so SMTP failures do not roll back registration.
                                try
                                {
                                    EmailService_65133295.SendVerificationEmail(newUser.Email, newUser.FirstName, token);
                                }
                                catch (Exception mailEx)
                                {
                                    string mailError = mailEx.Message;
                                    Exception mailInner = mailEx.InnerException;
                                    while (mailInner != null)
                                    {
                                        mailError += " -> " + mailInner.Message;
                                        mailInner = mailInner.InnerException;
                                    }

                                    TempData["WarningMessage"] = "Account created, but verification email could not be sent: " + mailError;
                                }
                            }

                            return RedirectToAction("VerifyEmailInfo", new { email = newUser.Email });
                        }
                        catch (Exception ex)
                        {
                            transaction.Rollback();
                            string fullError = ex.Message;
                            Exception inner = ex.InnerException;
                            while (inner != null)
                            {
                                fullError += " -> " + inner.Message;
                                inner = inner.InnerException;
                            }
                            ModelState.AddModelError("", "An error occurred during registration: " + fullError);
                        }
                    }
                }
                else
                {
                    ModelState.AddModelError("", "This email has already been registered.");
                }
            }
            return View(model);
        }

        private string BuildUniqueUsername(string email)
        {
            string baseName = (email ?? "").Split('@').FirstOrDefault() ?? "";
            baseName = new string(baseName.Where(c => char.IsLetterOrDigit(c) || c == '_' || c == '.').ToArray()).Trim('.', '_');
            if (string.IsNullOrWhiteSpace(baseName))
            {
                baseName = "user";
            }

            const int maxLength = 50;
            string candidate = baseName.Length > maxLength ? baseName.Substring(0, maxLength) : baseName;
            int suffix = 1;

            while (db.Users.Any(u => u.Username == candidate))
            {
                string suffixText = "_" + suffix++;
                int allowedBaseLength = maxLength - suffixText.Length;
                if (allowedBaseLength < 1)
                {
                    allowedBaseLength = 1;
                }
                string trimmedBase = baseName.Length > allowedBaseLength ? baseName.Substring(0, allowedBaseLength) : baseName;
                candidate = trimmedBase + suffixText;
            }

            return candidate;
        }

        // Notification after successful registration, waiting for email verification
        public ActionResult VerifyEmailInfo(string email)
        {
            ViewBag.Email = email;
            return View();
        }

        // Handle when clicking link in email
        public ActionResult VerifyEmail(string token)
        {
            if (string.IsNullOrEmpty(token))
            {
                return RedirectToAction("Index");
            }

            var verificationToken = db.EmailVerificationTokens.Include("Users")
                                     .FirstOrDefault(t => t.Token == token && t.IsUsed == false && t.ExpiresAt > DateTime.Now);

            if (verificationToken != null)
            {
                var user = verificationToken.Users;
                user.IsEmailVerified = true;
                verificationToken.IsUsed = true;
                db.SaveChanges();

                ViewBag.Success = true;
                ViewBag.Message = "Email verification successful! You can log in now.";
            }
            else
            {
                ViewBag.Success = false;
                ViewBag.Message = "Verification link is invalid or has expired.";
            }

            return View("VerifyEmailResult");
        }

        // Forgot password
        [HttpGet]
        public ActionResult ForgotPassword()
        {
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult ForgotPassword(ForgotPasswordViewModel_65133295 model)
        {
            if (ModelState.IsValid)
            {
                var user = db.Users.FirstOrDefault(u => u.Email == model.Email);
                if (user != null)
                {
                    string token = Guid.NewGuid().ToString();
                    var resetToken = new PasswordResetTokens
                    {
                        UserID = user.UserID,
                        Token = token,
                        ExpiresAt = DateTime.Now.AddHours(24),
                        IsUsed = false,
                        CreatedAt = DateTime.Now
                    };
                    db.PasswordResetTokens.Add(resetToken);
                    db.SaveChanges();

                    try
                    {
                        if (EmailService_65133295.IsEmailSendingEnabled())
                        {
                            EmailService_65133295.SendPasswordResetEmail(user.Email, user.FirstName, token);
                        }
                        TempData["SuccessMessage"] = "If the email exists in our system, a password reset link has been sent.";
                    }
                    catch (Exception mailEx)
                    {
                        string mailError = mailEx.Message;
                        Exception mailInner = mailEx.InnerException;
                        while (mailInner != null)
                        {
                            mailError += " -> " + mailInner.Message;
                            mailInner = mailInner.InnerException;
                        }

                        TempData["WarningMessage"] = "Reset token was created, but email could not be sent: " + mailError;
                    }
                }

                return View("ForgotPasswordInfo", (object)model.Email);
            }
            return View(model);
        }

        public ActionResult ForgotPasswordInfo(string email)
        {
            ViewBag.Email = email;
            return View();
        }

        // Reset password
        [HttpGet]
        public ActionResult ResetPassword(string token, string email)
        {
            if (string.IsNullOrEmpty(token) || string.IsNullOrEmpty(email))
            {
                return RedirectToAction("Index");
            }

            var model = new ResetPasswordViewModel_65133295 { Token = token, Email = email };
            return View(model);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult ResetPassword(ResetPasswordViewModel_65133295 model)
        {
            if (ModelState.IsValid)
            {
                var resetToken = db.PasswordResetTokens.Include("Users")
                    .FirstOrDefault(t => t.Token == model.Token && t.IsUsed == false && t.ExpiresAt > DateTime.Now && t.Users.Email == model.Email);

                if (resetToken != null)
                {
                    var user = resetToken.Users;
                    user.PasswordHash = model.Password;
                    resetToken.IsUsed = true;
                    db.SaveChanges();

                    ViewBag.Success = true;
                    ViewBag.Message = "Password reset successful! You can log in with your new password.";
                    return View("VerifyEmailResult");
                }
                else
                {
                    ModelState.AddModelError("", "Password reset link is invalid or has expired.");
                }
            }
            return View(model);
        }

        // Logout
        public ActionResult Logout()
        {
            FormsAuthentication.SignOut();
            Session.Clear();
            return RedirectToAction("Index");
        }
    }

    public class CustomAuthorizeAttribute : AuthorizeAttribute
    {
        public string Role { get; set; }

        protected override bool AuthorizeCore(HttpContextBase httpContext)
        {
            if (!httpContext.User.Identity.IsAuthenticated)
            {
                return false;
            }

            if (string.IsNullOrEmpty(Role))
            {
                return true;
            }

            string userRole = httpContext.Session["UserRole"]?.ToString();
            
            // If session is lost but user is authenticated, try to recover session
            if (string.IsNullOrEmpty(userRole))
            {
                string email = httpContext.User.Identity.Name;
                using (var db = new DbContext_65133295())
                {
                    var user = db.Users.FirstOrDefault(u => u.Email == email);
                    if (user != null)
                    {
                        httpContext.Session["UserID"] = user.UserID;
                        httpContext.Session["UserEmail"] = user.Email;
                        httpContext.Session["UserRole"] = user.Role.ToString().Trim();
                        httpContext.Session["UserRoleValue"] = Convert.ToInt32(user.Role);
                        httpContext.Session["FullName"] = $"{user.FirstName} {user.LastName}".Trim();
                        httpContext.Session["Avatar"] = user.Avatar;
                        userRole = httpContext.Session["UserRole"]?.ToString();
                        var userRoleVal = httpContext.Session["UserRoleValue"]?.ToString();
                    }
                }
            }
            
            // Support comma-separated roles and numeric role ids (e.g. "0,1" or "Admin,NhanVien")
            if (string.IsNullOrEmpty(userRole)) return false;

            var requested = Role.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries)
                                 .Select(r => r.Trim()).ToArray();

            foreach (var req in requested)
            {
                // If requested role is numeric, compare numeric values
                if (int.TryParse(req, out int reqVal))
                {
                    var sessVal = httpContext.Session["UserRoleValue"]?.ToString();
                    if (int.TryParse(sessVal, out int sessInt) && sessInt == reqVal) return true;
                    // if session missing numeric, try to resolve from userRole string by parsing enum
                    if (Enum.TryParse<Project_65133295.Models.UserRole>(userRole, true, out var parsedRole))
                    {
                        var enumVal = Convert.ToInt32(parsedRole);
                        if (enumVal == reqVal) return true;
                    }
                }
                else
                {
                    if (string.Equals(userRole, req, StringComparison.OrdinalIgnoreCase)) return true;
                }
            }

            return false;
        }

        protected override void HandleUnauthorizedRequest(AuthorizationContext filterContext)
        {
            if (!filterContext.HttpContext.User.Identity.IsAuthenticated)
            {
                filterContext.Result = new RedirectToRouteResult(new RouteValueDictionary(new
                {
                    controller = "Guest_65133295",
                    action = "Login",
                    area = "",
                    returnUrl = filterContext.HttpContext.Request.RawUrl
                }));
            }
            else
            {
                filterContext.Controller.TempData["Error"] = "You do not have permission to access this area.";
                filterContext.Result = new RedirectToRouteResult(new RouteValueDictionary(new
                {
                    controller = "Guest_65133295",
                    action = "Index",
                    area = ""
                }));
            }
        }
    }
}
