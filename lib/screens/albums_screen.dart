import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/album_model.dart';
import '../models/album_response.dart';
import '../viewmodels/album_viewmodel.dart';

class AlbumsScreen extends ConsumerStatefulWidget {
  const AlbumsScreen({super.key});

  @override
  ConsumerState<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends ConsumerState<AlbumsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(albumViewModelProvider.notifier).loadAlbums();
    });
  }

  // ✅ REMOVED deleteLocalAlbums from here — it belongs only in AlbumViewModel

  void _showAlbumDetails(BuildContext context, Album album) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xff1A2742),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width * .9,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        "Album Details",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 500;
                      return isMobile
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: album.coverImage != null
                                  ? Image.network(
                                album.coverImage!,
                                width: 140,
                                height: 140,
                                fit: BoxFit.cover,
                              )
                                  : Container(
                                width: 140,
                                height: 140,
                                color: const Color(0xff33435F),
                                child: const Icon(
                                    Icons.music_note,
                                    color: Colors.white54,
                                    size: 50),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            album.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            album.isPublic == true
                                ? "Public"
                                : "Private",
                            style: const TextStyle(
                                color: Colors.white60),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.play_arrow),
                              label: const Text("Play Album"),
                            ),
                          ),
                        ],
                      )
                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: album.coverImage != null
                                  ? Image.network(
                                album.coverImage!,
                                width: 140,
                                height: 140,
                                fit: BoxFit.cover,
                              )
                                  : Container(
                                width: 140,
                                height: 140,
                                color: const Color(0xff33435F),
                                child: const Icon(
                                    Icons.music_note,
                                    color: Colors.white54,
                                    size: 50),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Tracks",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _trackTile(1, "Unknown Track"),
                        const SizedBox(height: 8),
                        _trackTile(2, "Unknown Track"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _trackTile(int index, String title) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xff33435F),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text("$index", style: const TextStyle(color: Colors.white70)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 4),
                const Text("0:00",
                    style:
                    TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.music_note, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  void _showEditAlbumDialog(BuildContext context, Album album) {
    final titleController = TextEditingController(text: album.title);
    bool isPublic = album.isPublic ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xff1A2742),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * .92,
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text(
                            "Edit Album",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close,
                                color: Colors.white70),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Album Title",
                              style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: titleController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xff33435F),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: Column(
                              children: [
                                const Text("Album Cover",
                                    style: TextStyle(
                                        color: Colors.white70)),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius:
                                  BorderRadius.circular(12),
                                  child: album.coverImage != null
                                      ? Image.network(
                                    album.coverImage!,
                                    width: 130,
                                    height: 130,
                                    fit: BoxFit.cover,
                                  )
                                      : Container(
                                    width: 130,
                                    height: 130,
                                    color:
                                    const Color(0xff33435F),
                                    child: const Icon(
                                        Icons.music_note,
                                        color: Colors.white54,
                                        size: 50),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Text("Visibility",
                                  style: TextStyle(
                                      color: Colors.white70)),
                              const SizedBox(width: 12),
                              Switch(
                                value: isPublic,
                                onChanged: (v) =>
                                    setDialogState(() => isPublic = v),
                              ),
                              Text(
                                isPublic ? "Public" : "Private",
                                style: const TextStyle(
                                    color: Colors.white70),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "0.00",
                              filled: true,
                              fillColor: const Color(0xff33435F),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Select Media",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            const Text(
                                "Add 6 to 15 tracks — 0 / 15 tracks",
                                style:
                                TextStyle(color: Colors.white54)),
                            const SizedBox(height: 20),
                            const Text("🎵 Songs (2)",
                                style:
                                TextStyle(color: Colors.white)),
                            const SizedBox(height: 10),
                            _mediaTile("Travis Scott Type Beat"),
                            _mediaTile(
                                "Shawn Mendes – Treat You Better"),
                            const SizedBox(height: 20),
                            const Text("🎥 Videos (3)",
                                style:
                                TextStyle(color: Colors.white)),
                            const SizedBox(height: 10),
                            _mediaTile(
                                "Rolling Loud 2021 Kanye West"),
                            _mediaTile("Zayn singing Night Changes"),
                            _mediaTile("test"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel",
                                style: TextStyle(
                                    color: Colors.white70)),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              const Color(0xffFF3B9D),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Update Album"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteAlbumDialog(BuildContext context, Album album) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xff1A2742),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * .85,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.red, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      "Delete Album",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          height: 1.5),
                      children: [
                        const TextSpan(
                            text:
                            "Are you sure you want to delete "),
                        TextSpan(
                          text: '"${album.title}"',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                        const TextSpan(
                            text:
                            "? This action cannot be undone."),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 10,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel",
                          style: TextStyle(
                              color: Colors.white70, fontSize: 16)),
                    ),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: () {
                          ref
                              .read(albumViewModelProvider.notifier)
                              .deleteLocalAlbums(album.id);
                          Navigator.pop(context);
                        },
                        child: const Text("Delete Album"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _mediaTile(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xff33435F),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Checkbox(value: false, onChanged: (_) {}),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(albumViewModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xff08142D),
      appBar: AppBar(
        backgroundColor: const Color(0xff08142D),
        elevation: 0,
        title: const Text(
          "Albums",
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffFF3B9D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {},
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Create",
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xffFF3B9D),
          labelColor: const Color(0xffFF3B9D),
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "My Albums"),
            Tab(text: "Public"),
            Tab(text: "Purchases"),
          ],
        ),
      ),
      body: asyncState.when(
        loading: () =>
        const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(e.toString(),
              style: const TextStyle(color: Colors.white)),
        ),
        data: (response) => TabBarView(
          controller: _tabController,
          children: [
            _myAlbumsTab(response.albums),
            _publicAlbumsTab(response.publicAlbums),
            _purchasesTab(response.purchasedAlbums),
          ],
        ),
      ),
    );
  }

  Widget _myAlbumsTab(List<Album> albums) {
    if (albums.isEmpty) {
      return const Center(
        child: Text("No Albums Found",
            style: TextStyle(color: Colors.white)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xff122340),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: album.coverImage != null
                        ? Image.network(
                      album.coverImage!,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xff33435F),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.music_note,
                          color: Colors.white54),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xffFF3B9D),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          "${album.id}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      album.isPublic == true ? "Public" : "Private",
                      style:
                      const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_red_eye_outlined),
                color: Colors.white70,
                onPressed: () =>
                    _showAlbumDetails(context, album),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                color: Colors.white70,
                onPressed: () =>
                    _showEditAlbumDialog(context, album),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.white70,
                onPressed: () =>
                    _showDeleteAlbumDialog(context, album),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _publicAlbumsTab(List<Album> albums) {
    if (albums.isEmpty) {
      return const Center(
        child: Text("No Public Albums",
            style: TextStyle(color: Colors.white)),
      );
    }
    return ListView.builder(
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return ListTile(
          title: Text(album.title,
              style: const TextStyle(color: Colors.white)),
        );
      },
    );
  }

  Widget _purchasesTab(List<Album> purchasedAlbums) {
    if (purchasedAlbums.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 45,
                backgroundColor: Color(0xff2A3C5A),
                child: Icon(Icons.music_note,
                    size: 45, color: Colors.white54),
              ),
              const SizedBox(height: 20),
              const Text(
                "No purchased albums yet",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Albums you buy will appear here.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffFF3B9D),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
                onPressed: () {},
                child: const Text("Browse Albums",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: purchasedAlbums.length,
      itemBuilder: (context, index) {
        final album = purchasedAlbums[index];
        return ListTile(
          title: Text(album.title,
              style: const TextStyle(color: Colors.white)),
        );
      },
    );
  }
}