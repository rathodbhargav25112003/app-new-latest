// String baseUrl = "https://d93a-2409-40e4-4d-def3-97f1-fb76-3733-1573.ngrok-free.app/api";        //office wifi live
String baseUrl = "https://api.sushrutalgs.in/api"; //office wifi live
// String baseUrl = "http://192.168.29.25:8000/api";        //office wifi local
// String baseUrl = "http://192.168.29.83:8000/api";       //ajay
// String baseUrl = "http://192.168.45.138:3003/api";          //suraj
// String baseUrl = "http://192.168.43.147:8000/api";       //harsh
// String baseUrl = "http://192.168.29.71:8000/api";       //sir
String pdfBaseUrl = "https://api.sushrutalgs.in/";
// String pdfBaseUrl = "https://d93a-2409-40e4-4d-def3-97f1-fb76-3733-1573.ngrok-free.app/";
// String pdfBaseUrl = "http://192.168.45.138:3003/";
// String pdfBaseUrl = "http://192.168.29.83:8000/";
//String baseUrl="https://d68d-2409-40e5-9d-1f7f-ca2b-48a-342f-ba3c.ngrok-free.app/api";
//String pdfBaseUrl="https://4e08-2409-40e5-19-36e-13c1-23a9-e16a-1750.ngrok-free.app/";

//delete Account
String deleteAccount = "$baseUrl/deleteuser";

//Auth
String userRegister = "$baseUrl/user/register";
// String userRegister = "$baseUrl/user/v2/registerUserV2";
String userLogin = "$baseUrl/user/login";
String userLoginwithWt = "$baseUrl/user/v2/login";
String userLoginWithPhone = "$baseUrl/user/whatsappOtp";
String userLoginWithWtPhone = "$baseUrl/sendwhatsappOtp";
String userLoginVerifyOtp = "$baseUrl/user/LoginWithOtp";
String userLoginVerifyOtp2 = "$baseUrl/user/LoginWithOtp2";
String userRegisterOtp2 = "$baseUrl/user/LoginWithRegisterOtp2";
String userGoogleLogin = "$baseUrl/user/loginWithgoogle";
String createNotification = "$baseUrl/usernotification";
String logoutUser = "$baseUrl/user/logOutUser";
String deleteNotification = "$baseUrl/deletuserfcmtokem";
String notificationList = "$baseUrl/getUsernotification";
String sendOtpToMail = "$baseUrl/user/sendRegisterOtpMail";
String sendOtpToPhone = "$baseUrl/sendRegisterWhatsappOtp";
String sendOtpToForgotMail = "$baseUrl/user/sendOtpMail";
String verifyOtpMail = "$baseUrl/user/verifyOTP";
String verifyforgotpassOtpMail = "$baseUrl/user/verifyforgotpasswordOTP";
String forgotPass = "$baseUrl/user/forgot-password";

//Subscription
// String subscriptionsPlan = "$baseUrl/Subscription/getAll";
String subscriptionsPlan = "$baseUrl/v3/Subscription/getAll";
String createSubscriptionsPlan = "$baseUrl/Order/create";
String getSubscribedPlan = "$baseUrl/Order/getBuyorder";
String getPaymentMethod = "$baseUrl/Razorpaykey/getRazorpaykey";
String getSubscribedPlannew = "$baseUrl/Order/v2/getBuyorderV2";

//Coupon
String getAllCouponByUser = "$baseUrl/Coupon/getAllCouponByUser";
String getAllBookBySubscriptionPlan = "$baseUrl/getBookBySubsciptionId";
String getBookOffer = "$baseUrl/getBookOffer";
//all hardCopy notes
String getAllBookList = "$baseUrl/getAllByPreparingWise";
//video
String videoCategory = "$baseUrl/v3/getAllVideoCategory";
// String videoSubCategory = "$baseUrl/getAllVideoSubcategory";
String videoSubCategory = "$baseUrl/v3/getVideoCategoryId";
String videoTopicCategory = "$baseUrl/v3/getVideoBySubcategoryId";
// String videoTopic = "$baseUrl/getAllVideoBytopic";
String videoTopic = "$baseUrl/v3/getVideoBytopicId";
// String videoTopicDetail = "$baseUrl/getVideosByTopic";
String videoTopicDetail = "$baseUrl/v2/getVideosByContentId";
String markAsCompleted = "$baseUrl/CreateVideoHistory";

//test
String testCategory = "$baseUrl/v3/getByCategory";
String testSubCategory = "$baseUrl/v3/getBySubcategory";
String testTopic = "$baseUrl/v3/getByTopic";
String testExamPaperData = "$baseUrl/Exam/getAllQuestion";
String testPracticeExamPaperData = "$baseUrl/getPracticeQuestionList";
String testMockPracticeExamPaperData =
    "$baseUrl/MasterExam/getPracticeQuestionList";
String customTestPracticeExamPaperData =
    "$baseUrl/CustomTest/getPracticeQuestionList";
//master Exam
String getAllTestCategory = "$baseUrl/v3/getAllTestCategory";
String getAllTest = "$baseUrl/v3/getAllTest";
String testMaterExamPaperData = "$baseUrl/v2/getAllQuestion";
String createMasterExam = "$baseUrl/UserExam/createFullTestUserExam";
String userAnswerMaster = "$baseUrl/UserAnswer/v2/createFullTestAnswer";
String masterTestQuestionPallete = "$baseUrl/v2/getFullTestquestionPallete";
String masterTestQuestionPalleteCount = "$baseUrl/v2/getFullTestPalleteCount";
String masterTestReportByExam = "$baseUrl/v2/getReportBySubmit";
// String masterSolutionReportCategory = "$baseUrl/v2/getFullTestSolution";
String masterSolutionReportCategory = "$baseUrl/getSolutionByTopicName";
String mertiListMasterExam = "$baseUrl/v2/getMeritList";
String masterreportListByCategory = "$baseUrl/v2/getreportListByCategory";
String masterReportsByTestCategory = "$baseUrl/v2/getReportExamList";
String solutionMasterReportCategory = "$baseUrl/v3/getReport";
String getMasterExamCount = "$baseUrl/v3/getExamCount";

//notes
String notesCategory = "$baseUrl/v3/getAllPdfCategory";
// String notesSubCategory = "$baseUrl/getAllPdfSubcategory";
String notesSubCategory = "$baseUrl/v3/getPdfCategoryId";
String notesTopicCategory = "$baseUrl/v3/getPdfBySubcategoryId";
// String notesTopic = "$baseUrl/getAllPdfBytopic";
String notesTopic = "$baseUrl/v3/getPdfBytopicId";
// String notesTopicDetail = "$baseUrl/getPdfBytopic";
String notesTopicDetail = "$baseUrl/v2/getPdfByContentId";
//custom test
String createCustomTestUrl = "$baseUrl/CustomTest/create";
String deleteCustomTestUrl = "$baseUrl/deleteCustomTest";
String getAllMyCustomTest = "$baseUrl/getAllMyCustomTest";
String customTestSubByCateId = "$baseUrl/getSubcategoryBycategoryId";
String customTestTopicBySubId = "$baseUrl/getTopicBySubCategoryId";
String customTestExamByTopicId = "$baseUrl/getExamByTopicId";
String createCustomExam = "$baseUrl/CustomUserExam/create";
String testCustomExamPaperData = "$baseUrl/CustomTest/getAllQuestion";
String customTestQuestionPalletes = "$baseUrl/CustomQuestionPallete";
String userCustomAnswer = "$baseUrl/CustomUserAnswer/create";
String getCustomTestQuesAnswer = "$baseUrl/CustomUserAnswer/getquestionAns";
String customTestQuestionPalleteCount = "$baseUrl/CustomQuestionPalleteCount";
String customTestReportByExam = "$baseUrl/getCustomReportBySubmit";
String customTestReportByCategory = "$baseUrl/getCustomReport";
String customTestSolutionReportCategory = "$baseUrl/getCustomSolution";
String createCustomTestQuery = "$baseUrl/createCustomQuery";
//quiz test
String getTodayQuiz = "$baseUrl/QuizUserExam/getTodayQuiz";
String createQuizExam = "$baseUrl/QuizUserExam/create";
String quizExamPaperData = "$baseUrl/getAllQuestionByQuizId";
String userQuizAnswer = "$baseUrl/QuizUserAnswer/create";
String getQuizQuesAnswer = "$baseUrl/getquestionAns";
String quizTestQuestionPalleteCount = "$baseUrl/quizQuestionPalleteCount";
String quizQuestionPallete = "$baseUrl/quizQuestionPallete";
String quizTestReportByExam = "$baseUrl/QuizUserExam/getReportBySubmit";
String quizSolutionReport = "$baseUrl/QuizUserExam/getQuizSolution";
String createQuizQuery = "$baseUrl/createQuizQuery";
//practice test
String getQuestionCountPractice = "$baseUrl/getQuestionCountForPractice";
String getCountPracticeReport = "$baseUrl/getReportByPracticeSubmit";
String getMockQuestionCountPractice =
    "$baseUrl/MasterExam/getQuestionCountForPractice";
String getMockCountPracticeReport = "$baseUrl/getMockPracticeReport";
String getCustomQuestionCountPractice =
    "$baseUrl/CustomTest/getQuestionCountForPractice";
String getCustomCountPracticeReport = "$baseUrl/getCustomPracticeReport";
//test
String testExamByCategory = "$baseUrl/getTestByCategory";
String testExamBySubCategory = "$baseUrl/gettestBySubcategory";
String testExamByTopic = "$baseUrl/v3/getTestByTopic";
String createExam = "$baseUrl/UserExam/create";
// String userAnswer = "$baseUrl/UserAnswer/create";
String userAnswer = "$baseUrl/UserAnswer/v2/createV2";
String getQuesAnswer = "$baseUrl/UserAnswer/getquestionAns";
// String testQuestionPallete = "$baseUrl/questionPallete";
String testQuestionPallete = "$baseUrl/v2/questionPalleteV2";
// String testQuestionPalleteCount = "$baseUrl/questionPalleteCount";
String testQuestionPalleteCount = "$baseUrl/v2/questionPalleteCountV2";
String testReportByExam = "$baseUrl/getReportBySubmit";
String testReportByExamV2 = "$baseUrl/v2/getReportBySubmitV2";
//report
String reportsCategory = "$baseUrl/getReportBycategory";
String reportsSubCategory = "$baseUrl/getReportBysubcategory";
String reportsTopic = "$baseUrl/getReportByTopic";
String reportsTopicName = "$baseUrl/getReportByTopicName2";
String reportCategoryNewChange = "$baseUrl/v2/getReportBycategoryV2";

String reportsList = "$baseUrl/getreportlist";
String reportsByTestCategory = "$baseUrl/getTestlistcategory";
String reportsByTestSubCategory = "$baseUrl/getTestlistSubcategory";
String reportsByTestTopic = "$baseUrl/getTestlistTopic";
String reportByStegthTopic = "$baseUrl/getPercentWiseReport/";

String getexplanation = "$baseUrl/getExplanation";
String reportListByCategory = "$baseUrl/getreportListByCategory";
String reportListBySubCategory = "$baseUrl/getreportListBySubCategory";
String reportListByTopic = "$baseUrl/getreportListByTopic";

//Ask Quetion
String createAskQuestion = "$baseUrl/AskQuestion/create";
String getAskQuestion = "$baseUrl/getUserAskQuestion";
String deleteAskQuestion = "$baseUrl/deleteAskQuestion";
// address
String createAddress = "$baseUrl/Address/create";
String updateAddress = "$baseUrl/updateAddress";
String getAddresses = "$baseUrl/getAllUserAddress";
String createBookOrder = "$baseUrl/createBookOrder";

// String solutionReportCategory = "$baseUrl/getSolutionBycategory";
String solutionReportCategory = "$baseUrl/v2/getSolutionV2";
String createQuerySolutionReport = "$baseUrl/Query/create";
String createQueryMock = "$baseUrl/MockQuery/create";
String mertiListExam = "$baseUrl/FindMaxScore";
String createNote = "$baseUrl/createNotes";
String getNote = "$baseUrl/getNotes";
// String solutionReportSubCategory = baseUrl+ "/getSolutionBysubcategory";
// String solutionReportTopic = baseUrl+ "/getSolutionReportByTopic";

//bookmark
String getBookMarkList = "$baseUrl/getbookmarklist";
String updateBookMark = "$baseUrl/Bookmark/create";
// String updateBookMark = "$baseUrl/updateUserAnswer";
String bookMarkCategory = "$baseUrl/getbooklistcategory";
String masterBookMarkExamList = "$baseUrl/v2/getBookmarkExamList";
String bookMarkSubCategory = "$baseUrl/getbooklistSubcategory";
String bookMarkTopic = "$baseUrl/getbooklistTopic";
String getbookmarkAttempt = "$baseUrl/getbookmarkAttempt";
String getbookmarksQuestions = "$baseUrl/getbookmarks";
String getmasterBookmarksQuestions = "$baseUrl/v2/getbookmarks";
String deletebookmarksQuestions = "$baseUrl/deleteBookmark";

String bookmarkCategoryList = "$baseUrl/getbookmarklistcategory";
String masterBookmarkCategoryList = "$baseUrl/v2/getbookmarklistcategory";
String bookmarkSubCategoryList = "$baseUrl/getbookmarklistSubcategory";
String bookmarkTopicList = "$baseUrl/getbookmarklistTopic";

//Featured List
String getFeaturedContents = "$baseUrl/getFindFeatured";
String getPreparingForExams = "$baseUrl/preparing/getpreparing";

String getUserDetails = "$baseUrl/user/getUser";
String updateUserDetails = "$baseUrl/updateuser";
String getOfferBanner = "$baseUrl/Banner/getBanner";
String getSettings = "$baseUrl/Setting/getSetting";

//testimonial and blogs
String createTestimonialUrl = "$baseUrl/Tetsimonial/create";
String getTestimonialLists = "$baseUrl/Tetsimonial/getAll";
String getBlogsLists = "$baseUrl/Blog/getAll";
//Search
String getSearchByKeyword = "$baseUrl/getcategorySearch";
String getSearchBySubCatKeyword = "$baseUrl/getSubcategorySearch";
String getSearch = "$baseUrl/v2/getSearch";

//Zoom
String getAllMeetingLive = "$baseUrl/getAllMeeting/live";

String getAllMeetingUpcoming = "$baseUrl/getAllMeeting/upcoming";
