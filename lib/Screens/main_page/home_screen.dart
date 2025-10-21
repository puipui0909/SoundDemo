import 'package:flutter/material.dart';
import 'package:spotify_clone/models/artist.dart';
import 'package:spotify_clone/widgets/custom_appbar.dart';
import 'package:spotify_clone/widgets/home_tabs/items.dart';
import 'package:spotify_clone/models/song.dart';
import '../../features/search/my_search_delegate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: CustomAppBar(
          action: IconButton(
            onPressed: () {
              showSearch(
                context: context,
                delegate: MySearchDelegate(),
              );
            },
            icon: const Icon(Icons.search),
          ),
          title: 'HOME',
        ),
        body: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'News'),
                Tab(text: 'Artist'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  NewsTab(),
                  ArtistTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NewsTab extends StatelessWidget {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('songs')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final songs =
        snapshot.data!.map((map) => Song.fromMap(map)).toList();

        return SizedBox(
          height: 242,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: songs.length,
            itemBuilder: (context, index) =>
                MediaItem.song(
                  song: songs[index],
                  playlist: songs,
                  index: index,
                ),
          ),
        );
      },
    );
  }
}

class ArtistTab extends StatelessWidget {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('artists').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final artists =
        snapshot.data!.map((map) => Artist.fromMap(map)).toList();

        return SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: artists.length,
            itemBuilder: (context, index) =>
                MediaItem.artist(artist: artists[index]),
          ),
        );
      },
    );
  }
}
