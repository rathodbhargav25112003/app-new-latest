import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/empty_state.dart';
import '../../helpers/styles.dart';
import '../widgets/custom_remove_file_bottomsheet.dart';

class DownloadedNotes extends StatefulWidget {
  final String? filePath;
  final String? title;
  final String? titleId;
  const DownloadedNotes({super.key, this.filePath, this.title, this.titleId});

  @override
  State<DownloadedNotes> createState() => _DownloadedNotesState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => DownloadedNotes(
        filePath: arguments['filePath'],
        title: arguments['title'],
        titleId: arguments['titleId'],
      ),
    );
  }
}

class _DownloadedNotesState extends State<DownloadedNotes> {
  Future<List<FileSystemEntity>>? _fileList;

  Future<List<FileSystemEntity>> getFilesInDocumentsDirectory() async {
    Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();
    List<FileSystemEntity> files = appDocumentsDirectory.listSync();

    List<FileSystemEntity> pdfFiles = files.where((file) {
      return file is File && file.path.toLowerCase().endsWith('.pdf');
    }).toList();

    return pdfFiles;
  }

  @override
  void initState() {
    super.initState();
    _fileList = getFilesInDocumentsDirectory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppTokens.scaffold(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTokens.ink(context), size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text("Offline notes", style: AppTokens.titleLg(context)),
        centerTitle: false,
      ),
      // appBar: AppBar(
      //   elevation: 0,
      //   automaticallyImplyLeading: false,
      //   backgroundColor: ThemeManager.white,
      //   leading: Padding(
      //     padding: const EdgeInsets.only(left: Dimensions.PADDING_SIZE_SMALL),
      //     child:       IconButton(       highlightColor: Colors.transparent,     hoverColor: Colors.transparent,
      //       icon:  Icon(Icons.arrow_back_ios, color: ThemeManager.iconColor),
      //       onPressed: () {
      //         Navigator.pop(context);
      //       },
      //     ),
      //   ),
      //   centerTitle: true,
      //   title: Column(
      //     children: [
      //       Text(
      //         "Offline notes",
      //         style: interRegular.copyWith(
      //           fontSize: Dimensions.fontSizeLarge,
      //           fontWeight: FontWeight.w500,
      //           color: ThemeManager.black,
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppTokens.s24, AppTokens.s8, AppTokens.s24, 0),
                child: Column(
                  children: [
                    ///Notes list
                    FutureBuilder<List<FileSystemEntity>>(
                      future: getFilesInDocumentsDirectory(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: AppTokens.accent(context),
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return EmptyState(
                            icon: Icons.error_outline_rounded,
                            title: 'Couldn’t load',
                            subtitle:
                                'Something went wrong reading offline files.',
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const EmptyState(
                            icon: Icons.cloud_off_rounded,
                            title: 'No offline files',
                            subtitle:
                                'Notes you download for offline reading will appear here.',
                          );
                        } else {
                          List<FileSystemEntity> fileList = snapshot.data!;
                          fileList.sort((a, b) => b
                              .statSync()
                              .modified
                              .compareTo(a.statSync().modified));

                          // return Container(
                          //   padding: const EdgeInsets.only(
                          //     left: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                          //     right: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                          //     bottom: Dimensions.PADDING_SIZE_LARGE,
                          //   ),
                          //   child: Column(
                          //     crossAxisAlignment: CrossAxisAlignment.start,
                          //     children: [
                          //       Text(
                          //         widget.title??"",
                          //         style: interRegular.copyWith(
                          //           fontSize: Dimensions.fontSizeDefault,
                          //           fontWeight: FontWeight.w600,
                          //           color: ThemeManager.black,
                          //         ),
                          //       ),
                          //       const SizedBox(height: Dimensions.PADDING_SIZE_SMALL,),
                          //       Row(
                          //         children: [
                          //           InkWell(
                          //             onTap: (){
                          //               Navigator.of(context).pushNamed(Routes.notesReadView,
                          //                   arguments: {
                          //                     'contentUrl' : widget.filePath,
                          //                     'title': widget.title,
                          //                     'isDownloaded': true
                          //                   });
                          //             },
                          //             child: Row(
                          //               children: [
                          //                 SvgPicture.asset("assets/image/read_eye_icon.svg", height: Dimensions.PADDING_SIZE_SMALL,width: Dimensions.PADDING_SIZE_SMALL,),
                          //                 const SizedBox(width: Dimensions.PADDING_SIZE_SMALL,),
                          //                 Text("Read",
                          //                   style: interSemiBold.copyWith(
                          //                     fontSize: Dimensions.fontSizeSmall,
                          //                     fontWeight: FontWeight.w400,
                          //                     color: ThemeManager.primaryColor,
                          //                   ),
                          //                 )
                          //               ],
                          //             ),
                          //           ),
                          //           const Spacer(),
                          //           InkWell(
                          //             onTap: () async{
                          //               FileSystemEntity? removedFile = await showModalBottomSheet<FileSystemEntity>(
                          //                 shape: const RoundedRectangleBorder(
                          //                   borderRadius: BorderRadius.vertical(
                          //                     top: Radius.circular(25),
                          //                   ),
                          //                 ),
                          //                 clipBehavior: Clip.antiAliasWithSaveLayer,
                          //                 context: context,
                          //                 builder: (BuildContext context) {
                          //                   return CustomRemoveFileBottomSheet(context,
                          //                       // file,
                          //                       widget.titleId);
                          //                 },
                          //               );
                          //               if (removedFile != null) {
                          //                 setState(() {
                          //                   _fileList.remove(removedFile);
                          //                 });
                          //               }
                          //             },
                          //             child: Row(
                          //               children: [
                          //                 SvgPicture.asset("assets/image/delete_icon.svg", height: Dimensions.PADDING_SIZE_DEFAULT,width: Dimensions.PADDING_SIZE_SMALL,),
                          //                 const SizedBox(width: Dimensions.PADDING_SIZE_SMALL,),
                          //                 Text("Remove",
                          //                   style: interSemiBold.copyWith(
                          //                     fontSize: Dimensions.fontSizeSmall,
                          //                     fontWeight: FontWeight.w400,
                          //                     color: ThemeManager.redAlert,
                          //                   ),
                          //                 )
                          //               ],
                          //             ),
                          //           ),
                          //         ],
                          //       ),
                          //       const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT,),
                          //       SizedBox(
                          //         width: MediaQuery.of(context).size.width,
                          //         height:1,
                          //         child: Container(
                          //           color: ThemeManager.black,
                          //         ),
                          //       ),
                          //     ],
                          //   ),
                          // );
                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: Dimensions.PADDING_SIZE_SMALL),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                    Routes.notesReadView,
                                    arguments: {
                                      'contentUrl': widget.filePath,
                                      'title': widget.title,
                                      "isCompleted": true,
                                      'isDownloaded': true
                                    });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(
                                    Dimensions.PADDING_SIZE_DEFAULT),
                                decoration: BoxDecoration(
                                    color: ThemeManager.white,
                                    border: Border.all(
                                        color: ThemeManager.mainBorder),
                                    borderRadius: BorderRadius.circular(9.6)),
                                child: Row(
                                  children: [
                                    Container(
                                      height:
                                          Dimensions.PADDING_SIZE_LARGE * 3.6,
                                      width:
                                          Dimensions.PADDING_SIZE_LARGE * 3.6,
                                      padding: const EdgeInsets.all(
                                          Dimensions.PADDING_SIZE_LARGE),
                                      decoration: BoxDecoration(
                                        color:
                                            ThemeManager.continueContainerTrans,
                                        borderRadius:
                                            BorderRadius.circular(14.4),
                                      ),
                                      child: SvgPicture.asset(
                                        "assets/image/book-open2.svg",
                                        color: ThemeManager.currentTheme ==
                                                AppTheme.Dark
                                            ? AppColors.white
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: Dimensions.PADDING_SIZE_DEFAULT,
                                    ),
                                    Expanded(
                                      // width: MediaQuery.of(context).size.width * 0.56,
                                      child: Text(
                                        widget.title ?? "",
                                        style: interSemiBold.copyWith(
                                          fontSize: Dimensions.fontSizeDefault,
                                          fontWeight: FontWeight.w600,
                                          color: ThemeManager.black,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () async {
                                        FileSystemEntity? removedFile =
                                            await showModalBottomSheet<
                                                FileSystemEntity>(
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(25),
                                            ),
                                          ),
                                          clipBehavior:
                                              Clip.antiAliasWithSaveLayer,
                                          context: context,
                                          builder: (BuildContext context) {
                                            return CustomRemoveFileBottomSheet(
                                                context,
                                                // file,
                                                widget.titleId);
                                          },
                                        );
                                        if (removedFile != null) {
                                          setState(() {
                                            fileList.remove(removedFile);
                                          });
                                        }
                                      },
                                      child: Icon(
                                        Icons.delete,
                                        size: 24,
                                        color: ThemeManager.redText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                          // return ListView.builder(
                          //   itemCount: _fileList.length,
                          //   shrinkWrap: true,
                          //   padding: const EdgeInsets.only(top: Dimensions.PADDING_SIZE_DEFAULT),
                          //   physics: const BouncingScrollPhysics(),
                          //   itemBuilder: (BuildContext context, int index){
                          //     FileSystemEntity file = _fileList[index];
                          //     String fileNameWithExtension = file.uri.pathSegments.last;
                          //     String fileName = fileNameWithExtension.substring(0, fileNameWithExtension.lastIndexOf('.pdf'));
                          //     return Container(
                          //       padding: const EdgeInsets.only(
                          //         left: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                          //         right: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                          //         bottom: Dimensions.PADDING_SIZE_LARGE,
                          //       ),
                          //       child: Column(
                          //         crossAxisAlignment: CrossAxisAlignment.start,
                          //         children: [
                          //           Text(
                          //             widget.topicName??"",
                          //             style: interRegular.copyWith(
                          //               fontSize: Dimensions.fontSizeDefault,
                          //               fontWeight: FontWeight.w600,
                          //               color: ThemeManager.black,
                          //             ),
                          //           ),
                          //           const SizedBox(height: Dimensions.PADDING_SIZE_SMALL,),
                          //           Row(
                          //             children: [
                          //               InkWell(
                          //                 onTap: (){
                          //                   Navigator.of(context).pushNamed(Routes.notesReadView,
                          //                       arguments: {
                          //                         'fileUrl' : widget.filePath,
                          //                         'title': widget.topicName,
                          //                         'isDownloaded': true
                          //                       });
                          //                 },
                          //                 child: Row(
                          //                   children: [
                          //                     SvgPicture.asset("assets/image/read_eye_icon.svg", height: Dimensions.PADDING_SIZE_SMALL,width: Dimensions.PADDING_SIZE_SMALL,),
                          //                     const SizedBox(width: Dimensions.PADDING_SIZE_SMALL,),
                          //                     Text("Read",
                          //                       style: interSemiBold.copyWith(
                          //                         fontSize: Dimensions.fontSizeSmall,
                          //                         fontWeight: FontWeight.w400,
                          //                         color: ThemeManager.primaryColor,
                          //                       ),
                          //                     )
                          //                   ],
                          //                 ),
                          //               ),
                          //               const Spacer(),
                          //               InkWell(
                          //                 onTap: () async{
                          //                   FileSystemEntity? removedFile = await showModalBottomSheet<FileSystemEntity>(
                          //                     shape: const RoundedRectangleBorder(
                          //                       borderRadius: BorderRadius.vertical(
                          //                         top: Radius.circular(25),
                          //                       ),
                          //                     ),
                          //                     clipBehavior: Clip.antiAliasWithSaveLayer,
                          //                     context: context,
                          //                     builder: (BuildContext context) {
                          //                       return CustomRemoveFileBottomSheet(context, file, widget.topicId);
                          //                     },
                          //                   );
                          //                   if (removedFile != null) {
                          //                     setState(() {
                          //                       _fileList.remove(removedFile);
                          //                     });
                          //                   }
                          //                 },
                          //                 child: Row(
                          //                   children: [
                          //                     SvgPicture.asset("assets/image/delete_icon.svg", height: Dimensions.PADDING_SIZE_DEFAULT,width: Dimensions.PADDING_SIZE_SMALL,),
                          //                     const SizedBox(width: Dimensions.PADDING_SIZE_SMALL,),
                          //                     Text("Remove",
                          //                       style: interSemiBold.copyWith(
                          //                         fontSize: Dimensions.fontSizeSmall,
                          //                         fontWeight: FontWeight.w400,
                          //                         color: ThemeManager.redAlert,
                          //                       ),
                          //                     )
                          //                   ],
                          //                 ),
                          //               ),
                          //             ],
                          //           ),
                          //           const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT,),
                          //           SizedBox(
                          //             width: MediaQuery.of(context).size.width,
                          //             height:1,
                          //             child: Container(
                          //               color: ThemeManager.black,
                          //             ),
                          //           ),
                          //         ],
                          //       ),
                          //     );
                          //   },
                          // );
                        }
                      },
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
