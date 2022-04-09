/// This file is a part of Harmonoid (https://github.com/harmonoid/harmonoid).
///
/// Copyright © 2020-2022, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
///
/// Use of this source code is governed by the End-User License Agreement for Harmonoid that can be found in the EULA.txt file.
///
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ytm_client/ytm_client.dart';
import 'package:extended_image/extended_image.dart';

import 'package:harmonoid/core/collection.dart';
import 'package:harmonoid/utils/rendering.dart';
import 'package:harmonoid/utils/dimensions.dart';
import 'package:harmonoid/utils/widgets.dart';
import 'package:harmonoid/web/state/web.dart';
import 'package:harmonoid/web/track.dart';
import 'package:harmonoid/models/media.dart' as media;
import 'package:harmonoid/constants/language.dart';

class WebPlaylistLargeTile extends StatelessWidget {
  final double width;
  final double height;
  final Playlist playlist;
  const WebPlaylistLargeTile({
    Key? key,
    required this.playlist,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4.0,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () async {
          playlist.tracks = [];
          playlist.continuation = null;
          final thumbnails = playlist.thumbnails.values.toList();
          precacheImage(
            ExtendedNetworkImageProvider(thumbnails[thumbnails.length - 2]),
            context,
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => WebPlaylistScreen(
                playlist: playlist,
              ),
            ),
          );
        },
        child: Container(
          height: height,
          width: width,
          child: Column(
            children: [
              ClipRect(
                child: ScaleOnHover(
                  child: Hero(
                    tag: 'album_art_${playlist.id}',
                    child: ExtendedImage(
                      image: ExtendedNetworkImageProvider(
                          playlist.thumbnails.values.skip(1).first),
                      fit: BoxFit.cover,
                      height: width,
                      width: width,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.0,
                  ),
                  width: width,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.name.overflow,
                        style: Theme.of(context).textTheme.headline2,
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WebPlaylistTile extends StatelessWidget {
  final Playlist playlist;
  const WebPlaylistTile({
    Key? key,
    required this.playlist,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          playlist.tracks = [];
          playlist.continuation = null;
          final thumbnails = playlist.thumbnails.values.toList();
          precacheImage(
            ExtendedNetworkImageProvider(thumbnails[thumbnails.length - 2]),
            context,
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => WebPlaylistScreen(
                playlist: playlist,
              ),
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Divider(
              height: 1.0,
              indent: 80.0,
            ),
            Container(
              height: 64.0,
              alignment: Alignment.center,
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 12.0),
                  ExtendedImage(
                    image: NetworkImage(
                      playlist.thumbnails.values.first,
                    ),
                    height: 56.0,
                    width: 56.0,
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist.name.overflow,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: Theme.of(context).textTheme.headline2,
                        ),
                        const SizedBox(
                          height: 2.0,
                        ),
                        Text(
                          Language.instance.PLAYLIST_SINGLE,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: Theme.of(context).textTheme.headline3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Container(
                    width: 64.0,
                    height: 64.0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WebPlaylistScreen extends StatefulWidget {
  final Playlist playlist;
  const WebPlaylistScreen({
    Key? key,
    required this.playlist,
  }) : super(key: key);
  WebPlaylistScreenState createState() => WebPlaylistScreenState();
}

class WebPlaylistScreenState extends State<WebPlaylistScreen>
    with SingleTickerProviderStateMixin {
  Color? color;
  double elevation = 0.0;
  PagingController<int, Track?> pagingController =
      PagingController(firstPageKey: 0);
  int last = 0;
  ScrollController scrollController =
      ScrollController(initialScrollOffset: 0.0);

  bool isDark(BuildContext context) =>
      (0.299 *
              (color?.red ??
                  (Theme.of(context).brightness == Brightness.dark
                      ? 0.0
                      : 255.0))) +
          (0.587 *
              (color?.green ??
                  (Theme.of(context).brightness == Brightness.dark
                      ? 0.0
                      : 255.0))) +
          (0.114 *
              (color?.blue ??
                  (Theme.of(context).brightness == Brightness.dark
                      ? 0.0
                      : 255.0))) <
      128.0;

  @override
  void initState() {
    super.initState();
    pagingController.addPageRequestListener((pageKey) async {
      if (pageKey == 0) {
        pagingController.appendPage([null], 1);
      } else {
        last = widget.playlist.tracks.length;
        await YTMClient.playlist(widget.playlist);
        widget.playlist.tracks.asMap().entries.forEach((element) {
          element.value.trackNumber = element.key + 1;
        });
        if (widget.playlist.continuation != '') {
          pagingController.appendPage(
            widget.playlist.tracks.skip(last).toList(),
            pageKey + 1,
          );
        } else {
          pagingController.appendLastPage(
            widget.playlist.tracks.skip(last).toList(),
          );
        }
      }
    });
    widget.playlist.tracks.sort(
        (first, second) => first.trackNumber.compareTo(second.trackNumber));
    if (isDesktop) {
      Timer(
        Duration(milliseconds: 300),
        () {
          PaletteGenerator.fromImageProvider(ExtendedNetworkImageProvider(
                  widget.playlist.thumbnails.values.first))
              .then((palette) {
            setState(() {
              color = palette.colors.first;
            });
          });
        },
      );
      scrollController.addListener(() {
        if (scrollController.offset.isZero) {
          setState(() {
            elevation = 0.0;
          });
        } else if (elevation == 0.0) {
          setState(() {
            elevation = 4.0;
          });
        }
      });
    }
    if (Platform.isWindows) {
      scrollController.addListener(
        () {
          final scrollDirection = scrollController.position.userScrollDirection;
          if (scrollDirection != ScrollDirection.idle) {
            var scrollEnd = scrollController.offset +
                (scrollDirection == ScrollDirection.reverse ? 60 : -60);
            scrollEnd = min(scrollController.position.maxScrollExtent,
                max(scrollController.position.minScrollExtent, scrollEnd));
            scrollController.jumpTo(scrollEnd);
          }
        },
      );
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isDesktop
        ? Scaffold(
            body: Container(
              height: MediaQuery.of(context).size.height,
              child: Stack(
                children: [
                  PagedListView(
                    scrollController: scrollController,
                    pagingController: pagingController,
                    padding: EdgeInsets.only(
                      top: desktopTitleBarHeight + kDesktopAppBarHeight,
                    ),
                    builderDelegate: PagedChildBuilderDelegate<Track?>(
                      newPageProgressIndicatorBuilder: (_) => Container(
                        height: 96.0,
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                      firstPageProgressIndicatorBuilder: (_) => Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      itemBuilder: (context, track, pageKey) => pageKey == 0
                          ? TweenAnimationBuilder(
                              tween: ColorTween(
                                begin: Theme.of(context)
                                    .appBarTheme
                                    .backgroundColor,
                                end: color == null
                                    ? Theme.of(context)
                                        .appBarTheme
                                        .backgroundColor
                                    : color!,
                              ),
                              curve: Curves.easeOut,
                              duration: Duration(
                                milliseconds: 300,
                              ),
                              builder: (context, color, _) =>
                                  Transform.translate(
                                offset: Offset(0, -8.0),
                                child: Material(
                                  color: color as Color? ?? Colors.transparent,
                                  elevation: elevation == 0.0 ? 4.0 : 0.0,
                                  borderRadius: BorderRadius.zero,
                                  child: Container(
                                    height: 312.0,
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 56.0),
                                        Padding(
                                          padding: EdgeInsets.all(20.0),
                                          child: () {
                                            final thumbnails = widget
                                                .playlist.thumbnails.values
                                                .toList();
                                            return Hero(
                                              tag:
                                                  'playlist_art_${widget.playlist.name}',
                                              child: Card(
                                                color: Colors.white,
                                                elevation: 4.0,
                                                child: Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.all(8.0),
                                                      child: ExtendedImage(
                                                        image:
                                                            ExtendedNetworkImageProvider(
                                                          thumbnails[thumbnails
                                                                  .length -
                                                              2],
                                                        ),
                                                        height: 256.0,
                                                        width: 256.0,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }(),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 20.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  widget.playlist.name,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headline1
                                                      ?.copyWith(
                                                        fontSize: 24.0,
                                                        color: isDark(context)
                                                            ? Colors.white
                                                            : Colors.black,
                                                      ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: 16.0),
                                                Row(
                                                  children: [
                                                    ElevatedButton.icon(
                                                      onPressed: () {
                                                        Web.open(widget
                                                            .playlist.tracks);
                                                      },
                                                      style: ButtonStyle(
                                                        elevation:
                                                            MaterialStateProperty
                                                                .all(0.0),
                                                        backgroundColor:
                                                            MaterialStateProperty
                                                                .all(isDark(
                                                                        context)
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black87),
                                                        padding:
                                                            MaterialStateProperty
                                                                .all(EdgeInsets
                                                                    .all(12.0)),
                                                      ),
                                                      icon: Icon(
                                                        Icons.play_arrow,
                                                        color: !isDark(context)
                                                            ? Colors.white
                                                            : Colors.black87,
                                                      ),
                                                      label: Text(
                                                        Language
                                                            .instance.PLAY_NOW
                                                            .toUpperCase(),
                                                        style: TextStyle(
                                                          fontSize: 12.0,
                                                          color:
                                                              !isDark(context)
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .black87,
                                                          letterSpacing: -0.1,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8.0),
                                                    OutlinedButton.icon(
                                                      onPressed: () {
                                                        Collection.instance
                                                            .playlistCreate(
                                                          media.Playlist(
                                                            id: widget.playlist
                                                                .name.hashCode,
                                                            name: widget
                                                                .playlist.name,
                                                          )..tracks.addAll(widget
                                                              .playlist.tracks
                                                              .map((e) => media
                                                                      .Track
                                                                  .fromWebTrack(
                                                                      e.toJson()))),
                                                        );
                                                      },
                                                      style: OutlinedButton
                                                          .styleFrom(
                                                        primary: Colors.white,
                                                        side: BorderSide(
                                                            color: isDark(
                                                                    context)
                                                                ? Colors.white
                                                                : Colors
                                                                    .black87),
                                                        padding: EdgeInsets.all(
                                                            12.0),
                                                      ),
                                                      icon: Icon(
                                                        Icons.playlist_add,
                                                        color: isDark(context)
                                                            ? Colors.white
                                                            : Colors.black87,
                                                      ),
                                                      label: Text(
                                                        Language.instance
                                                            .SAVE_AS_PLAYLIST
                                                            .toUpperCase(),
                                                        style: TextStyle(
                                                          fontSize: 12.0,
                                                          color: isDark(context)
                                                              ? Colors.white
                                                              : Colors.black87,
                                                          letterSpacing: -0.1,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8.0),
                                                    OutlinedButton.icon(
                                                      onPressed: () {
                                                        launch(
                                                            'https://music.youtube.com/browse/${widget.playlist.id}');
                                                      },
                                                      style: OutlinedButton
                                                          .styleFrom(
                                                        primary: Colors.white,
                                                        side: BorderSide(
                                                            color: isDark(
                                                                    context)
                                                                ? Colors.white
                                                                : Colors
                                                                    .black87),
                                                        padding: EdgeInsets.all(
                                                            12.0),
                                                      ),
                                                      icon: Icon(
                                                        Icons.open_in_new,
                                                        color: isDark(context)
                                                            ? Colors.white
                                                            : Colors.black87,
                                                      ),
                                                      label: Text(
                                                        Language.instance
                                                            .OPEN_IN_BROWSER
                                                            .toUpperCase(),
                                                        style: TextStyle(
                                                          fontSize: 12.0,
                                                          color: isDark(context)
                                                              ? Colors.white
                                                              : Colors.black87,
                                                          letterSpacing: -0.1,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 56.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : WebTrackTile(
                              track: track!,
                              group: widget.playlist.tracks,
                            ),
                    ),
                  ),
                  TweenAnimationBuilder(
                    tween: ColorTween(
                      begin: Theme.of(context).appBarTheme.backgroundColor,
                      end: color == null
                          ? Theme.of(context).appBarTheme.backgroundColor
                          : color!,
                    ),
                    curve: Curves.easeOut,
                    duration: Duration(
                      milliseconds: 300,
                    ),
                    builder: (context, color, _) => DesktopAppBar(
                      elevation: elevation,
                      color: color as Color? ?? Colors.transparent,
                      title: elevation.isZero ? null : widget.playlist.name,
                    ),
                  ),
                ],
              ),
            ),
          )
        : Container();
  }
}