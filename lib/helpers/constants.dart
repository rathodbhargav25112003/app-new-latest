// String baseUrl = "https://8f6ef434b48d.ngrok-free.app/api";        //office wifi live
// String baseUrl = "http://192.168.52.138:8000/api"; //office wifi live
// String baseUrl = "http://192.168.228.138:8000/api"; //office wifi live
// String baseUrl = "http://10.248.162.139:8000/api"; //office wifi live
// String baseUrl =
//     "https://10c3-2409-40e4-104d-38f-1f74-5970-eb69-4636.ngrok-free.app/api"; //office wifi live
String baseUrl = "https://api.sushrutalgs.in/api"; //office wifi live

// String baseUrl =67c97c182eee1e1e5153d809\67cd1716f100ee804869d00e
//     "https://9d39-2409-40e4-2048-1076-ac52-bb5e-98ca-1fc2.ngrok-free.app/api"; //office wifi live
// String baseUrl = "http://192.168.21.138:8000/api"; //office wifi live

// String baseUrl = "http://192.168.1.3:8000/api"; //office wifi live
// String baseUrl = "http://192.168.245.139:8000/api"; //office wifi live
// String baseUrl = "http://64.227.167.108/api"; //office wifi live
// String baseUrl = "http://192.168.150.138:3003/api";        //office wifi local
// String baseUrl = "http://192.168.29.83:8000/api";       //ajay 
// String baseUrl = "http://192.168.109.138:3003/api";          //suraj
// String baseUrl = "http://192.168.43.147:8000/api";       //harsh
// String baseUrl = "http://192.168.29.71:8000/api";       //sir
// String baseUrl = "http://192.168.88.138:8000/api";
String pdfBaseUrl = "https://api.sushrutalgs.in/";
// String pdfBaseUrl = "http://192.168.52.138:8000/";
// String pdfBaseUrl = "http://192.168.171.138:8000/";        //office wifi local
// String pdfBaseUrl = "http://192.168.29.83:8000/";
//String baseUrl="https://d68d-2409-40e5-9d-1f7f-ca2b-48a-342f-ba3c.ngrok-free.app/api";
//String pdfBaseUrl="https://4e08-2409-40e5-19-36e-13c1-23a9-e16a-1750.ngrok-free.app/";

//delete Account
String deleteAccount = "$baseUrl/deleteuser";
String restoreUser = "$baseUrl/restoreUser";
String clearNotifications = "$baseUrl/CleareNotification";

//Auth
String userRegister = "$baseUrl/user/register";
// String userRegister = "$baseUrl/user/v2/registerUserV2";
String userLogin = "$baseUrl/user/login";
String getDeclarationTest = "$baseUrl/getDeclarationTest";
String userLoginwithWt = "$baseUrl/user/v2/login";
String userLoginWithPhone = "$baseUrl/user/whatsappOtp";
String userLoginWithWtPhone = "$baseUrl/sendwhatsappOtp";
String userLoginVerifyOtp = "$baseUrl/user/LoginWithOtp";
String userLoginVerifyOtp2 = "$baseUrl/user/LoginWithOtp2";
String deleteLoggedInDevice = "$baseUrl/user/deleteLoggedInDevice";
String checkDeviceExists = "$baseUrl/user/checkDeviceExists";
String checkDevice = "$baseUrl/checkDevice";
String userRegisterOtp2 = "$baseUrl/user/LoginWithRegisterOtp2";
String userGoogleLogin = "$baseUrl/user/loginWithgoogle";
String createNotification = "$baseUrl/usernotification";
String logoutUser = "$baseUrl/user/logOutUser";
String logoutUserAllDevice = "$baseUrl/logOutUserFromAllDevice";
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
String createFixedSubscriptionsPlan = "$baseUrl/Order/create2";
String getSubscribedPlan = "$baseUrl/Order/getBuyorder";
String getPaymentMethod = "$baseUrl/Razorpaykey/getRazorpaykey";
// String getSubscribedPlannew = "$baseUrl/Order/v2/getBuyorderV2";
String getSubscribedPlannew = "$baseUrl/getMyPlan";
String getAllBookOrder = "$baseUrl/getAllUserBookOrder";

//Coupon
String getAllCouponByUser = "$baseUrl/Coupon/getAllCouponByUser";
String getAllOfferByUser = "$baseUrl/Offer/getAllOfferByUser";
String createOfferByUser = "$baseUrl/userOffer/create";
String getAllUserOfferUrl = "$baseUrl/getAllUserOffer";
String getAllBookBySubscriptionPlan = "$baseUrl/getBookBySubsciptionId";
String getBookOffer = "$baseUrl/getBookOffer";
//all hardCopy notes
// String getAllBookList="$baseUrl/getAllByPreparingWise";
String getAllBookList = "$baseUrl/Book/getAll";
//continue watching
String getWatchingHistory = "$baseUrl/getWatchingHistory";
String getHomePageHistory = "$baseUrl/getHomePageHistory";
String createWatchingHistoryTest = "$baseUrl/CreateWatchingTest";
String createWatchingHistoryVideoNote = "$baseUrl/CreateWatchingHistory";
//video
String videoCategory = "$baseUrl/v3/getAllVideoCategory";
// String videoSubCategory = "$baseUrl/getAllVideoSubcategory";
String videoSubCategory = "$baseUrl/v3/getVideoCategoryId";
String videoTopicCategory = "$baseUrl/v3/getVideoBySubcategoryId";
// String videoTopic = "$baseUrl/getAllVideoBytopic";
// String videoTopic = "$baseUrl/v3/getVideoBytopicId";
String videoTopic = "$baseUrl/v4/getVideoBytopicId";
// String videoTopicDetail = "$baseUrl/getVideosByTopic";
String videoTopicDetail = "$baseUrl/v2/getVideosByContentId";
String videoChapterizationData = "$baseUrl/videoChapterization";
String getAllVideoBytopicId = "$baseUrl/getVideoChapter";
String getVimeoVideoData = "$baseUrl/getVimeoVideo";
String markAsCompleted = "$baseUrl/CreateVideoHistory";
String videoContentProgress = "$baseUrl/ContentProgress";
String bookmarkContent = "$baseUrl/createBookmarkContent";

//test
String testCategory = "$baseUrl/v3/getByCategory";
String testSubCategory = "$baseUrl/v3/getBySubcategory";
String createFreeTrail = "$baseUrl/createPlanFreeTrail";
String testTopic = "$baseUrl/v3/getByTopic";
String testExamPaperData = "$baseUrl/Exam/getAllQuestion";
String practiceTestExamPaperData = "$baseUrl/Exam/getAllQuestion2";
String testPracticeExamPaperData = "$baseUrl/getPracticeQuestionList";
String testMockPracticeExamPaperData =
    "$baseUrl/MasterExam/getPracticeQuestionList";
String customTestPracticeExamPaperData =
    "$baseUrl/CustomTest/getPracticeQuestionList";
//master Exam
String getAllTestCategory = "$baseUrl/v3/getAllTestCategory";
String getAllTestCategoryByType = "$baseUrl/v3/getAllTestCategoryByType";
String getLeaderBoardCategory = "$baseUrl/getLeaderBoardCategory";
String getAllTest = "$baseUrl/v3/getAllTest";
String getUserAttemptList = "$baseUrl/getUserAttemptList";
String getMcqUserTestList = "$baseUrl/getMcqUserTestList";
String getAllLeaderboardTest = "$baseUrl/getLeaderBoardExam";
String getAllTrendAnalysis = "$baseUrl/getTrendAnalysis";
String testMaterExamPaperData = "$baseUrl/v2/getAllQuestion";
String practiceTestMaterExamPaperData = "$baseUrl/mockExam/getAllQuestion";
String testSectionExamPaperData = "$baseUrl/getAllSectionQuestion";
String createMasterExam = "$baseUrl/UserExam/createFullTestUserExam";
String createSectionMasterExam = "$baseUrl/createUserSection";
String userAnswerMaster = "$baseUrl/UserAnswer/v2/createFullTestAnswer";
String masterTestQuestionPallete = "$baseUrl/v2/getFullTestquestionPallete";
String masterTestQuestionPalleteCount = "$baseUrl/v2/getFullTestPalleteCount";
String sectionTestQuestionPalleteCount = "$baseUrl/getSectionWisePalleteCount";
String masterTestReportByExam = "$baseUrl/v2/getReportBySubmit";
String getAllMyCustomTestBookmarkApi = "$baseUrl/v2/getAllMyCustomTest";
String getBookmarkSubcategoryListApi = "$baseUrl/v2/getBookmarkSubcategoryList";
String getBookmarkMCQQuestionListApi = "$baseUrl/getMcqBookmarkQList/";
String getBookmarkMockQuestionListApi = "$baseUrl/getMockBookmarkQList/";
String getCustomeQuestionListApi = "$baseUrl/getCustomBookmarkQList/";
String getCustomeMcqListApi = "$baseUrl/getCustomQuestionList/";
String getReBookmarkMCQQuestionListApi = "$baseUrl/getMcqPracticeQuestionList/";
String getCustomPracticeQsList = "$baseUrl/getCustomPracticeQsList/";
String getReBookmarkMockQuestionListApi =
    "$baseUrl/getMockPracticeQuestionList/";
String getCustomAnalysisBookmarkApi = "$baseUrl/getCustomUserExamList";
String deleteBookmarkTestApi = "$baseUrl/deleteBookmarkTest";
String customUserExamCreateExam = "$baseUrl/customUserExamCreate";
String createTest = "$baseUrl/createTest";
// String masterSolutionReportCategory = "$baseUrl/v2/getFullTestSolution";
String masterSolutionReportCategory = "$baseUrl/getSolutionByTopicName";
String mertiListMasterExam = "$baseUrl/v2/getMeritList";
String compareWithRank = "$baseUrl/getFirstRankAnalysis";
String masterreportListByCategory = "$baseUrl/v2/getreportListByCategory";
String masterReportsByTestCategory = "$baseUrl/v2/getReportExamList";
String solutionMasterReportCategory = "$baseUrl/v2/getReport";
String getMasterExamCount = "$baseUrl/v3/getExamCount";

///mock exam section wise
String getSectionTestList = "$baseUrl/getSectionTestList";
String sectionTestQuestionPallete = "$baseUrl/getSectionQuestionPallete";
String sectionAllQuestionPalleteCount = "$baseUrl/getSectionPalleteCount";
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
String customTestCategory = "$baseUrl/getCategoryForCusom";
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
String getQuestionCountPractice = "$baseUrl/getQuestionCountForPractice2";
String getNEETPrediction =
    "https://slgs-f1c855846531.herokuapp.com/predict_by_marks";
String getCountPracticeReport = "$baseUrl/getReportByPracticeSubmit2";
String getCustomPracticeReport = "$baseUrl/getCustomPracticeReport";
String getBookmarkPracticeReport = "$baseUrl/getBookmarkPracticeReport";
String getMockQuestionCountPractice =
    "$baseUrl/MasterExam/getQuestionCountForPractice";
String getMockCountPracticeReport = "$baseUrl/getMockPracticeReport";
String getCustomQuestionCountPractice =
    "$baseUrl/CustomTest/getQuestionCountForPractice";
String getCustomCountPracticeReport = "$baseUrl/getCustomPracticeReport";
//test
String testExamByCategory = "$baseUrl/getTestByCategory";
String testExamBySubCategory = "$baseUrl/gettestBySubcategory";
String getMcqQuestionList = "$baseUrl/getMcqQuestionList";
String testExamByTopic = "$baseUrl/v4/getTestByTopic";
String getCountTestMode = "$baseUrl/getCountTestMode";
String getCustomCountTestMode = "$baseUrl/getCustomCountTestMode";
String getBookmarkPracticeReport2 = "$baseUrl/getBookmarkPracticeReport";
String createExplAnnotation = "$baseUrl/createExplAnnotation";
String deleteHistoryUrl = "$baseUrl/deleteHistory";
String verifyUpdateNumberUser = "$baseUrl/verifyUpdateUser";
String createExam = "$baseUrl/v2/UserExam/create";
// String userAnswer = "$baseUrl/UserAnswer/create";
String userAnswer = "$baseUrl/UserAnswer/v2/createV2";
String getQuesAnswer = "$baseUrl/UserAnswer/getquestionAns";
// String testQuestionPallete = "$baseUrl/questionPallete";
String testQuestionPallete = "$baseUrl/v2/questionPalleteV2";
// String testQuestionPalleteCount = "$baseUrl/questionPalleteCount";
String testQuestionPalleteCount = "$baseUrl/v2/questionPalleteCountV2";
String testReportByExam = "$baseUrl/getReportBySubmit";
String testReportByExamV2 = "$baseUrl/v2/getReportBySubmitV2";
String examReports = "$baseUrl/getAnalysis";
String getMcqAnalysis = "$baseUrl/getMcqAnalysis";
String getCustomAnalysis = "$baseUrl/getCustomAnalysis";
String examReportsRank1 = "$baseUrl/getFirstRankAnalysis2";
//report
String reportsCategory = "$baseUrl/getReportBycategory";
String reportsSubCategory = "$baseUrl/getReportBysubcategory";
String reportsTopic = "$baseUrl/getReportByTopic";
String reportsTopicName = "$baseUrl/getReportByTopicName";
String reportCategoryNewChange = "$baseUrl/v2/getReportBycategoryV2";

String reportsList = "$baseUrl/getreportlist";
String reportsByTestCategory = "$baseUrl/getTestlistcategory";
String reportsByTestSubCategory = "$baseUrl/getTestlistSubcategory";
String reportsByTestTopic = "$baseUrl/getTestlistTopic";
String reportByStegthTopic = "$baseUrl/getPercentWiseReport/";

String getexplanation = "$baseUrl/getExplanation";

// ── Cortex AI v2/v3 endpoints ──
// Multi-turn chat, streaming, mistake debrief, related MCQs, modes,
// memory, snippets, search, export, flashcards. Backed by /api/cortex/*
// on the server. Backward-compatible — getexplanation above stays
// untouched and continues to power the legacy single-shot ask flow.
String cortexUsage = "$baseUrl/cortex/usage";
String cortexChats = "$baseUrl/cortex/chats";
String cortexChat = "$baseUrl/cortex/chat";                  // POST new chat / GET :id / PATCH :id / DELETE :id
String cortexChatMessage = "$baseUrl/cortex/chat";           // POST :id/message  (?stream=true → SSE)
String cortexMessageRate = "$baseUrl/cortex/message";        // POST :id/rate
String cortexMistakeDebrief = "$baseUrl/cortex/mistake-debrief";  // ?stream=true → SSE
String cortexRelatedMcqs = "$baseUrl/cortex/related-mcqs";   // GET :question_id
String cortexRoleplay = "$baseUrl/cortex/roleplay";          // ?stream=true → SSE
String cortexOsceViva = "$baseUrl/cortex/osce-viva";         // ?stream=true → SSE
String cortexTopicDeepDive = "$baseUrl/cortex/topic-deep-dive"; // ?stream=true → SSE
String cortexMnemonic = "$baseUrl/cortex/mnemonic";
String cortexDiagram = "$baseUrl/cortex/diagram";
String cortexSummarize = "$baseUrl/cortex/chat";             // POST :id/summarize
String cortexFollowups = "$baseUrl/cortex/message";          // GET :id/follow-ups
String cortexFlashcards = "$baseUrl/cortex/message";         // POST :id/flashcards
String cortexSnippet = "$baseUrl/cortex/message";            // POST :id/snippet
String cortexSnippets = "$baseUrl/cortex/snippets";
String cortexSearch = "$baseUrl/cortex/search";              // ?q=…
String cortexExport = "$baseUrl/cortex/chat";                // GET :id/export
String cortexMemory = "$baseUrl/cortex/memory";
String cortexQuickPrompts = "$baseUrl/cortex/quick-prompts"; // ?context_kind=…

// ── MCQ Review v3 — confidence, time-spent, discussions, SR queue,
//    analytics, study plan, audio, scheduled sessions ──
String userAnswerConfidence = "$baseUrl/user-answer/confidence";          // PATCH
String reviewQueueEnrollFromAttempt = "$baseUrl/review-queue/enroll-from-attempt";
String reviewQueueDue = "$baseUrl/review-queue/due";
String reviewQueueStats = "$baseUrl/review-queue/stats";
String reviewQueueEnroll = "$baseUrl/review-queue/enroll";
String reviewQueueGrade = "$baseUrl/review-queue";       // POST :id/grade
String reviewQueueStatus = "$baseUrl/review-queue";      // PATCH :id/status

String discussionThread = "$baseUrl/discussion/q";       // GET :question_id
String discussionPost = "$baseUrl/discussion/q";         // POST :question_id/post
String discussionPostBase = "$baseUrl/discussion/post";  // PATCH/:id, DELETE/:id, /:id/upvote, /:id/report, /:id/replies, /:id/accept

String analyticsTopicTrend = "$baseUrl/analytics/topic-trend";
String analyticsCalibration = "$baseUrl/analytics/calibration";
String analyticsQuestionTime = "$baseUrl/analytics/question-time";       // GET :question_id
String analyticsTopicStrength = "$baseUrl/analytics/topic-strength";

String cortexStudyPlan = "$baseUrl/cortex/study-plan";
String cortexAudioExplain = "$baseUrl/cortex/audio-explain";
String cortexScheduledSession = "$baseUrl/cortex/scheduled-session";
String cortexScheduledSessions = "$baseUrl/cortex/scheduled-sessions";

String reportListByCategory = "$baseUrl/getreportListByCategory";
String reportListBySubCategory = "$baseUrl/getreportListBySubCategory";
String reportListByTopic = "$baseUrl/getreportListByTopic";
String userScore = "$baseUrl/v2/getMeritList2";

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
String getCustomSolution2 = "$baseUrl/getCustomSolution2";
String createQuerySolutionReport = "$baseUrl/Query/create";
String createQueryMock = "$baseUrl/MockQuery/create";
String mertiListExam = "$baseUrl/FindMaxScore";
String createNote = "$baseUrl/createNotes";
String createPdfAnnotationData = "$baseUrl/createNotesAnnotation";
String getNote = "$baseUrl/getNotes";
// String solutionReportSubCategory = baseUrl+ "/getSolutionBysubcategory";
// String solutionReportTopic = baseUrl+ "/getSolutionReportByTopic";

//bookmark
String getBookMarkList = "$baseUrl/getbookmarklist";
String updateBookMark = "$baseUrl/Bookmark/create";
// String updateBookMark = "$baseUrl/updateUserAnswer";
String bookMarkCategory = "$baseUrl/getbooklistcategory";
String masterBookMarkExamList = "$baseUrl/v2/getBookmarkExamList";
String masterBookMarkExamListv2 = "$baseUrl/getBookmarkExamList";
String bookMarkSubCategory = "$baseUrl/getbooklistSubcategory";
String bookMarkTopic = "$baseUrl/getbooklistTopic";
String getbookmarkAttempt = "$baseUrl/getbookmarkAttempt";
String getbookmarksQuestions = "$baseUrl/getbookmarks";
String getmasterBookmarksQuestions = "$baseUrl/v2/getbookmarks";
String deletebookmarksQuestions = "$baseUrl/deleteBookmark";

String bookmarkCategoryList = "$baseUrl/getbookmarklistcategory";
String masterBookmarkCategoryList = "$baseUrl/v2/getbookmarklistcategory";
String bookmarkSubCategoryList = "$baseUrl/getbookmarklistSubcategory";
String bookmarkCustomeSubCategoryList = "$baseUrl/getBookmarkSubcategoryList";
String bookmarkTopicList = "$baseUrl/getbookmarklistTopic";
String bookmarkTopicListv2 = "$baseUrl/getBookmarkTopicList";

//Featured List
String getFeaturedContents = "$baseUrl/getFindFeatured";
String getPreparingForExams = "$baseUrl/preparing/getpreparing";
String getStanderdUrl = "$baseUrl/getStanderd";
String getStanderdByPreparingId = "$baseUrl/getStanderdByPreparingId";

String getUserDetails = "$baseUrl/user/getUser";
String getProgressDataDetails = "$baseUrl/getAllProgress";
String updateUserDetails = "$baseUrl/updateuser";
String getOfferBanner = "$baseUrl/Banner/getBanner";
String getSettings = "$baseUrl/Setting/getSetting";

//testimonial and blogs
String createTestimonialUrl = "$baseUrl/Tetsimonial/create";
String getTestimonialLists = "$baseUrl/Tetsimonial/getAll";
String getBlogsLists = "$baseUrl/Blog/getAll";
String getBlogDetails = "$baseUrl/Blog/getByBlogId";
//Search
String getSearchByKeyword = "$baseUrl/getcategorySearch";
String getSearchBySubCatKeyword = "$baseUrl/getSubcategorySearch";
String getSearch = "$baseUrl/v2/getSearch";
//global search
String getGlobalSearch = "$baseUrl/getGlobalSearch";
String getExamQuestionList = "$baseUrl/getAllQuestionByType/";
String createUserAnswerByType = "$baseUrl/createUserAnswerByType";
String customUserAnswerCreateApi = "$baseUrl/customUserAnswerCreate";

//Zoom
String getAllMeetingLive = "$baseUrl/getAllMeeting/live";

String getAllMeetingUpcoming = "$baseUrl/getAllMeeting/upcoming";

String getAllPlanCategoryGoal = "$baseUrl/getAllPlanCategory";
String getAllCustomSubsriptionByCatId = "$baseUrl/getSubByCatId";
String getAllSubsriptionPlan = "$baseUrl/getAllPlanForUser";
String getStaticsPlan = "$baseUrl/getStaticsPlan";

// API for Books
String getAllBookUrl = '$baseUrl/getAllBook';
String createMultiplePlans = '$baseUrl/Order/createmultiple';

// macOS In-App Purchase: create order verification (macOS only)
String createInAPurchasesOrder = "$baseUrl/createInAPurchasesOrder";

// ───── User features (video bookmarks, resume list, streak, review, prefs) ─────
String userVideoBookmarks = "$baseUrl/user/video-bookmarks";
String userResumeList = "$baseUrl/user/resume-list";
String userStreak = "$baseUrl/user/streak";
String userAnalyticsSummary = "$baseUrl/user/analytics/summary";
String userReviewNext = "$baseUrl/user/review/next";
String userReviewAnswer = "$baseUrl/user/review/answer";
String userReviewEnqueue = "$baseUrl/user/review/enqueue";
String userTopicMastery = "$baseUrl/user/topic-mastery";
String userDeviceRegister = "$baseUrl/user/device/register";
String userDeviceUnregister = "$baseUrl/user/device"; // append /:deviceId
String userPreferences = "$baseUrl/user/preferences";
