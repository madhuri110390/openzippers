// import 'package:flutter/material.dart';
// import '../helpers/translations.dart';
// import '../helpers/database_helper.dart';
// import 'dart:io';
// import 'package:file_picker/file_picker.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
// import 'package:openzippers/widgets/media_player_widgets.dart';
// import 'package:path/path.dart' as p;
//
// class PublishingScreen extends StatefulWidget {
//   final String? artistName;
//   final List<Map<String, dynamic>> userPosts;
//
//   const PublishingScreen({super.key, this.artistName, this.userPosts = const []});
//
//   @override
//   State<PublishingScreen> createState() => _PublishingScreenState();
// }
//
// class _PublishingScreenState extends State<PublishingScreen> with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   final Set<Map<String, dynamic>> _selectedPosts = {};
//
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 4, vsync: this);
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _showRequestPublishingDialog(BuildContext context, [Map<String, dynamic>? singlePost]) async {
//     final postsToRequest = singlePost != null ? [singlePost] : _selectedPosts.toList();
//     final result = await showDialog<bool>(
//       context: context,
//       builder: (context) => _RequestPublishingDialog(
//         artistName: widget.artistName,
//         posts: postsToRequest,
//       ),
//     );
//
//     if (result == true) {
//       for (var post in postsToRequest) {
//         // Update DB
//         await DatabaseHelper().updatePostStatus(post['id'], publishingStatus: 'Pending');
//         // Update Local State
//         setState(() {
//           post['publishingStatus'] = 'Pending';
//         });
//       }
//       setState(() {
//          _selectedPosts.clear();
//       });
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//            SnackBar(content: Text("${context.tr.success}: ${context.tr.contentSubmittedPublishing}"))
//         );
//       }
//     }
//   }
//
//   void _toggleSelection(Map<String, dynamic> post) {
//     setState(() {
//       if (_selectedPosts.contains(post)) {
//         _selectedPosts.remove(post);
//       } else {
//         _selectedPosts.add(post);
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final tr = context.tr;
//     final isDark = theme.brightness == Brightness.dark;
//
//     final imagePosts = widget.userPosts.where((p) => p['type'] == 'Image').toList();
//     final songPosts = widget.userPosts.where((p) => p['type'] == 'Song').toList();
//     final videoPosts = widget.userPosts.where((p) => p['type'] == 'Video' || p['type'] == 'Reel' || p['type'] == 'Reels').toList();
//     final literaturePosts = widget.userPosts.where((p) => p['type'] == 'Literature').toList();
//
//     return Scaffold(
//       backgroundColor: theme.scaffoldBackgroundColor,
//       floatingActionButton: _selectedPosts.isNotEmpty ? FloatingActionButton.extended(
//         onPressed: () => _showRequestPublishingDialog(context),
//         backgroundColor: const Color(0xFFDB2777),
//         label: Text(context.tr.publishSelectedCount(_selectedPosts.length), style: const TextStyle(color: Colors.white)),
//         icon: const Icon(Icons.upload, color: Colors.white),
//       ) : null,
//       body: SafeArea(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//           Container(
//              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
//              child: Stack(
//                alignment: Alignment.center,
//                children: [
//                  Align(
//                    alignment: Alignment.centerLeft,
//                    child: IconButton(
//                      icon: const Icon(Icons.arrow_back),
//                      onPressed: () => Navigator.of(context).pop(),
//                    ),
//                  ),
//                  Row(
//                    mainAxisSize: MainAxisSize.min,
//                    children: [
//                      Icon(Icons.publish, color: const Color(0xFFDB2777), size: 28),
//                      const SizedBox(width: 10),
//                      Text(
//                        tr.publishedContent,
//                        style: theme.textTheme.titleLarge?.copyWith(
//                          fontWeight: FontWeight.bold,
//                        ),
//                      ),
//                    ],
//                  ),
//                ],
//              )
//           ),
//
//           Container(
//             color: theme.cardColor,
//             child: TabBar(
//               controller: _tabController,
//               indicatorColor: const Color(0xFFDB2777),
//               labelColor: const Color(0xFFDB2777),
//               unselectedLabelColor: theme.hintColor,
//               isScrollable: true,
//               tabAlignment: TabAlignment.start,
//               tabs: [
//                 Tab(
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Icon(Icons.image_outlined, size: 18),
//                       const SizedBox(width: 8),
//                       Text(tr.image),
//                       if (imagePosts.isNotEmpty)
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                           decoration: BoxDecoration(
//                             color: isDark ? Colors.grey[800] : Colors.grey[200],
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: Text(imagePosts.length.toString(), style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color)),
//                         )
//                     ],
//                   ),
//                 ),
//                 Tab(
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Icon(Icons.music_note_outlined, size: 18),
//                       const SizedBox(width: 8),
//                       Text(tr.song),
//                       if (songPosts.isNotEmpty)
//                        Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                         decoration: BoxDecoration(
//                           color: isDark ? Colors.grey[800] : Colors.grey[200],
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Text(songPosts.length.toString(), style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color)),
//                       )
//                     ],
//                   ),
//                 ),
//                 Tab(
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Icon(Icons.videocam_outlined, size: 18),
//                       const SizedBox(width: 8),
//                       Text(tr.video),
//                       if (videoPosts.isNotEmpty)
//                        Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                         decoration: BoxDecoration(
//                           color: isDark ? Colors.grey[800] : Colors.grey[200],
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Text(videoPosts.length.toString(), style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color)),
//                       )
//                     ],
//                   ),
//                 ),
//                  Tab(
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                        const Icon(Icons.menu_book_outlined, size: 18),
//                        const SizedBox(width: 8),
//                        Text(tr.literature),
//                        if (literaturePosts.isNotEmpty)
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                           decoration: BoxDecoration(
//                             color: isDark ? Colors.grey[800] : Colors.grey[200],
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: Text(literaturePosts.length.toString(), style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color)),
//                         )
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           Expanded(
//             child: TabBarView(
//               controller: _tabController,
//               children: [
//                 _buildPublishingList(theme, isDark, tr, imagePosts),
//                 _buildPublishingList(theme, isDark, tr, songPosts),
//                 _buildPublishingList(theme, isDark, tr, videoPosts),
//                 _buildPublishingList(theme, isDark, tr, literaturePosts),
//               ],
//             ),
//           ),
//         ],
//       ),
//       ),
//     );
//   }
//   Widget _buildPublishingList(ThemeData theme, bool isDark, AppTranslations tr, List<Map<String, dynamic>> items) {
//     if (items.isEmpty) {
//        return Center(child: Text(tr.noResults, style: TextStyle(color: theme.hintColor)));
//     }
//     return ListView.builder(
//       padding: const EdgeInsets.all(20),
//       itemCount: items.length,
//       itemBuilder: (context, index) {
//         final item = items[index];
//         String title = item['title'] ?? tr.untitled;
//         if (title == tr.untitled || title.toLowerCase() == 'untitled') {
//              final path = item['filePath'] as String?;
//              if (path != null && path.isNotEmpty) {
//                  title = p.basenameWithoutExtension(path).replaceAll('_', ' ').replaceAll('-', ' ');
//              }
//         }
//
//         // Handle Date (DateTime or String)
//         String dateStr = '';
//         if (item['date'] is DateTime) {
//             final date = item['date'] as DateTime;
//             dateStr = "${date.day}/${date.month}/${date.year}";
//         } else {
//             dateStr = item['date']?.toString() ?? '';
//         }
//
//         // Handle Thumbnail
//         Widget thumbnailWidget;
//
//         final String? filePath = item['filePath'];
//         final String? coverPath = item['coverPath'];
//         final String type = item['type'] ?? 'Image';
//         String? fallbackImage = (item['images'] != null && (item['images'] as List).isNotEmpty) ? (item['images'] as List).first : item['image'];
//
//         // Logic matched from CopyrightScreen (and ProfileScreen)
//         if (type == 'Image') {
//              String? path = filePath ?? fallbackImage;
//              if (path != null && path.isNotEmpty) {
//                  if (path.startsWith('http')) {
//                     thumbnailWidget = Image.network(path, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, size: 20));
//                  } else {
//                     thumbnailWidget = Image.file(File(path), fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, size: 20));
//                  }
//              } else {
//                  thumbnailWidget = const Icon(Icons.image, color: Colors.grey);
//              }
//         } else if (type == 'Video' || type == 'Reel' || type == 'Reels') {
//              if (coverPath != null && coverPath.isNotEmpty) {
//                   thumbnailWidget = coverPath.startsWith('http')
//                       ? Image.network(coverPath, fit: BoxFit.cover)
//                       : Image.file(File(coverPath), fit: BoxFit.cover);
//              } else if (filePath != null && filePath.isNotEmpty) {
//                   thumbnailWidget = VideoPlayerWidget(
//                     videoPath: filePath,
//                     autoPlay: false,
//                     showControls: false,
//                     showPlayButton: false,
//                     fit: BoxFit.cover,
//                   );
//              } else {
//                   thumbnailWidget = const Icon(Icons.videocam, color: Colors.grey);
//              }
//         } else if (type == 'Song') {
//              if (coverPath != null && coverPath.isNotEmpty) {
//                   thumbnailWidget = coverPath.startsWith('http')
//                       ? Image.network(coverPath, fit: BoxFit.cover)
//                       : Image.file(File(coverPath), fit: BoxFit.cover);
//              } else {
//                   thumbnailWidget = const Icon(Icons.music_note, color: Colors.grey);
//              }
//         } else if (type == 'Literature') {
//               if (filePath != null && filePath.isNotEmpty) {
//                  thumbnailWidget = AbsorbPointer(
//                    child: filePath.startsWith('http')
//                       ? SfPdfViewer.network(filePath, enableDoubleTapZooming: false, canShowScrollHead: false, canShowScrollStatus: false)
//                       : SfPdfViewer.file(File(filePath), enableDoubleTapZooming: false, canShowScrollHead: false, canShowScrollStatus: false),
//                  );
//               } else {
//                  thumbnailWidget = const Icon(Icons.menu_book, color: Colors.grey);
//               }
//         } else {
//              thumbnailWidget = const Icon(Icons.insert_drive_file, color: Colors.grey);
//         }
//
//         final isSelected = _selectedPosts.contains(item);
//         final bool isSelectionMode = _selectedPosts.isNotEmpty;
//
//         return InkWell(
//           onTap: () {
//             if (isSelectionMode) {
//               if (item['publishingStatus'] != 'Pending') {
//                  _toggleSelection(item);
//               }
//             } else {
//               if (item['publishingStatus'] == 'Pending') return;
//               _showRequestPublishingDialog(context, item);
//             }
//           },
//           onLongPress: () {
//             if (item['publishingStatus'] != 'Pending') {
//                _toggleSelection(item);
//             }
//           },
//           child: Container(
//             margin: const EdgeInsets.only(bottom: 12),
//             decoration: BoxDecoration(
//               color: theme.cardColor,
//               borderRadius: BorderRadius.circular(8),
//               border: isSelected ? Border.all(color: const Color(0xFFDB2777), width: 2) : null,
//             ),
//             padding: const EdgeInsets.all(12),
//             child: Row(
//               children: [
//                 if (isSelectionMode)
//                    item['publishingStatus'] == 'Pending'
//                    ? Padding(
//                        padding: const EdgeInsets.only(right: 12),
//                        child: Icon(Icons.check_circle_outline, color: theme.disabledColor, size: 24),
//                      )
//                    : Checkbox(
//                     value: isSelected,
//                     activeColor: const Color(0xFFDB2777),
//                     onChanged: (val) => _toggleSelection(item),
//                   ),
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(4),
//                   child: Container(
//                     width: 50,
//                     height: 50,
//                     color: Colors.grey[200],
//                     child: thumbnailWidget
//                   ),
//                 ),
//                 const SizedBox(width: 15),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         title,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xFFDB2777),
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         context.tr.publishedOn(dateStr),
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: theme.hintColor,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 if (!isSelected && !isSelectionMode && item['publishingStatus'] == 'Pending')
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: Colors.amber.withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(4),
//                       border: Border.all(color: Colors.amber),
//                     ),
//                     child: Text(
//                       tr.processing ?? 'Processing',
//                       style: TextStyle(fontSize: 10, color: isDark ? Colors.amber[200] : Colors.amber[800], fontWeight: FontWeight.bold),
//                     ),
//                   )
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
//
// class _RequestPublishingDialog extends StatefulWidget {
//   final String? artistName;
//   final List<Map<String, dynamic>>? posts;
//   const _RequestPublishingDialog({this.artistName, this.posts});
//
//   @override
//   State<_RequestPublishingDialog> createState() => _RequestPublishingDialogState();
// }
//
// class _RequestPublishingDialogState extends State<_RequestPublishingDialog> {
//   bool _acceptedTerms = false;
//   final List<String> _selectedFileNames = [];
//   late TextEditingController _artistController;
//
//   @override
//   void initState() {
//     super.initState();
//     _artistController = TextEditingController(text: widget.artistName ?? "");
//   }
//
//   @override
//   void dispose() {
//     _artistController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final tr = context.tr;
//     final isDark = theme.brightness == Brightness.dark;
//
//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
//       child: Container(
//         width: 500,
//         padding: const EdgeInsets.all(24),
//         child: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                        Text(
//                         tr.requestPublishing,
//                         style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         tr.publishingSubTitle,
//                         style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
//                       ),
//                     ],
//                   ),
//                   IconButton(
//                     onPressed: () => Navigator.of(context).pop(),
//                     icon: const Icon(Icons.close),
//                     padding: EdgeInsets.zero,
//                     constraints: const BoxConstraints(),
//                   )
//                 ],
//               ),
//               const SizedBox(height: 20),
//
//               // Artist Name
//               Text(tr.artistName, style: const TextStyle(fontWeight: FontWeight.w500)),
//               const SizedBox(height: 8),
//               TextField(
//                 controller: _artistController,
//                 decoration: InputDecoration(
//                   filled: true,
//                   fillColor: isDark ? Colors.black26 : Colors.grey[100],
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                     borderSide: BorderSide.none,
//                   ),
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                 ),
//               ),
//                const SizedBox(height: 16),
//
//                if (widget.posts != null && widget.posts!.isNotEmpty) ...[
//                  Text(context.tr.selectedContentCount(widget.posts!.length), style: const TextStyle(fontWeight: FontWeight.w500)),
//                  const SizedBox(height: 8),
//                  Container(
//                    padding: const EdgeInsets.all(8),
//                    decoration: BoxDecoration(
//                      color: isDark ? Colors.black26 : Colors.grey[100],
//                      borderRadius: BorderRadius.circular(8),
//                    ),
//                    child: Column(
//                      crossAxisAlignment: CrossAxisAlignment.start,
//                      children: widget.posts!.map((post) {
//                        String title = post['title'] ?? context.tr.untitled;
//                        if (title == context.tr.untitled || title.toLowerCase() == 'untitled') {
//                            final path = post['filePath'] as String?;
//                            if (path != null && path.isNotEmpty) {
//                                title = p.basenameWithoutExtension(path).replaceAll('_', ' ').replaceAll('-', ' ');
//                            }
//                        }
//                        return Padding(
//                        padding: const EdgeInsets.symmetric(vertical: 2),
//                        child: Text("\u2022 $title", style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
//                      );
//                      }).toList(),
//                    ),
//                  ),
//                  const SizedBox(height: 16),
//                ],
//
//                // Publishing Content
//               Text(tr.publishingContent, style: const TextStyle(fontWeight: FontWeight.w500)),
//               const SizedBox(height: 8),
//               TextField(
//                 decoration: InputDecoration(
//                   hintText: tr.enterContentToPublish,
//                   hintStyle: TextStyle(color: theme.hintColor.withOpacity(0.5)),
//                   filled: true,
//                   fillColor: isDark ? Colors.black26 : Colors.grey[100],
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                     borderSide: const BorderSide(color: Color(0xFFDB2777)),
//                   ),
//                    enabledBorder: OutlineInputBorder(
//                      borderRadius: BorderRadius.circular(8),
//                      borderSide: const BorderSide(color: Color(0xFFDB2777)),
//                   ),
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                 ),
//               ),
//
//                const SizedBox(height: 16),
//
//                // Files
//                if (widget.posts == null || widget.posts!.isEmpty) ...[
//                Text(tr.uploadFiles, style: const TextStyle(fontWeight: FontWeight.w500)),
//               const SizedBox(height: 8),
//               Container(
//                 decoration: BoxDecoration(
//                   color: isDark ? Colors.black26 : Colors.grey[100],
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: theme.dividerColor),
//                 ),
//                 padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
//                 child: Row(
//                   children: [
//                     ElevatedButton(
//                       onPressed: () async {
//                          try {
//                            FilePickerResult? result = await FilePicker.platform.pickFiles(
//                              allowMultiple: true,
//                              type: FileType.any, // Allow any type for publishing generally
//                            );
//                            if (result != null) {
//                              setState(() {
//                                _selectedFileNames.addAll(result.files.map((f) => f.name).toList());
//                              });
//                            }
//                         } catch (e) {
//                           // Handle error
//                         }
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.white,
//                         foregroundColor: Colors.black,
//                         elevation: 0,
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
//                         padding: const EdgeInsets.symmetric(horizontal: 12),
//                       ),
//                       child: Text(tr.browse),
//                     ),
//                     const SizedBox(width: 10),
//                     Expanded(
//                        child: _selectedFileNames.isEmpty
//                         ? Text(
//                             context.tr.noFileSelected,
//                             style: TextStyle(color: theme.hintColor),
//                             overflow: TextOverflow.ellipsis,
//                           )
//                         : Text(
//                              context.tr.filesSelectedCount(_selectedFileNames.length),
//                             style: TextStyle(color: theme.textTheme.bodyMedium?.color),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                     ),
//                   ],
//                 ),
//               ),
//               if (_selectedFileNames.isNotEmpty) ...[
//                 const SizedBox(height: 4),
//                 Wrap(
//                   spacing: 4,
//                   children: _selectedFileNames.take(3).map((name) => Chip(
//                     label: Text(name, style: TextStyle(fontSize: 10)),
//                     deleteIcon: const Icon(Icons.close, size: 12),
//                     onDeleted: () {
//                       setState(() {
//                         _selectedFileNames.remove(name);
//                       });
//                     },
//                     materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                   )).toList() + (_selectedFileNames.length > 3 ? [Chip(label: Text(tr.dots))] : []),
//                 ),
//               ],
//                ],
//
//                const SizedBox(height: 20),
//
//                // Terms Checkbox
//               Row(
//                 children: [
//                   Checkbox(
//                     value: _acceptedTerms,
//                     activeColor: Colors.white,
//                     checkColor: Colors.black,
//                     onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
//                      side: BorderSide(color: theme.unselectedWidgetColor),
//                   ),
//                   Expanded(
//                     child: RichText(
//                       text: TextSpan(
//                         style: theme.textTheme.bodyMedium,
//                         children: [
//                           TextSpan(text: context.tr.iAcceptThe),
//                           TextSpan(
//                             text: tr.termsAndConditions,
//                             style: const TextStyle(color: Color(0xFFDB2777), decoration: TextDecoration.underline)
//                           ),
//                           TextSpan(text: context.tr.and),
//                           TextSpan(
//                             text: tr.privacyPolicy,
//                             style: const TextStyle(color: Color(0xFFDB2777), decoration: TextDecoration.underline)
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//                const SizedBox(height: 20),
//
//                // Submit Button
//                Align(
//                  alignment: Alignment.centerRight,
//                  child: ElevatedButton(
//                     onPressed: _acceptedTerms ? () {
//                        // TODO: Add real validation if needed (ID Card, Terms) - assuming it's done for consistency
//                        Navigator.of(context).pop(true);
//                        // ScaffoldMessenger.of(context).showSnackBar(
//                        //   SnackBar(content: Text("${tr.success}: ${context.tr.contentSubmittedPublishing}"))
//                        // );
//                     } : null,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: _acceptedTerms ? const Color(0xFFDB2777) : Colors.grey,
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                     ),
//                     child: Text(tr.submit),
//                  ),
//                ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
